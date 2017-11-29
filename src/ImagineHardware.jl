module ImagineHardware

using Unitful, UnitAliases
import Unitful: V, μm, m, A, mA, N, s, Hz, g, μF
import Base: position, clamp

include("amplifiers.jl")
include("registered_amplifiers.jl")
include("pids.jl")
include("registered_pids.jl")
include("piezos.jl")
include("registered_positioners.jl")
include("piezosystems.jl")
include("registered_piezosystems.jl")

export  AbstractAmplifier,
        SimpleAmplifier,
        retrieve_amplifier, register_amplifier,
        amplify, gain, offset, in_min, in_max, out_min, out_max, current_max, name,

        PidController,
        kp, ki, kd,
        set_kp!, set_ki!, set_kd!,
        samprate,
        retrieve_pid, register_pid,

        AbstractPositioner,
        Piezo,
        retrieve_positioner, register_positioner,
	pmin, pmax, pspan, vmin_in, vmax_in, vspan_in, vmin_out, vmax_out, vspan_out, pos2mon, mon2pos,
        closed_loop_pad,
	max_displacement,
	capacitance,
	motion_axis,
	stiffness, stiffness_all,
        clamp,
	effective_mass,
	resonance, resonance_all,
	max_force,
        loaded_resonance,
        closed2open, open2closed,
        pos2mon, mon2pos,
        pos2mod, mod2pos,
        pos2displacement, displacement2pos,
        input2displacement, displacement2input,
        mon2displacement, displacement2mon,
        mod2displacement, displacement2mod,
        input2pos, pos2input,
        
        PiezoSystem,
        amplifier, piezo, pid_controller,
        retrieve_piezosystem, register_piezosystem
        
end
