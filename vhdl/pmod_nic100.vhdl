library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pmod_nic100 is
    port(
        pmod_mosi : out std_logic;    
        pmod_miso : in std_logic;    
        pmod_ss   : out std_logic;
        pmod_sck  : out std_logic;

        status_debug : out std_logic_vector(1 downto 0);
        status_error : out std_logic;
        status_stage : out std_logic_vector(3 downto 0);

        bram_ena    : out std_logic;
        bram_addr   : out std_logic_vector(10 downto 0);
        bram_wrena  : out std_logic;
        bram_wrdata : out std_logic_vector(7 downto 0);
        bram_rddata : in std_logic_vector(7 downto 0);
        --bram_clk    : out std_logic;
        --bram_rst    : out std_logic;

        busy   : out std_logic;
        rx     : in std_logic;
        rx_len : out std_logic_vector(10 downto 0);
        tx     : in std_logic;
        tx_len : in std_logic_vector(10 downto 0);

        clk : in std_logic;
        rst : in std_logic
    );
end pmod_nic100;

architecture RTL of pmod_nic100 is

    --signal ena_a    : std_logic;
    --signal addr_a   : std_logic_vector(10 downto 0);
    --signal wrena_a  : std_logic;
    --signal wrdata_a : std_logic_vector(7 downto 0);
    --signal rddata_a : std_logic_vector(7 downto 0);

    signal wr_valid    : std_logic;
    signal wr_data     : std_logic_vector(7 downto 0);
    signal wr_done     : std_logic;
    signal wr_got_byte : std_logic;

    signal rd_valid : std_logic;
    signal rd_stop  : std_logic;
    signal rd_data  : std_logic_vector(7 downto 0);

    signal ss : std_logic;

begin
    
    --bram : entity work.ram
    --port map(
    --    ena_a    => ena_a,
    --    addr_a   => addr_a,
    --    wrena_a  => wrena_a,
    --    wrdata_a => wrdata_a,
    --    rddata_a => rddata_a,
    --    clk_a    => clk,
    --    rst_a    => rst,
    --
    --    ena_b    => bram_ena,
    --    addr_b   => bram_addr,
    --    wrena_b  => bram_wrena,
    --    wrdata_b => bram_wrdata,
    --    rddata_b => bram_rddata,
    --    clk_b    => bram_clk,
    --    rst_b    => bram_rst
    --);

    spi : entity work.spi
    port map(
        wr_valid    => wr_valid,
        wr_data     => wr_data,
        wr_done     => wr_done,
        wr_got_byte => wr_got_byte,

        rd_valid => rd_valid,
        rd_stop  => rd_stop,
        rd_data  => rd_data,

        ss => ss,

        pmod_mosi => pmod_mosi,
        pmod_miso => pmod_miso,

        clk => clk,
        rst => rst
    );

    controller : entity work.controller
    port map(
        bram_ena    => bram_ena,
        bram_addr   => bram_addr,
        bram_wrena  => bram_wrena,
        bram_wrdata => bram_wrdata,
        bram_rddata => bram_rddata,

        wr_valid    => wr_valid,
        wr_data     => wr_data,
        wr_done     => wr_done,
        wr_got_byte => wr_got_byte,

        rd_valid => rd_valid,
        rd_stop  => rd_stop,
        rd_data  => rd_data,

        status_debug => status_debug,
        status_error => status_error,
        status_stage => status_stage,

        busy   => busy,
        rx     => rx,
        rx_len => rx_len,
        tx     => tx,
        tx_len => tx_len,

        clk => clk,
        rst => rst
    );

    clock : entity work.clock
    port map(
        ss => ss,
        
        pmod_sck => pmod_sck,

        clk => clk,
        rst => rst
    );

    pmod_ss <= ss;

end RTL;