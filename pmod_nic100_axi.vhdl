library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Pmod_NIC100_AXI is 
    generic (
		C_S_AXI_DATA_WIDTH : integer := 32;
		C_S_AXI_ADDR_WIDTH : integer := 4
	);
    port(
        pmod_mosi : out std_logic;    
        pmod_miso : in std_logic;    
        pmod_ss   : out std_logic;
        pmod_sck  : out std_logic;

        status_debug : out std_logic_vector(1 downto 0);
        status_error : out std_logic;
        status_stage : out std_logic_vector(3 downto 0);

        bram_ena    : in std_logic;
        bram_addr   : in std_logic_vector(10 downto 0);
        bram_wrena  : in std_logic;
        bram_wrdata : in std_logic_vector(7 downto 0);
        bram_rddata : out std_logic_vector(7 downto 0);

        S_AXI_ACLK      : in std_logic;
		S_AXI_ARESETN   : in std_logic;
		S_AXI_AWADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_AWPROT    : in std_logic_vector(2 downto 0);
		S_AXI_AWVALID   : in std_logic;
		S_AXI_AWREADY   : out std_logic;
		S_AXI_WDATA     : in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_WSTRB     : in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		S_AXI_WVALID    : in std_logic;
		S_AXI_WREADY    : out std_logic;
		S_AXI_BRESP     : out std_logic_vector(1 downto 0);
		S_AXI_BVALID    : out std_logic;
		S_AXI_BREADY    : in std_logic;
		S_AXI_ARADDR    : in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		S_AXI_ARPROT    : in std_logic_vector(2 downto 0);
		S_AXI_ARVALID   : in std_logic;
		S_AXI_ARREADY   : out std_logic;
		S_AXI_RDATA     : out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		S_AXI_RRESP     : out std_logic_vector(1 downto 0);
		S_AXI_RVALID    : out std_logic;
		S_AXI_RREADY    : in std_logic
    );
end Pmod_NIC100_AXI;

architecture RTL of Pmod_NIC100_AXI is
    signal busy   : std_logic;
    signal tx     : std_logic;
    signal tx_len : std_logic_vector(10 downto 0);
    signal rx     : std_logic;
begin
    axi_interface : entity work.axi_interface
    generic map (
		C_S_AXI_DATA_WIDTH	=> C_S_AXI_DATA_WIDTH,
		C_S_AXI_ADDR_WIDTH	=> C_S_AXI_ADDR_WIDTH
	)
	port map (
        busy   => busy,
        tx     => tx,
        tx_len => tx_len,
        rx     => rx,

		S_AXI_ACLK      => S_AXI_ACLK,
		S_AXI_ARESETN   => S_AXI_ARESETN,
		S_AXI_AWADDR    => S_AXI_AWADDR,
		S_AXI_AWPROT    => S_AXI_AWPROT,
		S_AXI_AWVALID   => S_AXI_AWVALID,
		S_AXI_AWREADY   => S_AXI_AWREADY,
		S_AXI_WDATA     => S_AXI_WDATA,
		S_AXI_WSTRB     => S_AXI_WSTRB,
		S_AXI_WVALID    => S_AXI_WVALID,
		S_AXI_WREADY    => S_AXI_WREADY,
		S_AXI_BRESP     => S_AXI_BRESP,
		S_AXI_BVALID    => S_AXI_BVALID,
		S_AXI_BREADY    => S_AXI_BREADY,
		S_AXI_ARADDR    => S_AXI_ARADDR,
		S_AXI_ARPROT    => S_AXI_ARPROT,
		S_AXI_ARVALID   => S_AXI_ARVALID,
		S_AXI_ARREADY   => S_AXI_ARREADY,
		S_AXI_RDATA     => S_AXI_RDATA,
		S_AXI_RRESP     => S_AXI_RRESP,
		S_AXI_RVALID    => S_AXI_RVALID,
		S_AXI_RREADY    => S_AXI_RREADY
    );

    pmod_nic100 : entity work.pmod_nic100
    port map (
        pmod_mosi => pmod_mosi,
        pmod_miso => pmod_miso,
        pmod_ss   => pmod_ss,
        pmod_sck  => pmod_sck,

        status_debug => status_debug,
        status_error => status_error,
        status_stage => status_stage,

        bram_ena    => bram_ena,
        bram_addr   => bram_addr,
        bram_wrena  => bram_wrena,
        bram_wrdata => bram_wrdata,
        bram_rddata => bram_rddata,

        busy   => busy,
        tx     => tx,
        tx_len => tx_len,
        rx     => rx,

        clk => S_AXI_ACLK,
        rst => S_AXI_ARESETN
    );
end RTL;