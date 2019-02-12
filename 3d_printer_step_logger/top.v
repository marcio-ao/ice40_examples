/* Top level module for 3D printer step logger */
module top (
    // input hardware clock (12 MHz)
    hwclk,
    // all LEDs
    led1,
    led2,
    led3,
    led4,
    led5,
    // UART lines
    ftdi_tx,
    // Stepper input
    step_x,
    step_y,
    step_z,
    step_e,
    dir_x,
    dir_y,
    dir_z,
    dir_e
    );

    /* Clock input */
    input hwclk;

    /* LED outputs */
    output led1;
    output led2;
    output led3;
    output led4;
    output led5;

    /* FTDI I/O */
    output ftdi_tx;

    /* stepper input */
    input step_x;
    input step_y;
    input step_z;
    input step_e;
    input dir_x;
    input dir_y;
    input dir_z;
    input dir_e;

    /* 9600 Hz clock generation (from 12 MHz) */
    reg clk_9600 = 0;
    reg [31:0] cntr_9600 = 32'b0;
    parameter period_9600 = 625;

    /* 1 Hz clock generation (from 12 MHz) */
    reg clk_1 = 0;
    reg [31:0] cntr_1 = 32'b0;
    parameter period_1 = 6000000;

    // Note: could also use "0" or "9" below, but I wanted to
    // be clear about what the actual binary value is.
    parameter ASCII_0  = 8'd48;
    parameter ASCII_9  = 8'd57;
    parameter ASCII_A  = 8'd65;
    parameter ASCII_LF = 8'd10;

    /* UART registers */
    reg [7:0] uart_txbyte = ASCII_0;
    reg uart_send = 1'b1;
    wire uart_txed;

    /* LED register */
    reg ledval = 0;

    /* UART transmitter module designed for
       8 bits, no parity, 1 stop bit.
    */
    uart_tx_8n1 transmitter (
        // 9600 baud rate clock
        .clk (clk_9600),
        // byte to be transmitted
        .txbyte (uart_txbyte),
        // trigger a UART transmit on baud clock
        .senddata (uart_send),
        // input: tx is finished
        .txdone (uart_txed),
        // output UART tx pin
        .tx (ftdi_tx),
    );

    /* Low speed clock generation */
    always @ (posedge hwclk) begin
        /* generate 9600 Hz clock */
        cntr_9600 <= cntr_9600 + 1;
        if (cntr_9600 == period_9600) begin
            clk_9600 <= ~clk_9600;
            cntr_9600 <= 32'b0;
        end

        /* generate 1 Hz clock */
        cntr_1 <= cntr_1 + 1;
        if (cntr_1 == period_1) begin
            clk_1 <= ~clk_1;
            cntr_1 <= 32'b0;
        end
    end

    /* Wiring */
    assign led1=dir_x;
    assign led2=dir_y;
    assign led3=dir_z;
    assign led4=dir_e;
    assign led5=clk_1;

    parameter x_nibbles = 4;
    parameter y_nibbles = 4;
    parameter z_nibbles = 5;
    parameter e_nibbles = 5;

    parameter total_nibbles = x_nibbles + y_nibbles + z_nibbles + e_nibbles;
    parameter total_bits    = total_nibbles * 4;

    /* Pulse counter */
    reg [x_nibbles*4-1:0] x_pos;
    reg [y_nibbles*4-1:0] y_pos;
    reg [z_nibbles*4-1:0] z_pos;
    reg [e_nibbles*4-1:0] e_pos;

    wire pedge_step_x;
    wire pedge_step_y;
    wire pedge_step_z;
    wire pedge_step_e;

    reg step_x_latch, dir_x_latch;
    reg step_y_latch, dir_y_latch;
    reg step_z_latch, dir_z_latch;
    reg step_e_latch, dir_e_latch;

    /* Positive edge detectors */
    pos_edge_det pe_det_x (.sig(step_x_latch), .clk(hwclk), .pe(pedge_step_x));
    pos_edge_det pe_det_y (.sig(step_y_latch), .clk(hwclk), .pe(pedge_step_y));
    pos_edge_det pe_det_z (.sig(step_z_latch), .clk(hwclk), .pe(pedge_step_z));
    pos_edge_det pe_det_e (.sig(step_e_latch), .clk(hwclk), .pe(pedge_step_e));

    always @ (posedge hwclk) begin
        step_x_latch <= step_x;
        step_y_latch <= step_y;
        step_z_latch <= step_z;
        step_e_latch <= step_e;
        dir_x_latch  <= dir_x;
        dir_y_latch  <= dir_y;
        dir_z_latch  <= dir_z;
        dir_e_latch  <= dir_e;

        if(pedge_step_x)
        begin
           if(dir_x_latch)
                x_pos <= x_pos + 1;
           else
                x_pos <= x_pos - 1;
        end

        if(pedge_step_y)
        begin
            if(dir_y_latch)
                y_pos <= y_pos + 1;
            else
                y_pos <= y_pos - 1;
        end

        if(pedge_step_z)
        begin
            if(dir_z_latch)
                z_pos <= z_pos + 1;
            else
                z_pos <= z_pos - 1;
        end

        if(pedge_step_e)
        begin
            if(e_dir_latch)
                e_pos <= e_pos + 1;
            else
                e_pos <= e_pos - 1;
        end
    end

    /* Output as hexadecimal */

    reg [total_bits-1:0] hex_output;
    reg [$clog2(total_nibbles):0] char_index;

    always @ (posedge clk_9600 ) begin
        if(uart_txed) begin
            char_index <= char_index + 1;
            ledval <= ~ledval;

            /* Print the contents of pulse_counter in hexadecimal */

            if(char_index == total_nibbles)
            begin
                uart_txbyte <= ASCII_LF;
                char_index  <= 0;
                hex_output  <= {x_pos, y_pos, z_pos, e_pos};
            end
            else
            begin
                char_index  <= char_index + 1;
                hex_output  <= hex_output << 4;
                case(hex_output[total_bits-1:total_bits-5])
                    4'h0: uart_txbyte <= ASCII_0 + 0;
                    4'h1: uart_txbyte <= ASCII_0 + 1;
                    4'h2: uart_txbyte <= ASCII_0 + 2;
                    4'h3: uart_txbyte <= ASCII_0 + 3;
                    4'h4: uart_txbyte <= ASCII_0 + 4;
                    4'h5: uart_txbyte <= ASCII_0 + 5;
                    4'h6: uart_txbyte <= ASCII_0 + 6;
                    4'h7: uart_txbyte <= ASCII_0 + 7;
                    4'h8: uart_txbyte <= ASCII_0 + 8;
                    4'h9: uart_txbyte <= ASCII_0 + 9;
                    4'hA: uart_txbyte <= ASCII_A + 0;
                    4'hB: uart_txbyte <= ASCII_A + 1;
                    4'hC: uart_txbyte <= ASCII_A + 2;
                    4'hD: uart_txbyte <= ASCII_A + 3;
                    4'hE: uart_txbyte <= ASCII_A + 4;
                    4'hF: uart_txbyte <= ASCII_A + 5;
                endcase
            end
        end
    end

endmodule