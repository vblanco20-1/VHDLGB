use std.env.all;
use std.textio.all;
use work.testbench_utils.all;
use work.csv_file_reader_pkg.all;

library vunit_lib;
context vunit_lib.vunit_context;

-- Testbench for the csv_file_reader_pkg package. Test the package's basic
-- operation by reading data from known test files and checking the values read
-- against their expected values.
entity csv_file_read_pkg_tb is
    generic (runner_cfg : string);
end;

architecture testbench of csv_file_read_pkg_tb is
    
    procedure read_test_files is
        variable csv_file_1: csv_file_reader_type;
        variable csv_file_2: csv_file_reader_type;
        variable read_string: string(1 to 256);
        variable read_integer: integer;
        variable read_boolean: boolean;
        variable read_real: real;
    begin
        puts("opening CSV files");
        csv_file_1.initialize("/mnt/d/FPGA/PGB/PGB.srcs/sim_1/new/data/test_file_1.csv");
        --csv_file_2.initialize("c:\intel\projects\fpga\decision_tree_nsl_kdd\vhdl\testbench\data\test_file_2.csv");

        puts("testing 1st line of the csv file: 1,abc,true,0.5,0110");
        csv_file_1.readline;
        puts("reading csv1");
        read_integer := csv_file_1.read_integer;
        read_string := csv_file_1.read_string;
        read_boolean := csv_file_1.read_boolean;
        read_real := csv_file_1.read_real;
        assert_that("integer value read is 1", read_integer = 1);
        assert_that("string value read is 'abc'", read_string(1 to 3) = "abc");
        --assert_that("boolean value read is 'true'", read_boolean = true);
        assert_that("real value read is 0.5", read_real = 0.5);
        assert_that("end of file was not reached", csv_file_1.end_of_file = false);
      

        puts("testing 2nd line of the csv file: 2,xyz,false,-1.0,0000");
        csv_file_1.readline;
        read_integer := csv_file_1.read_integer;
        read_string := csv_file_1.read_string;
        read_boolean := csv_file_1.read_boolean;
        read_real := csv_file_1.read_real;
        assert_that("integer value read is 2", read_integer = 2);
        assert_that("string value read is 'xyz'", read_string(1 to 3) = "xyz");
       -- assert_that("boolean value read is 'false'", read_boolean = false);
        assert_that("real value read is -1.0", read_real = -1.0);
        assert_that("end of file was reached", csv_file_1.end_of_file = true);
    end;
    
begin
    main: process begin
        test_runner_setup(runner, runner_cfg);
        puts("Starting testbench...");
        read_test_files;
        puts("End of testbench. All tests passed.");
        test_runner_cleanup(runner);
    end process;
end;