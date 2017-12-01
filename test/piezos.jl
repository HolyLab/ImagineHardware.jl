using Base.Test
using ImagineHardware
using Unitful
import Unitful: V, s, Hz, m, μm, A, mA, N, g, μF

p = retrieve_positioner("NanoSX800")
@test name(p) == "NanoSX800"
@test vmin_in(p) == -20.0V
@test vmax_in(p) == 130.0V
@test vspan_in(p) == vmax_in(p) - vmin_in(p)
@test ImagineHardware.mon_slope(p, true) == 10.0V / 800.0μm
@test ImagineHardware.mon_slope(p, false) == 10.0V / 900.0μm
@test closed_loop_pad(p) == 50.0μm
@test vmin_out(p, true) == 0.0V
@test vmax_out(p, true) == 10.0V
@test vmin_out(p, true) == 0.0V
@test vmax_out(p, true) == 10.0V
@test vmin_out(p, false) == 0.0V
@test vmax_out(p, false) == 10.0V
@test vspan_out(p, true) == vmax_out(p, true) - vmin_out(p, true)
@test vspan_out(p, false) == vmax_out(p, false) - vmin_out(p, false)
@test pmin(p, true) == 0.0μm
@test pmax(p, true) == 800.0μm
@test pmin(p, false) == -50.0μm
@test pmax(p, false) == 850.0μm
@test pspan(p, true) == pmax(p, true) - pmin(p, true)
@test pspan(p, false) == pmax(p, false) - pmin(p, false)
@test ImagineHardware.blocked_pad(p) == 125μm
@test closed2open(0.0μm, p) == 0.0μm
@test closed2open(800.0μm, p) == 800.0μm
#@test_throws Exception closed2open(-10.0μm, p) #relaxed this requirement because the piezo can go this far in closed loop mode, though it's not supposed to
@test open2closed(0.0μm, p) == 0.0μm
@test open2closed(800.0μm, p) == 800.0μm
@test_throws Exception open2closed(-10.0μm, p)
@test max_displacement(p) == 1150μm
@test capacitance(p) == 7.0μF
@test motion_axis(p) == 1
@test stiffness(p) == stiffness(p, 1) == 0.2N/μm
@test stiffness_all(p) == (0.2N/μm, 2.5N/μm, 2.5N/μm)
@test effective_mass(p) == 77.1917g
@test resonance(p) == resonance(p, 1) == 210.0Hz
@test resonance_all(p) == (210.0Hz, 500.0Hz, 700.0Hz)

@test mon2pos(0.0V, p, true) == 0.0μm
@test mon2pos(0.0V, p, false) == -50.0μm
@test mon2pos(10.0V, p, true) == 800.0μm
@test mon2pos(10.0V, p, false) == 850.0μm
@test_throws Exception mon2pos(10.1V, p, false)
@test_throws Exception mon2pos(10.1V, p, true)
@test pos2mon(0.0μm, p, true) == 0.0V
@test pos2mon(-50.0μm, p, false) == 0.0V
@test pos2mon(800.0μm, p, true) == 10.0V
@test pos2mon(850.0μm, p, false) == 10.0V
@test_throws Exception pos2mon(1000μm, p, false)
#@test_throws Exception pos2mon(808μm, p, true) #relaxed this requirement becase the piezo can go this far in closed loop mode, though it's not supposed to

@test displacement2pos(0μm, p, false) == -50μm #blocked internally
@test displacement2pos(125μm, p, false) == -50μm
@test displacement2pos(125μm, p, false) == -50μm
@test displacement2pos(1025μm, p, false) == 850μm
@test displacement2pos(175μm, p, true) == 0μm
@test displacement2pos(975μm, p, true) == 800μm
@test_throws Exception displacement2pos(0μm, p, true)
@test_throws Exception displacement2pos(125μm, p, true)
@test_throws Exception displacement2pos(1025μm, p, true)
#including outside force
@test displacement2pos(125μm, p, false, 0.0N) == displacement2pos(125μm, p, false)
@test displacement2pos(125μm, p, false, 10.0N) == displacement2pos(125μm + uconvert(μm, 10.0N/stiffness(p)), p, false)

@test_throws Exception pos2displacement(-50μm, p, false)
@test_throws Exception pos2displacement(850μm, p, false)
@test pos2displacement(0μm, p, true) == 175μm
@test pos2displacement(800μm, p, true) == 975μm
@test pos2displacement(400μm, p, true) == 575μm
@test pos2displacement(400μm, p, false) == 575μm
#including outside force
@test pos2displacement(400μm, p, true, 0.0N) == 575μm
@test pos2displacement(400μm, p, false, 0.0N) == 575μm
@test pos2displacement(400μm, p, true, 10.0N) == 575μm - 10.0N/stiffness(p)
@test pos2displacement(400μm, p, true, 10.0N) == 575μm - 10.0N/stiffness(p)

@test input2displacement(-20.0V, p) == 0.0μm
@test input2displacement(130.0V, p) == max_displacement(p)
@test input2displacement(55.0V, p) == max_displacement(p) / 2
@test_throws Exception input2displacement(-30.0V, p)
@test_throws Exception input2displacement(140.0V, p)

@test displacement2input(0.0μm, p) == -20.0V
@test displacement2input(max_displacement(p) / 2, p) == 55.0V
@test displacement2input(max_displacement(p), p) == 130.0V
@test_throws Exception displacement2input(1200μm, p)
@test_throws Exception displacement2input(-10μm, p)

@test input2pos(-20.0V, p, false) == displacement2pos(0.0μm, p, false)
@test input2pos(-20.0V, p, false) == displacement2pos(0.0μm, p, false)
@test input2pos(130.0V, p, false) == displacement2pos(1150.0μm, p, false)
@test input2pos(130.0V, p, false) == displacement2pos(1150.0μm, p, false)
@test input2pos(55.0V, p, false) == displacement2pos(max_displacement(p)/2, p, false)
@test input2pos(55.0V, p, true) == displacement2pos(max_displacement(p)/2, p, true)
@test_throws Exception input2pos(-30.0V, p)
@test_throws Exception input2pos(140.0V, p)
#including outside force
@test input2pos(-20.0V, p, false, 0.0N) == input2pos(-20.0V, p, false)
@test input2pos(130.0V, p, false, 0.0N) == input2pos(130.0V, p, false)
@test input2pos(55.0V, p, false, 0.0N) == input2pos(55.0V, p, false)
@test input2pos(55.0V, p, true, 0.0N) == input2pos(55.0V, p, true)
@test input2pos(-20.0V, p, false, 10.0N) == displacement2pos(0.0μm, p, false, 10.0N)

#including outside force
@test pos2input(0μm, p, true, 0.0N) == pos2input(0μm, p, true)
@test pos2input(800μm, p, true, 0.0N) == pos2input(800μm, p, true)
@test pos2input(0μm, p, true, 10.0N) == displacement2input(pos2displacement(0μm, p, true, 10.0N), p)

#adjusted_displacement - compression = mon_displacement
#adjusted_displacement = mon_displacement + compression
#                  = mon_displacement + f / stiffness(p)
mon2displacement(0.0V, p, true) == pos2displacement(0.0μm, p, true)
@test_throws Exception mon2displacement(0.0V, p, false)
@test mon2displacement(5.0V, p, true) == max_displacement(p)/2
@test mon2displacement(0.0V, p, true, 0.0N) == pos2displacement(0.0μm, p, true, 0.0N)
@test_throws Exception mon2displacement(0.0V, p, false, 0.0N)
@test mon2displacement(0.0V, p, true, 1.0N) == pos2displacement(0.0μm, p, true, 1.0N)
@test_throws Exception mon2displacement(0.0V, p, false, 1.0N)

@test max_force(p, 0μm, 1) == stiffness(p) * max_displacement(p)
@test max_force(p, 800μm, -1) == stiffness(p) * -800μm # - pos2displacement(800.0μm, p, true))
@test max_force(p, 0μm, 800μm, true) == max_force(p, pos2displacement(0.0μm, p, true), 1)
@test max_force(p, 800μm, 0μm, true) == max_force(p, pos2displacement(800.0μm, p, true), -1) == -max_force(p, pos2displacement(0.0μm, p, true), 1)
@test max_force(p, 0μm, 800μm, false) == max_force(p, pos2displacement(0.0μm, p, false), 1)
@test max_force(p, 800μm, 0μm, false) == max_force(p, pos2displacement(800.0μm, p, false), -1) == -max_force(p, pos2displacement(0.0μm, p, false), 1)

@test loaded_resonance(100.0Hz, 70.0g, 100.0g) == uconvert(Unitful.Hz, 100.0Hz * sqrt(70.0g/(70.0g+100.0g)))
@test loaded_resonance(p, 500g) == loaded_resonance(resonance(p), effective_mass(p), 500g)

