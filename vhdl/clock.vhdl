library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity clock is
    port(
        ss : in std_logic;
        
        pmod_sck : out std_logic;

        clk : in std_logic;
        rst : in std_logic
    );
end clock;

architecture RTL of clock is

    signal clk_ena : std_logic;

begin

    process (clk, rst)
    begin
        if rst = '0' then
            clk_ena <= '0';
        elsif rising_edge(clk) then
            if ss = '0' then
                clk_ena <= '1';
            else
                clk_ena <= '0';
            end if;
        end if;
    end process;
    
    process (clk)
    begin
        pmod_sck <= not clk and clk_ena;
    end process;

end RTL;