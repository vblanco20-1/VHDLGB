library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;

entity vgacore is
	port
	(
		reset: in std_logic;	
		clk_in: in std_logic;
		hsyncb: out std_logic;	
		vsyncb: out std_logic;	
		rgb: out std_logic_vector(11 downto 0) 
	);
end vgacore;

architecture vgacore_arch of vgacore is

component gb_framebuffer is
  Port (clk : in std_logic; 
		cx,cy : in std_logic_vector(7 downto 0);
        color : out std_logic_vector(7 downto 0) );
end component;

signal romcolor : std_logic_vector(7 downto 0);
signal pixelcolor : std_logic_vector(7 downto 0);
signal hcnt: std_logic_vector(8 downto 0);	
signal vcnt: std_logic_vector(9 downto 0);	

signal clock: std_logic;  --este es el pixel_clock
signal screen: std_logic;
signal hblank : std_logic;


signal gby,gbx : std_logic_vector(7 downto 0);
begin

FB: process(clock,hcnt,vcnt)
variable gx,gy : std_logic_vector(7 downto 0);
variable sc: std_logic;
begin	
	if (clock'event and clock='1') then
		gx := "00000000"; gy := "00000000"; sc := '0';
		if(hcnt >= 49 and hcnt < 210) then -- we want to run it one pixel ahead
			if(vcnt >= 100 and vcnt < 400) then --duplicated Y
				gx := hcnt(7 downto 0) - 49 ;
				gy := vcnt(8 downto 1) - 50;
				sc := '1';
			end if;
		end if;
		gbx <= gx;	
		gby <= gy;		
		screen <= sc;
		pixelcolor <= romcolor;
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


-- A partir de aqui implementar los m?dulos que faltan, necesarios para dibujar en el monitor


rgb(3 downto 0) <= pixelcolor(7 downto 4) when screen = '1' else "0000"; --"00000000000" when screen = '0' else "10001100100";
rgb(7 downto 4) <= pixelcolor(7 downto 4) when screen = '1' else "0000";
rgb(11 downto 8) <= pixelcolor(7 downto 4) when screen = '1' else "0000";
--rgb(11) <= hcnt(1);

gbf: gb_framebuffer port map (clk_in,gbx,gby,romcolor);
 

end vgacore_arch;

