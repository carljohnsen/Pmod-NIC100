library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ram is
    port(
        ena_a : in std_logic;
        addr_a : in std_logic_vector(10 downto 0);
        wrena_a : in std_logic;
        wrdata_a : in std_logic_vector(7 downto 0);
        rddata_a : out std_logic_vector(7 downto 0);
        clk_a : in std_logic;
        rst_a : in std_logic;
        
        ena_b : in std_logic;
        addr_b : in std_logic_vector(10 downto 0);
        wrena_b : in std_logic;
        wrdata_b : in std_logic_vector(7 downto 0);
        rddata_b : out std_logic_vector(7 downto 0);
        clk_b : in std_logic;
        rst_b : in std_logic
    );
end ram;

architecture RTL of ram is
    type mem_type is array (1499 downto 0) of std_logic_vector(7 downto 0);
    shared variable mem : mem_type;
begin

    process (clk_a, rst_a)
    begin
        if rst_a = '0' then
            rddata_a <= (others => '0');
        elsif rising_edge(clk_a) then
            if ena_a = '1' then
                rddata_a <= mem(to_integer(unsigned(addr_a)));
                if wrena_a = '1' then
                    mem(to_integer(unsigned(addr_a))) := wrdata_a;
                end if;
            end if;
        end if;
    end process;

    process (clk_b, rst_b)
    begin
        if rst_b = '0' then
            rddata_b <= (others => '0');
        elsif rising_edge(clk_b) then
            if ena_b = '1' then
                rddata_b <= mem(to_integer(unsigned(addr_b)));
                if wrena_b = '1' then
                    mem(to_integer(unsigned(addr_b))) := wrdata_b;
                end if;
            end if;
        end if;
    end process;
end RTL;