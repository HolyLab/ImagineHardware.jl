ocpi2_psys = PiezoSystem(retrieve_amplifier("30DV300"),
                         retrieve_positioner("NanoSX800"),
                                                  retrieve_pid("ocpi-2"))

register_piezosystem(ocpi2_psys, "ocpi-2")
