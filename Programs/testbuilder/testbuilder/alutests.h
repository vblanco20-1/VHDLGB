// testbuilder.h : Include file for standard system include files,
// or project specific include files.

#pragma once

#include <string>
#include <vector>

enum class alu_op : uint8_t {
	ADD,SUB,AND,OR,XOR
};

struct alu_flags {
	bool z{ 0 };
	bool n{ 0 };
	bool h{ 0 };
	bool c{ 0 };
};
// make sure this fully matches the gb_alu.vhd
struct alu_in {
	uint16_t op_A;
	uint16_t op_B;
	alu_op mode;
	bool db;
	bool w_carry;
	bool f_carry;
};

struct alu_out {
	uint16_t op_R{0};
	alu_flags flags{};
};

struct alu_test_case {
	alu_in input;
	alu_out output;
	std::string testname;

	std::string build_csv();
};

struct alu_test {
	uint16_t op_A;
	uint16_t op_B;
	bool usecarry;
	std::string name;

	alu_test_case calculate(alu_op mode);
};

alu_out exec_alu(alu_in in);
std::vector<alu_test_case> test_battery_add();
std::vector<alu_test_case> test_battery_sub();
std::vector<alu_test_case> test_battery_and();
std::vector<alu_test_case> test_battery_or();
std::vector<alu_test_case> test_battery_xor();