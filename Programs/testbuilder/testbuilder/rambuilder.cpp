// imgprocess.cpp : This file contains the 'main' function. Program execution begins and ends there.
//

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>

void dump_file_to_ram(std::string input, std::string output)
{
	std::ifstream inputfile;
	inputfile.open(input, std::ios::binary);

	std::vector<unsigned char> data = std::vector<unsigned char>(std::istreambuf_iterator<char>(inputfile), std::istreambuf_iterator<char>());
	int n = data.size();
	std::ofstream file;
	file.open(output);

	file << R"(
		library IEEE;
		use IEEE.STD_LOGIC_1164.ALL;
		use IEEE.NUMERIC_STD.ALL;

		entity gb_tetris_rom is
		Port(clk : in std_logic; 
		idx : in std_logic_vector(15 downto 0);
					data: out std_logic_vector(7 downto 0));
		end gb_tetris_rom; 

		architecture Behavioral of gb_tetris_rom is
		constant DATA_WIDTH : integer := 8;	
	)";

	file << "constant RAM_SIZE : integer := " << n << ";\n";
	file << "TYPE mem_type IS ARRAY(0 TO RAM_SIZE-1) OF std_logic_vector((DATA_WIDTH-1) DOWNTO 0); \n";
	file << R"(

signal nxtdata  : std_logic_vector(7 downto 0); 


	)";
	file << "signal ram_block : mem_type := (" << std::endl;
	for (int i = 0; i < n; i++)
	{
		char buffer[50];

		sprintf_s(buffer, "%x", data[i] % 255);
		const char* str = "00";
		int len = strlen(buffer);
		if (len != 2)
		{

			if (len == 1)
			{
				buffer[1] = buffer[0];
				buffer[0] = str[0];
				buffer[2] = str[2];
			}
			else {
				buffer[0] = str[0];
				buffer[1] = str[1];
				buffer[2] = str[2];
			}
		}

		file << "x\"" << buffer;
		if (i != (data.size() - 1))
		{
			file << "\",";
		}
		else
		{
			file << "\");\n";
		}
	}

	file << R"(
attribute rom_style  : string;
attribute rom_style of ram_block : signal is "block";

begin
sync : process (clk,nxtdata)
begin
    if rising_edge(clk) then
		data <= nxtdata;
	end if;
end process;

comb : process (idx)
variable intid  : unsigned(15 downto 0);
variable intdx : integer;
begin
	intid := unsigned(idx);
	intdx := to_integer(intid);
   nxtdata <= ram_block(intdx);
end process;

end Behavioral;
	)";

}

// Run program: Ctrl + F5 or Debug > Start Without Debugging menu
// Debug program: F5 or Debug > Start Debugging menu

// Tips for Getting Started: 
//   1. Use the Solution Explorer window to add/manage files
//   2. Use the Team Explorer window to connect to source control
//   3. Use the Output window to see build output and other messages
//   4. Use the Error List window to view errors
//   5. Go to Project > Add New Item to create new code files, or Project > Add Existing Item to add existing code files to the project
//   6. In the future, to open this project again, go to File > Open > Project and select the .sln file
