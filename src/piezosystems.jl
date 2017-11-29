immutable PiezoSystem{T}
    amp::SimpleAmplifier{T}
    piezo::Piezo{T}
    pid::PidController{T}
end

amplifier(ps::PiezoSystem) = ps.amp
piezo(ps::PiezoSystem) = ps.piezo
pid_controller(ps::PiezoSystem) = ps.pid
validate_command(ps::PiezoSystem, command) = validate_command(amp(ps), command)

PIEZOSYSTEMS = Dict{String, Any}()

function retrieve_piezosystem(rig_name::String)
    if !haskey(PIEZOSYSTEMS, rig_name)
        error("Unknown rig")
    end
    return PIEZOSYSTEMS[rig_name]
end

function register_piezosystem(ps::PiezoSystem, rig_name::String)
    if haskey(PIEZOSYSTEMS, rig_name)
        error("The rig $rig_name already has a registered PiezoSystem.")
    end
    PIEZOSYSTEMS[rig_name] = ps
end
