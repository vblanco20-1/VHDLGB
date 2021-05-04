// testbuilder.cpp : Defines the entry point for the application.
//

#include "testbuilder.h"
#include "alutests.h"
#include <fstream>
using namespace std;

void export_tests(std::vector<alu_test_case> addtests, std::string filename)
{
	std::ofstream f(filename);

	if (f.is_open())
	{
		f << "op_a,op_b,double,carry,fc,op_r,r_zero,r_sub,r_half,r_carry,name \n";
		for (auto t : addtests)
		{
			f << t.build_csv();
		}
	}
}
#include "rambuilder.h"
int main()
{
	auto addtests = test_battery_add();

	export_tests(addtests, "alu_add_tests.csv");

	auto subtests = test_battery_sub();

	export_tests(subtests, "alu_sub_tests.csv");

	auto andtests = test_battery_and();

	export_tests(andtests, "alu_and_tests.csv");

	auto ortests = test_battery_or();

	export_tests(ortests, "alu_or_tests.csv");

	auto xortests = test_battery_xor();

	export_tests(xortests, "alu_xor_tests.csv");

	dump_file_to_ram("D:/FPGA/PGB/PGB.srcs/sources_1/new/tetris.gb", "D:/FPGA/PGB/PGB.srcs/sources_1/new/tetrisdump.vhd");

	return 0;
}
