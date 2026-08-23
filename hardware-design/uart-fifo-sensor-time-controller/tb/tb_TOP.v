`timescale 1ns / 1ps
module tb_top ();
    parameter button_debounce = (1000_000_000 / 1000) * 8;
    parameter bps9600 = 1000_000_000 / 9600;


    parameter 
        ascii_d=8'h44  ,ascii_l=8'h4C ,ascii_m=8'h4D 
        ,ascii_r=8'h52 ,ascii_s=8'h53 ,ascii_u=8'h55 
        ,ascii_D=8'h64 ,ascii_L=8'h6C ,ascii_M=8'h6D 
        ,ascii_R=8'h72 ,ascii_S=8'h73 ,ascii_U=8'h75;

    reg        clk;
    reg        rst;
    reg        btnR;
    reg        btnL;
    reg        btnU;
    reg        btnD;
    reg        echo;
    reg        rx;
    reg        trig_0;
    reg  [3:0] sw;
    wire       tx;
    wire       trig;

    wire [3:0] fnd_com;
    wire [7:0] fnd_data;
    wire [8:0] led;
    wire       dht11;
    integer i, j;
    reg io_oe;
    reg dht_sensor_data;

    reg test_button;
    reg test_uart_rx;
    reg [39:0] DATA_STREAM;
    reg [7:0] ascii;

    TOP u_top (
        .clk     (clk),
        .rst     (rst),
        .btnR    (btnR),
        .btnL    (btnL),
        .btnU    (btnU),
        .btnD    (btnD),
        .echo    (echo),
        .rx      (rx),
        .sw      (sw),
        .tx      (tx),

        .fnd_com (fnd_com),
        .fnd_data(fnd_data),
        .led     (led),
        .trig    (trig),
        .dht11   (dht11)
    );
    // DHT11의 단일 DATA 선을 센서 모델과 DUT가 번갈아 구동하도록 구성한다.
    assign dht11 = (io_oe) ? dht_sensor_data : 1'bz;
    
    always begin#5;clk = ~clk;end
    
    initial begin
        clk = 0;
        test_button = 0;
        test_uart_rx = 0;

        sw = 0;
        btnR = 0;
        btnL = 0;
        btnU = 0;
        btnD = 0;
        rx = 0;
        io_oe = 0;
        dht_sensor_data = 0;
        rst = 1;
        #10;
        rst = 0;
        #10;

        // 실행할 통합 시나리오 태스크를 선택한다.
        test_button = 0; test_uart_rx = 1;  uart_rx;  


        test_button  = 0;
        test_uart_rx = 0;
        repeat (20) @(negedge clk);
        $finish;
    end
    
    task button_DHT11;
        begin
            DATA_STREAM = {8'h50, 8'h00, 8'h25, 8'h00, 8'h50 + 8'h25};
            repeat (2) @(negedge clk);
            sw[3:2] = 2'b11;
            {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
            #(button_debounce);
            {btnR, btnL, btnU, btnD} = 4'b0000 >> 0;
            #100;
            DHT11;
            
        end
    endtask


    // 40 bit 온습도 데이터와 Checksum을 DHT11 타이밍에 맞춰 응답한다.
    task DHT11;
        begin
            wait (!dht11);

            wait (dht11);
            #31680;
            io_oe = 1;
            i = 0;
            dht_sensor_data = 1'b0;
            #80000;
            dht_sensor_data = 1'b1;
            #80000;
            for (i = 40; i >= 1; i = i - 1) begin
                dht_sensor_data = 1'b0;
                #50000;
                dht_sensor_data = 1'b1;
                #(DATA_STREAM[i-1] ? 70000 : 26000);
            end

            dht_sensor_data = 0;
            #50000;
            io_oe = 0;
            #10000;

            ascii = ascii_s;
            repeat (2) @(negedge clk);
            rx = 0;
            #(bps9600);
            for (j = 0; j < 8; j = j + 1) begin
                rx = ascii[j];
                #(bps9600);
            end
            rx = 1;
            

            #(bps9600 * 11 * 20);

            $stop;
        end
    endtask

    task uart_DHT11;
        begin
            DATA_STREAM = {8'h50, 8'h00, 8'h25, 8'h00, 8'h50 + 8'h25};
            repeat (2) @(negedge clk);
            sw[3:2] = 2'b11;
            ascii   = ascii_r;
            repeat (2) @(negedge clk);
            rx = 0;
            #(bps9600);
            for (j = 0; j < 8; j = j + 1) begin
                rx = ascii[j];
                #(bps9600);
            end
            rx = 1;
            #(bps9600);
            repeat (2) @(negedge clk);
            #100;
            DHT11;
        end
    endtask


    // 선택 모드에 따라 해당 기능의 제어 신호만 활성화되는지 확인한다.
    always @(posedge clk) begin
        if (sw[3:2] == 2'b10 && test_button) begin
            if (u_top.U_SR04_DATAPATH.btnR)
                $display("[%t][SR04][PASS] SR04 / w_btnR ON", $time);
            if (u_top.U_DHT11_DATAPATH.dht11_start)
                $display("[%t][SR04][ERRO] DT11 / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_runstop)
                $display("[%t][SR04][ERRO] STOP / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_clear)
                $display("[%t][SR04][ERRO] STOP / w_btnL ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_mode)
                $display("[%t][SR04][ERRO] STOP / w_btnD ON", $time);
        end

        if (sw[3:2] == 2'b11 && test_button) begin
            if (u_top.U_SR04_DATAPATH.btnR)
                $display("[%t][DHT11][ERRO] SR04 / w_btnR ON", $time);
            if (u_top.U_DHT11_DATAPATH.dht11_start)
                $display("[%t][DHT11][PASS] DT11 / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_runstop)
                $display("[%t][DHT11][ERRO] STOP / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_clear)
                $display("[%t][DHT11][ERRO] STOP / w_btnL ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_mode)
                $display("[%t][DHT11][ERRO] STOP / w_btnD ON", $time);
        end

        if (sw[3:2] == 2'b01 && test_button) begin
            if (u_top.U_SR04_DATAPATH.btnR)
                $display("[%t][SW][ERRO] SR04 / w_btnR ON", $time);
            if (u_top.U_DHT11_DATAPATH.dht11_start)
                $display("[%t][SW][ERRO] DT11 / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_runstop)
                $display("[%t][SW][PASS] STOP / w_btnR ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_clear)
                $display("[%t][SW][PASS] STOP / w_btnL ON", $time);
            if (u_top.U_STOPWATCH_DATAPATH.i_mode)
                $display("[%t][SW][PASS] STOP / w_btnD ON", $time);
        end
    end

    always @(posedge clk) begin
        if (u_top.UART_RX.rx_done) begin
            if (u_top.UART_RX.rx_data === ascii_u)
                $display("[%t][UARX] DATA / [KEY u]", $time);
            if (u_top.UART_RX.rx_data === ascii_d)
                $display("[%t][UARX] DATA / [KEY d]", $time);
            if (u_top.UART_RX.rx_data === ascii_l)
                $display("[%t][UARX] DATA / [KEY l]", $time);
            if (u_top.UART_RX.rx_data === ascii_r)
                $display("[%t][UARX] DATA / [KEY r]", $time);
            if (u_top.UART_RX.rx_data === ascii_s)
                $display("[%t][UARX] DATA / [KEY s]", $time);
            if (u_top.UART_RX.rx_data === ascii_m)
                $display("[%t][UARX] DATA / [KEY m]", $time);
            if (u_top.UART_RX.rx_data === ascii_U)
                $display("[%t][UARX] DATA / [KEY U]", $time);
            if (u_top.UART_RX.rx_data === ascii_D)
                $display("[%t][UARX] DATA / [KEY D]", $time);
            if (u_top.UART_RX.rx_data === ascii_L)
                $display("[%t][UARX] DATA / [KEY L]", $time);
            if (u_top.UART_RX.rx_data === ascii_R)
                $display("[%t][UARX] DATA / [KEY R]", $time);
            if (u_top.UART_RX.rx_data === ascii_S)
                $display("[%t][UARX] DATA / [KEY S]", $time);
            if (u_top.UART_RX.rx_data === ascii_M)
                $display("[%t][UARX] DATA / [KEY M]", $time);
        end
    end


    task button;
        begin
            repeat (2) @(negedge clk);
            for (i = 0; i < 4; i = i + 1) begin
                sw[3:2] = i;
                if (i == 0) begin
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b0000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 1;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 2;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 3;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b0000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b0000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                end else if (i == 1) begin
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 1;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 2;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                    {btnR, btnL, btnU, btnD} = 4'b1000 >> 3;
                    #(button_debounce);
                    repeat (2) @(negedge clk);
                end else begin
                    for (j = 0; j < 4; j = j + 1) begin
                        {btnR, btnL, btnU, btnD} = 4'b1000 >> j;
                        #(button_debounce);
                        repeat (2) @(negedge clk);
                    end
                end
            end
        end
    endtask

    task uart_key;
        input [7:0] ascii_in;
        begin
            ascii = ascii_in;
            repeat (2) @(negedge clk);
            #(bps9600);
            for (i = 0; i < 4; i = i + 1) begin
                sw[3:2] = i;
                repeat (2) @(negedge clk);
                rx = 0;
                #(bps9600);
                for (j = 0; j < 8; j = j + 1) begin
                    rx = ascii[j];
                    #(bps9600);
                end
                rx = 1;
                #(bps9600);
                repeat (2) @(negedge clk);
            end
        end
    endtask

    // UART 문자 명령으로 Stopwatch와 Watch의 제어 흐름을 순차적으로 구동한다.
    task uart_rx;
        begin
            uart_key(ascii_d);
            uart_key(ascii_l);
            uart_key(ascii_m);
            uart_key(ascii_r);
            uart_key(ascii_s);
            uart_key(ascii_u);
            uart_key(ascii_D);
            uart_key(ascii_L);
            uart_key(ascii_M);
            uart_key(ascii_R);
            uart_key(ascii_S);
            uart_key(ascii_U);
        end
    endtask

    task button_SR04;
        begin
            repeat (2) @(negedge clk);
            sw[3:2] = 2'b10;
            {btnR, btnL, btnU, btnD} = 4'b1000 >> 0;
            #(button_debounce);
            {btnR, btnL, btnU, btnD} = 4'b0000 >> 0;
            SR04;


        end
    endtask

    

    task uart_SR04;
        begin
            repeat (2) @(negedge clk);
            sw[3:2] = 2'b10;
            ascii   = ascii_r;
            repeat (2) @(negedge clk);
            rx = 0;
            #(bps9600);
            for (j = 0; j < 8; j = j + 1) begin
                rx = ascii[j];
                #(bps9600);
            end
            rx = 1;
            SR04;
            repeat (2) @(negedge clk);
            ascii = ascii_s;
            repeat (2) @(negedge clk);
            rx = 0;
            #(bps9600);
            for (j = 0; j < 8; j = j + 1) begin
                rx = ascii[j];
                #(bps9600);
            end
            #(bps9600 * 11 * 16);
        end
    endtask

    task SR04;
        begin
            @(posedge trig);
            trig_0 = 1;
            @(negedge trig);
            #1_000;
            echo = 1;
            @(negedge clk);
            #(1_000 * 58 * 10);
            echo = 0;
        end
    endtask


endmodule
