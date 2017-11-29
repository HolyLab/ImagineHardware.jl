mutable struct PidController{T}
    kp::T
    ki::HasInverseTimeUnits{T}
    kd::HasTimeUnits{T}
    sample_rate::HasInverseTimeUnits{T}
end

samprate(pc::PidController) = pc.sample_rate
set_kp!(pc::PidController, val::Float64) = pc.kp = val
set_ki!(pc::PidController, val::HasInverseTimeUnits) = pc.ki = val
set_kd!(pc::PidController, val::HasTimeUnits) = pc.kd = val

kp(pc::PidController) = pc.kp
ki(pc::PidController) = pc.ki
kd(pc::PidController) = pc.kd

DEFAULT_PIDS = Dict{String, Any}()

function retrieve_pid(rig_name::String)
    if !haskey(DEFAULT_PIDS, rig_name)
        error("Unknown rig")
    end
    return DEFAULT_PIDS[rig_name]
end

function register_pid(pid::PidController, rig_name::String)
    if haskey(DEFAULT_PIDS, rig_name)
        error("Rig $rig_name already has a default PidController.")
    end
    DEFAULT_PIDS[rig_name] = pid
end
