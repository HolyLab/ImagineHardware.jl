nanosx800 = Piezo("NanoSX800",
                  -20.0V,
                  130.0V,
                  0.0V,
                  10.0V,
                  -50.0μm,
                  850.0μm,
                  50.0μm,
                  1150.0μm, #900μm,#nominal max displacement
#                  125μm, #disp_offset (so when the positioner is at -50.0μm it's actually at 125μm for force calculations)
                  7.0μF,
                  1,   #motion axis
                  77.1917g, #effective mass
                  (210.0Hz, 500.0Hz, 700.0Hz), #resonance frequencies without load
                  (0.2N/μm, 2.5N/μm, 2.5N/μm) #stiffnesses
                 )

register_positioner(nanosx800) #used on OCPI2
