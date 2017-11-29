abstract type AbstractPositioner end
#All theory used here came from these sources:
#https://www.piezosystem.com/piezopedia/piezotheory/
#http://www.piezo.ws/piezoelectric_actuator_tutorial/Piezo_Design_part3.php

#Linear translation piezo device (one-dimension of motion only)
#TODO: add coefficient of friction? (should be very small)
struct Piezo{T} <: AbstractPositioner
    id::String
    vmin_in::HasVoltageUnits{T} #min acceptable amplifier input
    vmax_in::HasVoltageUnits{T} #max acceptable amplifier input
    vmin_out::HasVoltageUnits{T} #min MON (sensor) output
    vmax_out::HasVoltageUnits{T} #max MON (sensor) output
    pmin_ol::HasLengthUnits{T} #min position in open loop
    pmax_ol::HasLengthUnits{T}
    closed_loop_pad::HasLengthUnits{T} #Amount of the motion range that becomes inaccessible in closed loop mode.  This applies equally to the low and high side, so the total loss in range is twice this amount
    max_disp::HasLengthUnits{T} #nominal max displacement.  One might expect this to be the same as the open loop range, but this contradicts the
                                #force specificatinos of our piezo.  (see below and more thoughts at the end of this file)
    cap::HasCapacitanceUnits{T}
    motion_axis::Int
    effective_mass::HasMassUnits{T}
    resonance_freqs::NTuple{3,HasInverseTimeUnits{T}} #resonance frequency without load (decreases with load, avoid operating at greater than 80% of resonant frequency)
    stiffs::NTuple{3, HasStiffnessUnits{T}} #actuator stiffness
end

name(p::Piezo) = p.id
vmin_in(p::Piezo) = p.vmin_in
vmax_in(p::Piezo) = p.vmax_in
vspan_in(p::Piezo) = vmax_in(p) - vmin_in(p)
mon_slope(p::Piezo, is_cl::Bool) = vspan_out(p, is_cl) / pspan(p, is_cl) #Volts MON per micron.  TODO: this as well as vmin_out and vmax_out may be inaccurate in open loop mode
closed_loop_pad(p::Piezo) = p.closed_loop_pad
vmin_out(p::Piezo, is_cl::Bool) = p.vmin_out
vmax_out(p::Piezo, is_cl::Bool) = p.vmax_out
#function vmin_out(p::Piezo, is_cl::Bool)
#    if is_cl
#        return p.vmin_out + mon_slope(p, is_cl) * closed_loop_pad(p)
#    else
#        return p.vmin_out
#    end
#end
#
#function vmax_out(p::Piezo, is_cl::Bool)
#    if is_cl
#        return p.vmax_out - mon_slope(p, is_cl) * closed_loop_pad(p)
#    else
#        return p.vmax_out
#    end
#end
vspan_out(p::Piezo, is_cl::Bool) = vmax_out(p, is_cl) - vmin_out(p, is_cl)

pmin(p::Piezo, is_cl::Bool) = is_cl ? p.pmin_ol + closed_loop_pad(p) : p.pmin_ol
pmax(p::Piezo, is_cl::Bool) = is_cl ? p.pmax_ol - closed_loop_pad(p) : p.pmax_ol
pspan(p::Piezo, is_cl::Bool) = pmax(p, is_cl) - pmin(p, is_cl)

blocked_pad(p::Piezo) = (max_displacement(p) - pspan(p, false))/2 #If the max nominal displacement is greater than the open loop span of the piezo then there is a region that is blocked.  This is the half-size of the total blocked distance
function closed2open(pclosed::HasLengthUnits, p::Piezo)
    if pclosed < pmin(p, true) || pclosed > pmax(p, true)
        error("The input is not within the valid closed-loop range of the piezo")
    end
    return pmin(p, false) + closed_loop_pad(p) + pclosed
end

function open2closed(popen::HasLengthUnits, p::Piezo)
    clp = closed_loop_pad(p)
    if popen < (pmin(p, false) + clp) || popen > (pmax(p, false) - clp)
        error("Position $popen is not achievable in closed-loop mode")
    end
    return pmin(p, false) + clp + popen #note this is trivial (equal to popen) when the closed-loop range begins with zero (all piezosystem jena piezos)
end

max_displacement(p::Piezo) = p.max_disp
capacitance(p::Piezo) = p.cap
motion_axis(p::Piezo) = p.motion_axis
stiffness(p::Piezo, dim::Int) = p.stiffs[dim]
stiffness(p::Piezo) = stiffness(p, motion_axis(p))
stiffness_all(p::Piezo) = p.stiffs
effective_mass(p::Piezo) = p.effective_mass
resonance(p::Piezo, dim::Int) = p.resonance_freqs[dim]
resonance(p::Piezo) = resonance(p, motion_axis(p))
resonance_all(p::Piezo) = p.resonance_freqs

#clamps a given position value to be within the nominal displacement range of the piezo
function clamp(pos::HasLengthUnits, p::Piezo)
    if pos < zero(pos)
        return zero(pos)
    else
        return min(pos, max_displacement(p))
    end
end

#Several functions are defined for converting input/output voltages and positions:
#amplifier voltage <-> positioner displacement <-> monitored voltage <-> monitored position

#Converts the monitor voltage into a position reading, does NOT correspond with the nominal displacement of the piezo.  Therefore the position reading should not be used
#for making force / compression calculations.
function mon2pos(mon::HasVoltageUnits, p::Piezo, is_cl::Bool)
    if mon < vmin_out(p, is_cl) || mon > vmax_out(p, is_cl)
        error("Monitor voltage lies outside the valid output range of this piezo.")
    end
    return pmin(p, is_cl) + inv(mon_slope(p, is_cl)) * (mon - vmin_out(p, is_cl))
end

#Returns the mon voltage for a given position
function pos2mon(pos::HasLengthUnits, p::Piezo, is_cl::Bool)
    clp = closed_loop_pad(p)
    max_p = pmax(p, is_cl) 
    min_p = pmin(p, is_cl)
    if pos < min_p || pos > max_p
        if !is_cl
            error("Position lies outside the valid open-loop position range of this piezo.")
        end
        error("Position lies outside the valid closed-loop position range of this piezo.")
    end
    pos_frac = (pos - min_p) / (max_p - min_p)
    return vmin_out(p, is_cl) + pos_frac * vspan_out(p, is_cl)
end

#Converts nominal displacement to a physical position, clamping the position to be within the allowed range of the positioner
#(position is only accurate without external forces)
function displacement2pos(d::HasLengthUnits, p::Piezo, is_cl::Bool)
    md = max_displacement(p)
    if d > md || d < zero(d)
        error("Displacement must be nonnegative and no greater than the maximum displacement of the piezo")
    end
    extra_pad = blocked_pad(p)
    p_ol = zero(d)
    if d <= pspan(p, false) + extra_pad
        p_ol = pmin(p, false) + max(zero(d), d - extra_pad)
    else
        p_ol = pmax(p, false)
    end
    if is_cl
        return open2closed(p_ol, p)
    else
        return p_ol
    end
end

#This version accounts for length changes due to finite piezo stiffness. Thus it uses the net force acting on the positioner (positive force corresponds with positive voltage and positive change in position).
#The force calculation should include any load, the effective mass of the positioner itself, and gravity forces
displacement2pos(d::HasLengthUnits, p::Piezo, is_cl::Bool, f::HasForceUnits) = displacement2pos(d + uconvert(unit(d), f/stiffness(p)), p, is_cl)

function check_disp_extrema(pos::HasLengthUnits, p::Piezo; only_warn = false)
    if isapprox(pos, pmin(p, false)) || isapprox(pos, pmax(p, false))
        f = only_warn ? warn : error
        f("The nominal displacement can't reliably be calculated from the position when position reaches the extremes of the operating range")
    end
end

#The monitored signal doesn't give the displacement that is useful for piezo force calculations.  This function transforms the mon value to that more useful value.
#This version takes the position according to piezo sensor output and converts that to a nominal piezo displacement useful for force calculations
#Note that it's unreliable at the extremes of the piezo's range because the piezo could be generating extra force (and thus a greater nominal displacement) against a stop
#If you want to proceed anyway call the unsafe_ version
unsafe_pos2displacement(pos::HasLengthUnits, p::Piezo) = blocked_pad(p) + (pos - pmin(p, false))
function pos2displacement(pos::HasLengthUnits, p::Piezo, is_cl::Bool)
    if is_cl
        pos = closed2open(pos, p)
    end
    check_disp_extrema(pos, p)
    return unsafe_pos2displacement(pos, p)
end

#This version considers a load
#nom_displacement + f/stiffness(p) = measured_displacement
#nom_displacement = measured_disp - f/stiffness(p)
pos2displacement(pos::HasLengthUnits, p::Piezo, is_cl::Bool, f::HasForceUnits) =  pos2displacement(pos, p, is_cl) - f/stiffness(p)

#get the (nominal) displacement of the positioner for a given input voltage without any load
#like the nominal max displacement, this may exceed the allowed displacement of the piezo
#We assume there is an internal stop narrowing the allowed displacement, but for the force calculation the full displacement must be used
function input2displacement(v::HasVoltageUnits, p::Piezo)
    if v < vmin_in(p) || v > vmax_in(p)
        error("Input voltage lies outside the valid input range of this piezo.")
    end
    v_frac = (v-vmin_in(p)) / vspan_in(p)
    md = max_displacement(p)
    return v_frac * md
end

#Calculate volts required to generate a given nominal displacement
#(piezo might not actually reach that displacement due to blocking forces)
function displacement2input(d::HasLengthUnits, p::Piezo)
    @assert d <= max_displacement(p) && d >= zero(d)
    return vmin_in(p) + (d/max_displacement(p)) * vspan_in(p)
end

function input2pos(v::HasVoltageUnits, p::Piezo, is_cl::Bool, f::HasForceUnits)
    d0 = input2displacement(v, p)
    return displacement2pos(d0, p, is_cl, f)
end
input2pos(v::HasVoltageUnits, p::Piezo, is_cl::Bool) = input2pos(v, p, is_cl, 0.0N)

pos2input(pos::HasLengthUnits, p::Piezo, is_cl::Bool, f::HasForceUnits) = displacement2input(pos2displacement(pos, p, is_cl, f), p)
pos2input(pos::HasLengthUnits, p::Piezo, is_cl::Bool) = displacement2input(pos2displacement(pos, p, is_cl, 0.0N), p)

#adjusted_displacement - compression = mon_displacement
#adjusted_displacement = mon_displacement + compression
#                  = mon_displacement + f / stiffness(p)
mon2displacement(mon::HasVoltageUnits, p::Piezo, is_cl::Bool, f::HasForceUnits) = pos2displacement(mon2pos(mon, p, is_cl), p, is_cl, f)
#function mon2displacement(mon::HasVoltageUnits, p::Piezo, is_cl::Bool, f::HasForceUnits)
#    pos = mon2pos(mon, p, is_cl)
#    if is_cl
#        pos = closed2open(pos, p)
#    end
#    check_disp_extrema(pos, p; only_warn=true)
#    return unsafe_pos2displacement(mon2pos(mon, p, is_cl), p, f)
#end

mon2displacement(mon::HasVoltageUnits, p::Piezo, is_cl::Bool) = mon2displacement(mon, p, is_cl, 0.0N)

max_force(stif::HasStiffnessUnits, displacement::HasLengthUnits) = stif * displacement

#TODO: consult with Piezosystem Jena to make sure this is accurate.  As noted elsewhere in code comments, it's not obvious how to do this calculation with the NanoSX positioners.
function max_force(p::Piezo, cur_disp::HasLengthUnits, direction::Int)
    d = direction > 0 ? max_displacement(p) - cur_disp : -cur_disp
    return max_force(stiffness(p), d)
end

function max_force(p::Piezo, pos::HasLengthUnits, is_cl::Bool, direction::Int)
    if direction == 0
        error("Direction of motion must be positive or negative")
    end
    kt = stiffness(p)
    nd = max_displacement(p)
    if is_cl
        pos = closed2open(pos, p)
    end
    cur_disp = blocked_pad(p) + pos - pmin(p, false)
    return max_force(p, cur_disp, direction)
end

function max_force(p::Piezo, cur_pos::HasLengthUnits, new_pos::HasLengthUnits, is_cl::Bool)
    direction = sign(new_pos - cur_pos)
    return max_force(p, cur_pos, is_cl, direction)
end

#Useful for NanoSX piezos which do not specify effective mass
#Instead they specify resonance frequency without load and with one more more loads.
#This solves for effective mass using two points on the curve
function effective_mass(f0, f_load, m_load)
    #77.1917g for NanoSX800 using the zero and f_load = 300g points (note the equation doesn't fit the points they gave exactly, seems to fit better at higher loads)
    #In theory this one should be equivalent:
    #effective_mass(f0, stif) = stif/(2*pi*f0)^2
    temp = f_load^2 / f0^2
    return  -m_load * temp / (temp - 1)
end

loaded_resonance(f0::HasInverseTimeUnits, m_eff::HasMassUnits, m_load::HasMassUnits) = uconvert(Unitful.Hz, f0 * sqrt(m_eff/(m_eff+m_load)))
loaded_resonance(p::Piezo, m_load::HasMassUnits) = loaded_resonance(resonance(p), effective_mass(p), m_load)

function mod2pos(mod::HasVoltageUnits, a::SimpleAmplifier, p::Piezo, is_cl::Bool)
    @assert mod >= in_min(a) && mod <= in_max(a)
    mod_frac = (mod - in_min(a)) / in_span(a)
    return pmin(p, is_cl) + mod_frac * pspan(p, is_cl)
end

function pos2mod(pos::HasLengthUnits, a::SimpleAmplifier, p::Piezo, is_cl::Bool)
    @assert pos >= pmin(p, is_cl) && pos <= pmax(p, is_cl)
    pos_frac = (pos - pmin(p, is_cl)) / pspan(p, is_cl)
    return in_min(a) + pos_frac * in_span(a)
end

mod2displacement(mod::HasVoltageUnits, a::SimpleAmplifier, p::Piezo, is_cl::Bool) = pos2displacement(mod2pos(mod, a, p, is_cl), p, is_cl)

function displacement2mod(disp::HasLengthUnits, p::Piezo, a::SimpleAmplifier, is_cl::Bool)
    if !is_cl
        error("Don't yet trust this function in open-loop mode")
    end
    frac = disp / max_displacement(p)
    return in_min(a) + frac * (in_max(a) - in_min(a))
end

POSITIONERS = Dict{String, Any}()

function retrieve_positioner(pos_name::String)
    if !haskey(POSITIONERS, pos_name)
        error("Unknown positioner")
    end
    return POSITIONERS[pos_name]
end

function register_positioner(pos::T) where {T<:AbstractPositioner}
    if haskey(POSITIONERS, name(pos))
        error("An positioner named $(name(pos)) is already registered.")
    end
    POSITIONERS[name(pos)] = pos
end


#The NanoX / NanoSX series piezos actually use two opposing ceramic piezo stacks per positioner.
#When one pushes, the other pulls.  In principle this could allow the maximum generable force of the 
#device to remain constant over the entire range of motion.  However it's not clear from spec sheets
#that this is true.
#Alternatively if the push and pull forces are additive then the maximum achievable force can be calculated
#like a conventional piezo.  The force would simply be double the force that a single piezo could generate
#for a given displacement (calculated as the absolute difference between current position and position attained without
#resisting forces
#A maximum push/pull force of 100.0N is listed, along with an open loop diplacement max
#of 900um.  If one tries to apply the basic equation for force generation:
#F = kt * L (where kt is stiffness of the piezo in N/um and L is max displacement in um)
#Then it's not possible to produce a constant 100.0N force throughout the range using this push/pull strategy.
#(the displacements of the two would have to be offset by 500um in that case, which means they would go negative at the extremes of the range)
#Instead 180.0N comes up as the max force when you use 900um as the nominal max
#Some possible complications:
#1. 900um is not the "nominal max displacement"
#2. 100.0N is not the max generable force
#Option 1 makes sense only if the real displacement is greater that 900, which would mean a max force greater than 180, not less
#Option 2 is possible if they are somehow being conservative
#OR the push/pull forces are additive, meaning that the most force can be generated at the edges of the piezo's range (only
# when that force is directed toward the center of the range)
#That's my favorite option for now.  But then it's still unclear where 100N comes from.  If the nominal max disp is really
#900um then 100N can only be achieved between 250um and 650um in open loop mode.
#also the "max load" is only 50N, suggesting it can't do 100N throughout the range.
#but these numbers suggest that 50N is only achievable from 125um to 775um open loop
#Let's let nominal max displacement be larger than specified:
#to achieve 50N throughout the open loop range then the true range must be larger than that.  How much larger?
#50N = d * 0.2 * 2
#d = 125um on either side of the range
#So the nominal displacement would be 900um + 125um*2 = 1150um
