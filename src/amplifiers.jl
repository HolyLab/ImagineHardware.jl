abstract type AbstractAmplifier end

immutable SimpleAmplifier{T} <: AbstractAmplifier
#    Vin::ClosedInterval{typeof(0.0*Unitful.V)}
    name::String
    in_min::HasVoltageUnits{T}
    in_max::HasVoltageUnits{T}
    gain::Float64
    offset::HasVoltageUnits{T}
    current_max::HasCurrentUnits{T}
end

name(amp::SimpleAmplifier) = amp.name
in_min(amp::SimpleAmplifier) = amp.in_min
out_min(amp::SimpleAmplifier) = amp.in_min*gain + offset
in_max(amp::SimpleAmplifier) = amp.in_max
out_max(amp::SimpleAmplifier) = amp.in_max*gain + offset
#in_rng(amp::SimpleAmplifier) = ClosedInterval(in_min(amp), in_max(amp))
#out_rng(amp::SimpleAmplifier) = ClosedInterval(out_min(amp), out_max(amp))
in_span(amp::SimpleAmplifier) = in_max(amp) - in_min(amp)
out_span(amp::SimpleAmplifier) = out_max(amp) - out_min(amp)
current_max(amp::SimpleAmplifier) = amp.current_max
gain(amp::SimpleAmplifier) = amp.gain
offset(amp::SimpleAmplifier) = amp.offset

function validate_input(amp::SimpleAmplifier, input::HasVoltageUnits)
    if input < in_min(amp) || input > in_max(amp)
        error("Voltage $command is outside of the acceptable command range of the amplifier")
    end
end

function amplify(amp::SimpleAmplifier, input::HasVoltageUnits)
    validate_input(amp, input)
    return gain(amp) * input + offset(amp)
end

AMPLIFIERS = Dict{String, Any}()

function retrieve_amplifier(amp_name::String)
    if !haskey(AMPLIFIERS, amp_name)
        error("Unknown amplifier")
    end
    return AMPLIFIERS[amp_name]
end

function register_amplifier(amp::T) where {T<:AbstractAmplifier}
    if haskey(AMPLIFIERS, name(amp))
        error("An amplifier named $(name(amp)) is already registered.")
    end
    AMPLIFIERS[name(amp)] = amp
end

