# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this file,
# You can obtain one at http://mozilla.org/MPL/2.0/.
#
# Copyright (c) 2014-2015, Lars Asplund lars.anders.asplund@gmail.com

from os.path import join, dirname
from vunit import VUnit

root = dirname(__file__)

src_path = join(root, "synthesis")
tb_path = join(root, "simulation")
fft_path = join(root, "ip\\altera\\fft\\src\\");

altera_sim_path = "C:\\altera\\15.0\\quartus\\eda\\sim_lib\\"


ui = VUnit.from_argv()
ui.add_osvvm()

ui.enable_location_preprocessing()
ui.enable_check_preprocessing()

sim = ui.add_library("sim");

sim.add_source_files(join(altera_sim_path, "altera_primitives.v"))
sim.add_source_files(join(altera_sim_path, "220model.v"))
sim.add_source_files(join(altera_sim_path, "sgate.v"))
sim.add_source_files(join(altera_sim_path, "altera_mf.v"))
sim.add_source_files(join(altera_sim_path, "altera_lnsim.sv"))
sim.add_source_files(join(altera_sim_path, "cycloneive_atoms.v"))

btle = ui.add_library("btle")

btle.add_source_files(join(src_path, "*.vhd"))
btle.add_source_files(join(tb_path, "*.vhd"))
btle.add_source_files(join(fft_path, "fft_ii_0_example_design_core.sv"))

ui.main()

