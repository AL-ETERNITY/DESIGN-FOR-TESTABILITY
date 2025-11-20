library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity scan_dff is
  port(
    clk   : in  std_logic;
    reset : in  std_logic;  -- asynchronous reset
    se    : in  std_logic;  -- scan enable: 0 = di, 1 = si
    di    : in  std_logic;  -- functional data
    si    : in  std_logic;  -- scan data (serial)
    q     : out std_logic   -- flop output
  );
end scan_dff;

architecture rtl of scan_dff is
begin
  process(clk, reset)
  begin
    if reset = '1' then
      q <= '0';
    elsif rising_edge(clk) then
      if se = '1' then
        q <= si;
      else
        q <= di;
      end if;
    end if;
  end process;
end rtl;
