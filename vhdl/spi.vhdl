library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi is
    port(
        wr_valid : in std_logic;
        wr_data : in std_logic_vector(7 downto 0);
        wr_done : out std_logic;
        wr_got_byte : out std_logic;

        rd_valid : out std_logic;
        rd_stop : in std_logic;
        rd_data : out std_logic_vector(7 downto 0);

        ss : out std_logic;
        pmod_mosi : out std_logic;
        pmod_miso : in std_logic;

        clk : in std_logic;
        rst : in std_logic
    );
end spi;

architecture RTL of spi is

    type comms_state_type is (
        idle, reading, writing, delay
    );

    signal comm_state : comms_state_type;
    signal i : integer;

begin

    process (clk, rst)
    variable running : std_logic;
    variable tmp : std_logic_vector(7 downto 0);
    begin
        if rst = '0' then
            comm_state <= idle;

            wr_done <= '0';
            wr_got_byte <= '0';

            rd_valid <= '0';
            rd_data <= (others => '0');

            ss <= '1';
            pmod_mosi <= '0';

            i <= 0;
            tmp := (others => '0');
            running := '0';
        elsif rising_edge(clk) then
            case comm_state is
                when idle =>
                    wr_done <= '0';
                    rd_valid <= '0';
                    if wr_valid = '1' then
                        comm_state <= writing;
                        ss <= '0';
                        if running = '1' then
                            pmod_mosi <= wr_data(7);
                            i <= 6;
                        else
                            i <= 7;
                        end if;
                        tmp(7 downto 0) := wr_data;
                        wr_got_byte <= '1';
                        running := '1';
                    elsif rd_stop = '0' then
                        comm_state <= reading;
                        ss <= '0';
                        i <= 7;
                        running := '1';
                    else
                        if running = '1' then
                            i <= 1;
                            comm_state <= delay;
                        end if;
                        running := '0';
                    end if;

                when reading =>
                    tmp(i) := pmod_miso;
                    if rd_stop = '1' then
                        comm_state <= idle;
                        ss <= '1';
                    elsif i = 0 then
                        rd_valid <= '1';
                        rd_data <= tmp(7 downto 0);
                        i <= 7;
                    else
                        i <= i - 1;
                        rd_valid <= '0';
                    end if;

                when writing =>
                    wr_got_byte <= '0';
                    pmod_mosi <= tmp(i);
                    if i = 0 then
                        comm_state <= idle;
                        wr_done <= '1';
                    else
                        i <= i - 1;
                    end if;
                
                when delay =>
                    ss <= '1';
                    if i = 0 then
                        comm_state <= idle;
                    else
                        i <= i - 1;
                    end if;
            end case;
        end if;
    end process;
end RTL;