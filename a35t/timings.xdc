# Contraints de tiempo

# El reloj externo. Los relojes creados por el MMCM2 ya están añadidos automaticamente
create_clock -name clk50 -period 20 [get_nets clk50mhz]

# Tiempo máximo desde flanco de reloj hasta que cambia la salida de la VGA.
set_output_delay -clock [get_clocks -of_objects [get_nets sysclk]] -max 10 [get_ports hsync]
set_output_delay -clock [get_clocks -of_objects [get_nets sysclk]] -max 10 [get_ports vsync]
set_output_delay -clock [get_clocks -of_objects [get_nets sysclk]] -max 10 [get_ports r]
set_output_delay -clock [get_clocks -of_objects [get_nets sysclk]] -max 10 [get_ports g]
set_output_delay -clock [get_clocks -of_objects [get_nets sysclk]] -max 10 [get_ports b]
