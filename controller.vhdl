library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity controller is
    port(
        bram_ena : out std_logic;
        bram_addr : out std_logic_vector(10 downto 0);
        bram_wrena : out std_logic;
        bram_wrdata : out std_logic_vector(7 downto 0);
        bram_rddata : in std_logic_vector(7 downto 0);

        wr_valid : out std_logic;
        wr_data : out std_logic_vector(7 downto 0);
        wr_done : in std_logic;
        wr_got_byte : in std_logic;

        rd_valid : in std_logic;
        rd_stop : out std_logic;
        rd_data : in std_logic_vector(7 downto 0);

        status_debug : out std_logic_vector(1 downto 0);
        status_error : out std_logic;
        status_stage : out std_logic_vector(3 downto 0);

        busy : out std_logic;
        tx : in std_logic;
        tx_len : in std_logic_vector(10 downto 0);
        rx : in std_logic;

        clk: in std_logic;
        rst: in std_logic
    );
end controller;

architecture RTL of controller is
    -- Types
    type control_state_type is (
        init0,  init1,  init2,  init3,  init4,  
        init5,  init6,  init7,  init8,  init9,  
        init10, init11, init12, init13, init14, 
        init15, init16, init17, init18, init19,
        init20, init21, init22, init23, init24,
        init25, init26, init27, init28, init29, 
        init30, init31, init32, init33, init34,
        init35, init36, init37, init38, init39,
        init40,
        ctrl_idle,
        tx0,  tx1,  tx2,  tx3,  tx4,  
        tx5,  tx6,  tx7,  tx8,  tx9,  
        tx10, tx11, tx12, tx13, tx14, 
        tx15, tx16, tx17, tx18, tx19, 
        tx20
    );

    -- Signals
    signal control_state : control_state_type;
    signal i, j : integer;
    signal buf : std_logic_vector(15 downto 0);

    -- Constants
    -- Instructions
    constant WCRU     : std_logic_vector(7 downto 0) := "00100010";
    constant RCRU     : std_logic_vector(7 downto 0) := "00100000";
    constant BFSU     : std_logic_vector(7 downto 0) := "00100100";
    constant WUDADATA : std_logic_vector(7 downto 0) := "00110010";
    constant SETTXRTS : std_logic_vector(7 downto 0) := "11010100";

    -- Addresses
    constant EUDASTL   : std_logic_vector(7 downto 0) := x"16";
    constant ESTATH    : std_logic_vector(7 downto 0) := x"1b";
    constant ECON1L    : std_logic_vector(7 downto 0) := x"1e";
    constant ECON2L    : std_logic_vector(7 downto 0) := x"6e";
    constant ECON2H    : std_logic_vector(7 downto 0) := x"6f";
    constant ETXSTL    : std_logic_vector(7 downto 0) := x"00";
    constant ETXWIREL  : std_logic_vector(7 downto 0) := x"14";
    constant MACON2L   : std_logic_vector(7 downto 0) := x"42";
    constant MAMXFLL   : std_logic_vector(7 downto 0) := x"4a";
    constant EIEL      : std_logic_vector(7 downto 0) := x"72";
    constant EIEH      : std_logic_vector(7 downto 0) := x"73";
    constant EUDAWRPTL : std_logic_vector(7 downto 0) := x"90";

    -- Masks
    constant TXCRCEN  : std_logic_vector(7 downto 0) := "00010000"; -- MACON2L
    constant PADCFG   : std_logic_vector(7 downto 0) := "11100000"; -- MACON2L
    constant CLKRDY   : std_logic_vector(7 downto 0) := "00010000"; -- ESTATH
    constant ETHRST   : std_logic_vector(7 downto 0) := "00010000"; -- ECON2L
    constant RXEN     : std_logic_vector(7 downto 0) := "00000001"; -- ECON1L
    constant TXMAC    : std_logic_vector(7 downto 0) := "00100000"; -- ECON2H
    constant TXIE     : std_logic_vector(7 downto 0) := "00001000"; -- EIEL
    constant TXABTIE  : std_logic_vector(7 downto 0) := "00000100"; -- EIEL
    constant INTIE    : std_logic_vector(7 downto 0) := "10000000"; -- EIEH

    -- Default control register values
    constant MACON2L_d : std_logic_vector(7 downto 0) := x"b2";
begin
    
    process (clk, rst)
        variable tmp : std_logic_vector(15 downto 0);
    begin
        if rst = '0' then
            -- reset
            status_debug <= "00";
            status_error <= '0';
            status_stage <= "0000";
            control_state <= init0;
            wr_data <= (others => '0');
            wr_valid <= '0';
            rd_stop <= '1';
            i <= 0;
            j <= 0;
            buf <= (others => '0');
            busy <= '1';
            bram_ena <= '0';
            bram_addr <= "00000000000";
            bram_wrena <= '0';
            bram_wrdata <= x"00";
        elsif rising_edge(clk) then
            case control_state is
                when init0 =>
                    wr_valid <= '1';
                    wr_data <= WCRU;
                    control_state <= init1;
                when init1 =>
                    if wr_got_byte = '1' then
                        wr_data <= EUDASTL;
                        control_state <= init2;
                    end if;
                when init2 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"12"; 
                        control_state <= init3;
                    end if;
                when init3 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"34"; 
                        control_state <= init4;
                    end if;
                when init4 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init5;
                    end if;
                when init5 =>
                    if wr_done = '1' then
                        control_state <= init6;
                    end if;
                when init6 =>
                    wr_valid <= '1';
                    wr_data <= RCRU;
                    control_state <= init7;
                when init7 =>
                    if wr_got_byte = '1' then
                        wr_data <= EUDASTL;
                        control_state <= init8;
                    end if;
                when init8 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init9;
                    end if;
                when init9 =>
                    rd_stop <= '0';
                    if rd_valid = '1' then
                        buf(7 downto 0) <= rd_data;
                        control_state <= init10;
                    end if;
                when init10 =>
                    if rd_valid = '1' then
                        buf(15 downto 8) <= rd_data;
                        control_state <= init11;
                        rd_stop <= '1';
                    end if;
                when init11 =>
                    if buf /= x"3412" then
                        status_error <= '1';
                        control_state <= init0;
                    else 
                        control_state <= init12;
                    end if;

                when init12 =>
                    wr_valid <= '1';
                    wr_data <= RCRU;
                    control_state <= init13;
                when init13 =>
                    if wr_got_byte = '1' then
                        wr_data <= ESTATH;
                        control_state <= init14;
                    end if;
                when init14 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init15;
                        rd_stop <= '0';
                    end if;
                when init15 =>
                    if rd_valid = '1' then
                        buf(7 downto 0) <= rd_data;
                        control_state <= init16;
                        rd_stop <= '1';
                    end if;
                when init16 =>
                    if rd_data(4) = '1' then
                        status_error <= '0';
                        control_state <= init17;
                    else
                        status_error <= '1';
                        control_state <= init12;
                    end if;

                when init17 =>
                    wr_valid <= '1';
                    wr_data <= BFSU;
                    control_state <= init18;
                when init18 =>
                    if wr_got_byte = '1' then
                        wr_data <= ECON2L;
                        control_state <= init19;
                    end if;
                when init19 =>
                    if wr_got_byte = '1' then
                        wr_data <= ETHRST;
                        control_state <= init20;
                    end if;
                when init20 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init21;
                    end if;
                when init21 =>
                    if wr_done = '1' then
                        control_state <= init22;
                        i <= 250;
                    end if;

                when init22 =>
                    i <= i - 1;
                    if i = 0 then
                        control_state <= init23;
                    end if;

                when init23 =>
                    wr_valid <= '1';
                    wr_data <= RCRU;
                    control_state <= init24;
                when init24 =>
                    if wr_got_byte = '1' then
                        wr_data <= EUDASTL;
                        control_state <= init25;
                    end if;
                when init25 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init26;
                    end if;
                when init26 =>
                    rd_stop <= '0';
                    if rd_valid = '1' then
                        buf(7 downto 0) <= rd_data;
                        control_state <= init27;
                    end if;
                when init27 =>
                    if rd_valid = '1' then
                        buf(15 downto 8) <= rd_data;
                        control_state <= init28;
                        rd_stop <= '1';
                    end if;
                when init28 =>
                    if buf = x"0000" then
                        status_error <= '0';
                        i <= 2560;
                        control_state <= init23;
                    else
                        status_error <= '1';
                        control_state <= init29;
                    end if;
                when init29 =>
                    i <= i - 1;
                    if i = 0 then
                        control_state <= init30;
                    end if;

                when init30 =>
                    wr_valid <= '1';
                    wr_data <= RCRU;
                    control_state <= init31;
                when init31 =>
                    if wr_got_byte = '1' then
                        wr_data <= MACON2L;
                        control_state <= init32;
                    end if;
                when init32 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        rd_stop <= '0';
                        control_state <= init33;
                    end if;
                when init33 =>
                    if rd_valid = '1' then
                        buf(7 downto 0) <= rd_data;
                        rd_stop <= '1';
                        control_state <= init34;
                    end if;
                when init34 =>
                    if buf(7 downto 0) = MACON2L_d then
                        control_state <= init35;
                    else
                        status_error <= '1';
                        control_state <= init30;
                    end if;

                when init35 =>
                    wr_valid <= '1';
                    wr_data <= WCRU;
                    control_state <= init36;
                when init36 =>
                    if wr_got_byte = '1' then
                        wr_data <= MAMXFLL;
                        control_state <= init37;
                    end if;
                when init37 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"dc";
                        control_state <= init38;
                    end if;
                when init38 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"05";
                        control_state <= init39;
                    end if;
                when init39 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= init40;
                    end if;
                when init40 =>
                    if wr_done = '1' then
                        control_state <= tx0;
                        i <= 90;
                    end if;

                when ctrl_idle =>
                    if tx = '1' then
                        i <= to_integer(unsigned(tx_len));
                        busy <= '1';
                        control_state <= tx0;
                    end if;
                
                when tx0 =>
                    wr_valid <= '1';
                    wr_data <= WCRU;
                    control_state <= tx1;
                when tx1 =>
                    if wr_got_byte = '1' then
                        wr_data <= ETXSTL;
                        control_state <= tx2;
                    end if;
                when tx2 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"00"; -- ETXSTL = 0
                        control_state <= tx3;
                    end if;
                when tx3 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"00"; -- ETXSTH = 0
                        control_state <= tx4;
                    end if;
                when tx4 =>
                    if wr_got_byte = '1' then
                        tmp := std_logic_vector(to_unsigned(i, 16));
                        wr_data <= tmp(7 downto 0); -- ETXLENL
                        control_state <= tx5;
                    end if;
                when tx5 =>
                    if wr_got_byte = '1' then 
                        wr_data <= tmp(15 downto 8); -- ETXLENH = 0
                        control_state <= tx6;
                    end if;
                when tx6 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= tx7;
                    end if;
                when tx7 =>
                    if wr_done = '1' then
                        control_state <= tx8;
                    end if;

                when tx8 =>
                    wr_valid <= '1';
                    wr_data <= WCRU;
                    control_state <= tx9;
                    bram_ena <= '1';
                    bram_addr <= "00000000000";
                when tx9 => 
                    if wr_got_byte = '1' then
                        wr_data <= EUDAWRPTL;
                        control_state <= tx10;
                    end if;
                when tx10 =>
                    if wr_got_byte = '1' then
                        status_stage <= bram_rddata(3 downto 0);
                        bram_ena <= '0';
                        wr_data <= x"00"; -- EUDAWRPTL = 00
                        control_state <= tx11;
                    end if;
                when tx11 =>
                    if wr_got_byte = '1' then
                        wr_data <= x"00"; -- EUDAWRPTL = 00
                        control_state <= tx12;
                    end if;
                when tx12 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= tx13;
                    end if;
                when tx13 =>
                    if wr_done = '1' then
                        control_state <= tx14;
                        j <= 0;
                    end if;

                when tx14 =>
                    wr_valid <= '1';
                    wr_data <= WUDADATA;
                    control_state <= tx15;
                    bram_ena <= '1';
                    bram_addr <= std_logic_vector(to_unsigned(j, 11));
                
                when tx15 => 
                    if wr_got_byte = '1' then
                        wr_data <= bram_rddata;
                        if j = i-1 then
                            control_state <= tx16;
                        end if;
                        j <= j + 1;
                        bram_addr <= std_logic_vector(to_unsigned(j + 1, 11));
                    end if;
                when tx16 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= tx17;
                        bram_ena <= '0';
                    end if;
                when tx17 =>
                    if wr_done = '1' then
                        control_state <= tx18;
                    end if;

                when tx18 => -- Start the transaction
                    wr_valid <= '1';
                    wr_data <= SETTXRTS;
                    control_state <= tx19;
                when tx19 =>
                    if wr_got_byte = '1' then
                        wr_valid <= '0';
                        control_state <= tx20;
                    end if;
                when tx20 =>
                    if wr_done = '1' then
                        busy <= '0';
                        control_state <= ctrl_idle;
                    end if;
            end case;
        end if;
    end process;
end RTL;