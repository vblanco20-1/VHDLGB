from vunit import VUnit
from pathlib import Path
# Create VUnit instance by parsing command line arguments
vu = VUnit.from_argv()
#vu.set_compile_option("ghdl.flags", ["--no-vital-checks"])
#vu.set_compile_option("ghdl.a_flags",["--ieee=standard"])
# Create library 'lib'
lib = vu.add_library("lib",vhdl_standard="2008")

SRC_PATH = Path(__file__).parent

# Add all files ending in .vhd in current working directory to library
lib.add_source_files(SRC_PATH / "PGB.srcs/sources_1/new/*.vhd",allow_empty = True)
lib.add_source_files(SRC_PATH / "PGB.srcs/sources_1/imports/new/*.vhd",allow_empty = True)

lib.add_source_files(SRC_PATH / "PGB.srcs/sim_1/new/*.vhd",allow_empty = True)


vu.set_compile_option("ghdl.a_flags", ["-fsynopsys"])
lib.set_compile_option("ghdl.a_flags", ["-fsynopsys"])

#vu.set_sim_option("ghdl.elab_flags", ["-fsynopsys"])
lib.set_sim_option("ghdl.elab_flags", ["-fsynopsys"])

#vu.set_compile_option("ghdl.a_flags", ["--ieee=standard"])
#
# Run vunit function
vu.main()