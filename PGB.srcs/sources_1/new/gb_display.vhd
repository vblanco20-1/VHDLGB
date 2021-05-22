library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

library work;
use work.gb_package.all;

entity gb_display is
	port
	(
		reset: in std_logic;
		clk_in: in std_logic;

		fb_data: in std_logic_vector(1 downto 0);
		fb_coord: out gb_px_coord;
		fb_read: out std_logic;

		hsyncb: out std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
end gb_display;

architecture gb_display_arch of gb_display is

signal romcolor : std_logic_vector(7 downto 0);
signal hcnt: std_logic_vector(8 downto 0);	
signal vcnt: std_logic_vector(9 downto 0);	
signal displaycolor : std_logic_vector(11 downto 0);

signal clock: std_logic;  --este es el pixel_clock
signal screen: std_logic;
signal hblank : std_logic;

begin

FB: process(clock,hcnt,vcnt)
variable gx,gy : std_logic_vector(7 downto 0);
variable sc: std_logic;
begin	
	if (clock'event and clock='1') then
		gx := "00000000"; gy := "00000000"; sc := '0';
		if(hcnt >= 10 and hcnt < 10+160) then -- we want to run it one pixel ahead
			if(vcnt >= 100 and vcnt < 450) then --duplicated Y
				gx := hcnt(7 downto 0) - 10 ;
				gy := vcnt(8 downto 1) - 50;
				sc := '1';
			end if;
		end if;

		case fb_data is

		when "00" => displaycolor <= x"FFF";
		when "01" => displaycolor <= x"AAA";
		when "10" => displaycolor <= x"777";
		when others => displaycolor <= x"222"; -- "11"

		end case;

		fb_coord.x <= gx;
		fb_coord.y <= gy;	
		screen <= sc;
		fb_read <= sc;
	end if;
end process;

A: process(clock,reset)
begin
	-- reset asynchronously clears pixel counter
	if reset='1' then
		hcnt <= "000000000";
	-- horiz. pixel counter increments on rising edge of dot clock
	elsif (clock'event and clock='1') then
		-- horiz. pixel counter rolls-over after 381 pixels
		if hcnt<380 then
			hcnt <= hcnt + 1;
		else
			hcnt <= "000000000";
		end if;
	end if;
end process;


B: process(hblank,reset)
begin
	-- reset asynchronously clears line counter
	if reset='1' then
		vcnt <= "0000000000";
	-- vert. line counter increments after every horiz. line
	elsif (hblank'event and hblank='1') then
		-- vert. line counter rolls-over after 528 lines
		if vcnt<527 then
			vcnt <= vcnt + 1;
		else
			vcnt <= "0000000000";
		end if;
	end if;
end process;


C: process(clock,reset)
begin
	-- reset asynchronously sets horizontal sync to inactive
	if reset='1' then
		hblank <= '1';
	-- horizontal sync is recomputed on the rising edge of every dot clock
	elsif (clock'event and clock='1') then
		-- horiz. sync is low in this interval to signal start of a new line
		if (hcnt>=291 and hcnt<337) then
			hblank <= '0';
		else
			hblank <= '1';
		end if;
	end if;
end process;

D: process(hblank,reset)
begin
	-- reset asynchronously sets vertical sync to inactive
	if reset='1' then
		vsyncb <= '1';
	-- vertical sync is recomputed at the end of every line of pixels
	elsif (hblank'event and hblank='1') then
		-- vert. sync is low in this interval to signal start of a new frame
		if (vcnt>=490 and vcnt<492) then
			vsyncb <= '0';
		else
			vsyncb <= '1';
		end if;
	end if;
end process;

clock <= clk_in;
hsyncb <= hblank;


rgb <= displaycolor when screen = '1' else x"000";

--rgb(3 downto 2) <= fb_data when screen = '1' else "00";
--rgb(1 downto 0) <= "00";
--rgb(11 downto 10) <= fb_data when screen = '1' else "00";
--rgb(9 downto 8) <= "00";
--rgb(7 downto 6) <= fb_data when screen = '1' else "00";
--rgb(5 downto 4) <= "00";



end gb_display_arch;

