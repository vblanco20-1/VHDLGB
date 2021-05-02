// testbuilder.cpp : Defines the entry point for the application.
//
#include <fmt/core.h>
#include "alutests.h"
#include <random>

alu_out add(alu_in in)
{
	alu_out out{};
	unsigned int sum = in.op_A + in.op_B;	

	if (sum & 0xff00)	out.flags.c = true;

	if (((in.op_A & 0x0f) + (in.op_B & 0x0f)) > 0x0f)  out.flags.h = true;

	if ((sum & 0x00FF) == 0)	out.flags.z = true;

	out.op_R = uint16_t(sum & 0xff);

	return out;
}

alu_out adc(alu_in in)
{
	alu_out out{};
	unsigned int carry = in.f_carry ? 1 : 0;
	unsigned int sum = in.op_A + in.op_B + carry;
	unsigned int halfsum = ((in.op_A & 0x0f) + (in.op_B & 0x0f)) + carry;
	if (sum & 0xff00)	out.flags.c = true;

	if (halfsum  > 0x0f)  out.flags.h = true;

	if ((sum & 0x00FF) == 0)	out.flags.z = true;

	out.op_R = uint16_t(sum & 0xff);

	return out;
}

alu_out sub(alu_in in)
{
	alu_out out{};
	unsigned int sum = in.op_A - in.op_B;
	out.flags.n = true;

	if (in.op_B > in.op_A) out.flags.c = true;

	if ((in.op_B & 0x0f) > (in.op_A & 0x0f)) out.flags.h = true;

	if (sum == 0)	out.flags.z = true;

	out.op_R = uint16_t(sum & 0xff);
	return out;
}


alu_out sbc(alu_in in)
{
	alu_out out{};
	unsigned int carry = in.f_carry ? 1 : 0;
	int sum = in.op_A - in.op_B - carry;
	int halfsum = ((in.op_A & 0x0f) - (in.op_B & 0x0f)) - carry;
	out.flags.n = true;

	if (sum < 0) out.flags.c = true;

	if (halfsum < 0)  out.flags.h = true;

	if ((sum & 0x00FF) == 0)	out.flags.z = true;

	out.op_R = uint16_t(sum & 0xff);
	return out;
}


alu_out _and(alu_in in)
{
	alu_out out{};
	out.op_R = in.op_A & in.op_B;
	
	out.flags.h = true;

	if (out.op_R == 0)
	{
		out.flags.z = true;
	}
	return out;
}
alu_out _or(alu_in in)
{
	alu_out out{};	

	out.op_R = in.op_A | in.op_B;

	if (out.op_R == 0)
	{
		out.flags.z = true;
	}
	return out;
}
alu_out _xor(alu_in in)
{
	alu_out out{};

	out.op_R = in.op_A ^ in.op_B;

	if (out.op_R == 0)
	{
		out.flags.z = true;
	}
	return out;
}


alu_out exec_alu(alu_in in)
{
	alu_out res;
	switch (in.mode) {
	case alu_op::ADD: 
		if (in.w_carry && in.f_carry)
			return adc(in);
		else
			return add(in);
		break;
	case alu_op::SUB: 
		if (in.w_carry && in.f_carry)
			return sbc(in);
		else
			return sub(in);
		break;
	case alu_op::AND: 
		return _and(in);
		break;
	case alu_op::OR: 
		return _or(in);
		break;
	case alu_op::XOR: 
		return _xor(in);
		break;
	}
	return alu_out{};
}

std::string alu_test_case::build_csv()
{
	return fmt::format("{},{},{},{},{},{},{},{},{},{},{}\n", 
		input.op_A, input.op_B, (int)input.db,
		int(input.w_carry), (int)input.f_carry,
		output.op_R, 
		(int)output.flags.z, (int)output.flags.n, (int)output.flags.h, (int)output.flags.c,
		testname);
}

alu_test_case alu_test::calculate(alu_op mode)
{
	alu_test_case test;
	test.input.op_A = op_A;
	test.input.op_B = op_B;
	test.input.f_carry = usecarry;
	test.input.w_carry = usecarry;
	test.input.mode = mode;
	test.input.db = false;
	test.testname = name;
	test.output = exec_alu(test.input);
	return test;
}

const std::vector<alu_test> common_tests =
{
	{0,0,false,"allzero"},
	{0,0,true,"zero carry"},
	{15,1,false,"half carry"},
	{15,0,true,"half carry, c"},
	{255,0,true,"huge"},
	{0,255,true,"huge rev"},
	{0,255,false,"huge rev"},
	{255,1,true,"huge"},
	{255,255,false,"big"},
	{255,205,true,"huge"},
	{10,20,false,"simple"},
	{15,15,false,"simple"},
};


std::default_random_engine rng;

std::uniform_int_distribution<uint16_t> _8bit(0, 0xFF);
std::uniform_int_distribution<uint16_t> _16bit(0, 0xFFFF);
std::vector<alu_test_case> test_battery_add() {

	std::vector <alu_test_case> tests;

	for (auto t : common_tests)
	{
		tests.push_back(t.calculate(alu_op::ADD));
	}

	int numrand = 64;

	for (int i = 0; i < numrand; i++)
	{
		alu_test rndtest;
		rndtest.op_A = _8bit(rng);
		rndtest.op_B = _8bit(rng);
		rndtest.usecarry = (_8bit(rng) & 1) == 0;
		rndtest.name = fmt::format("random {}", i);

		tests.push_back(rndtest.calculate(alu_op::ADD));
	}

	return tests;
}

std::vector<alu_test_case> test_battery_sub() {

	std::vector <alu_test_case> tests;

	for (auto t : common_tests)
	{
		tests.push_back(t.calculate(alu_op::SUB));
	}

	int numrand = 64;

	for (int i = 0; i < numrand; i++)
	{
		alu_test rndtest;
		rndtest.op_A = _8bit(rng);
		rndtest.op_B = _8bit(rng);
		rndtest.usecarry = (_8bit(rng) & 1) == 0;
		rndtest.name = fmt::format("random {}", i);

		tests.push_back(rndtest.calculate(alu_op::SUB));
	}

	return tests;
}

std::vector<alu_test_case> test_battery_and() {

	std::vector <alu_test_case> tests;

	for (auto t : common_tests)
	{
		tests.push_back(t.calculate(alu_op::AND));
	}

	int numrand = 64;

	for (int i = 0; i < numrand; i++)
	{
		alu_test rndtest;
		rndtest.op_A = _8bit(rng);
		rndtest.op_B = _8bit(rng);
		rndtest.usecarry = (_8bit(rng) & 1) == 0;
		rndtest.name = fmt::format("random {}", i);

		tests.push_back(rndtest.calculate(alu_op::AND));
	}

	return tests;
}



std::vector<alu_test_case> test_battery_or() {

	std::vector <alu_test_case> tests;

	for (auto t : common_tests)
	{
		tests.push_back(t.calculate(alu_op::OR));
	}

	int numrand = 64;

	for (int i = 0; i < numrand; i++)
	{
		alu_test rndtest;
		rndtest.op_A = _8bit(rng);
		rndtest.op_B = _8bit(rng);
		rndtest.usecarry = (_8bit(rng) & 1) == 0;
		rndtest.name = fmt::format("random {}", i);

		tests.push_back(rndtest.calculate(alu_op::OR));
	}

	return tests;
}




std::vector<alu_test_case> test_battery_xor() {

	std::vector <alu_test_case> tests;

	for (auto t : common_tests)
	{
		tests.push_back(t.calculate(alu_op::XOR));
	}

	int numrand = 64;

	for (int i = 0; i < numrand; i++)
	{
		alu_test rndtest;
		rndtest.op_A = _8bit(rng);
		rndtest.op_B = _8bit(rng);
		rndtest.usecarry = (_8bit(rng) & 1) == 0;
		rndtest.name = fmt::format("random {}", i);

		tests.push_back(rndtest.calculate(alu_op::XOR));
	}

	return tests;
}