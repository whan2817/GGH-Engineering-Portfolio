`define bps #(1_000_000_000 / 9600);
`define bps16 ( 100_000_000 / 9600);
logic [15: 0] iocr=0;
int tx_cnt = `bps16;
bit [7:0]i_ascii = 8'd0;
int loop;
logic [15:0]prev_io_port;
int pass_num,fail_num,total_num,read_num, write_num, io_num;

string mode_sel;

typedef enum {
		TEST_START = 0, TEST_END=1,  
		RESET =2, WRITE=3, READ =4, ALL=5,IO=6
}c_mode;

typedef enum {
		NORM=0, UART = 1, SPI=2, I2C =3,AXI=4,GPIO=5
}c_protocol;

