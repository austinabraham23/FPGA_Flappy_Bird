//-------------------------------------------------------------------------
//    mb_usb_hdmi_top.sv                                                 --
//    Zuofu Cheng                                                        --
//    2-29-24                                                            --
//                                                                       --
//                                                                       --
//    Spring 2024 Distribution                                           --
//                                                                       --
//    For use with ECE 385 USB + HDMI                                    --
//    University of Illinois ECE Department                              --
//-------------------------------------------------------------------------


module mb_usb_hdmi_top(
    input logic Clk,
    input logic reset_rtl_0,
    
    //USB signals
    input logic [0:0] gpio_usb_int_tri_i,
    output logic gpio_usb_rst_tri_o,
    input logic usb_spi_miso,
    output logic usb_spi_mosi,
    output logic usb_spi_sclk,
    output logic usb_spi_ss,
    
    //UART
    input logic uart_rtl_0_rxd,
    output logic uart_rtl_0_txd,
    
    //HDMI
    output logic hdmi_tmds_clk_n,
    output logic hdmi_tmds_clk_p,
    output logic [2:0]hdmi_tmds_data_n,
    output logic [2:0]hdmi_tmds_data_p,
        
    //HEX displays
    output logic [7:0] hex_segA,
    output logic [3:0] hex_gridA,
    output logic [7:0] hex_segB,
    output logic [3:0] hex_gridB,
    
    // on board test
    input logic BTN2,
    input logic BTN3,
    input logic BTN4,
    
    // switches
    input logic [15:0] SW,
    
    // audio
    output logic SPKL,
    output logic SPKR
);
    
    logic [31:0] keycode0_gpio, keycode1_gpio;
    logic clk_25MHz, clk_125MHz, clk, clk_100MHz;
    logic locked;
    logic [9:0] drawX, drawY, ballxsig, ballysig, ballsizesig; 
    logic [9:0] pipex1sig, pipex2sig, pipex3sig, pipex4sig, pipex5sig; 
    logic [9:0] pipey1sig, pipey2sig, pipey3sig, pipey4sig, pipey5sig;
    logic [9:0] pipe_offset1, pipe_offset2, pipe_offset3, pipe_offset4;

    logic hsync, vsync, vde;
    logic [3:0] red, green, blue;
    logic reset_ah;
    logic [15:0] counter_score;
    logic game_start;
    logic [15:0] level;
    
    logic [2:0] bird_volume;
    
    parameter [7:0] UP_KEYCODE_1 = 8'h1A; // Keycode for "W"
    parameter [7:0] UP_KEYCODE_2 = 8'h52; // Keycode for "Up Arrow"
    
    assign reset_ah = reset_rtl_0;
    
    logic [15:0] pacmanAudio [0:34];
    initial begin
        pacmanAudio[0]  = 568;
        pacmanAudio[1]  = 536;
        pacmanAudio[2]  = 1080;
        pacmanAudio[3]  = 808;
        pacmanAudio[4]  = 672;
        pacmanAudio[5]  = 1072;
        pacmanAudio[6]  = 800;
        pacmanAudio[7]  = 679;
        pacmanAudio[8]  = 672;
        pacmanAudio[9]  = 568;
        pacmanAudio[10] = 1136;
        pacmanAudio[11] = 856;
        pacmanAudio[12] = 720;
        pacmanAudio[13] = 712;
        pacmanAudio[14] = 848;
        pacmanAudio[15] = 711;
        pacmanAudio[16] = 720;
        pacmanAudio[17] = 216;
        pacmanAudio[18] = 536;
        pacmanAudio[19] = 1072;
        pacmanAudio[20] = 808;
        pacmanAudio[21] = 672;
        pacmanAudio[22] = 1080;
        pacmanAudio[23] = 799;
        pacmanAudio[24] = 680;
        pacmanAudio[25] = 672;
        pacmanAudio[26] = 640;
        pacmanAudio[27] = 720;
        pacmanAudio[28] = 720;
        pacmanAudio[29] = 808;
        pacmanAudio[30] = 800;
        pacmanAudio[31] = 855;
        pacmanAudio[32] = 896;
        pacmanAudio[33] = 1072;
        pacmanAudio[34] = 264;
    end
    
    logic [15:0] audio_freq = 0;
    logic [8:0] counter = 0;           // Index counter for audio
    logic [31:0] clk_counter = 0;      // Clock cycle counter (large enough for 10,000,000)

    always_ff @(posedge Clk or posedge reset_rtl_0) begin
        if (reset_rtl_0) begin
            counter = 0;          // Reset the audio index counter
            clk_counter = 0;      // Reset the clock cycle counter
            audio_freq = pacmanAudio[0];
        end else begin
            if (clk_counter >= (10_000_000) - 1) begin
                clk_counter = 0; // Reset the clock counter
                if (counter > 34) begin
                    counter = 0; // Loop back to the start of the audio array
                end else begin
                    counter = counter + 1; // Increment the audio index counter
                end
                audio_freq = pacmanAudio[counter]; // Update the audio frequency
            end else begin
                clk_counter = clk_counter + 1; // Increment the clock cycle counter
            end
        end
    end

    // constant audio
    pwm_sine_wave PACMAN_AUDIO(
        .clk_100MHz(Clk),  // Input 
        .freq(audio_freq),
        .volume(SW[2:0]),
        .lock(1),
        .SPK(SPKL)       // PWM output for left channel
    );
    
    // bird click audio
    hardware_only_audio BIRD_AUDIO(
        .clk_100MHz(Clk),
        .sw_i(SW),
        .reset_rtl_0(reset_ah),
        .BTN2(BTN2),
        .keycode(keycode0_gpio[7:0]),
        
        .SPKL(SPKL),
        .SPKR(SPKR)
    );
    
    //Keycode HEX drivers
    hex_driver HexA (
        .clk(Clk),
        .reset(reset_ah),
        .in({counter_score[15:12], counter_score[11:8], counter_score[7:4], counter_score[3:0]}),
        .hex_seg(hex_segA),
        .hex_grid(hex_gridA)
    );
    
    hex_driver HexB (
        .clk(Clk),
        .reset(reset_ah),
        //.in({keycode0_gpio[15:12], keycode0_gpio[11:8], keycode0_gpio[7:4], keycode0_gpio[3:0]}),
//        .in({{3'b0, SPKL},{3'b0, SPKR}, {4'b0}, {1'b0, SW[2:0]}}),
        .in({level[7:4], level[3:0], {4'b0}, {2'b0, SW[1:0]}}),
        .hex_seg(hex_segB),
        .hex_grid(hex_gridB)
    );
    
//    mb_usb mb_block_i (
    mb_block mb_block_i (
        .clk_100MHz(Clk),
        .gpio_usb_int_tri_i(gpio_usb_int_tri_i),
        .gpio_usb_keycode_0_tri_o(keycode0_gpio),
        .gpio_usb_keycode_1_tri_o(keycode1_gpio),
        .gpio_usb_rst_tri_o(gpio_usb_rst_tri_o),
        .reset_rtl_0(~reset_ah), //Block designs expect active low reset, all other modules are active high
        .uart_rtl_0_rxd(uart_rtl_0_rxd),
        .uart_rtl_0_txd(uart_rtl_0_txd),
        .usb_spi_miso(usb_spi_miso),
        .usb_spi_mosi(usb_spi_mosi),
        .usb_spi_sclk(usb_spi_sclk),
        .usb_spi_ss(usb_spi_ss)
    );
        
    //clock wizard configured with a 1x and 5x clock for HDMI
    clk_wiz_0 clk_wiz (
        .clk_out1(clk_25MHz),
        .clk_out2(clk_125MHz),
        .reset(reset_ah),
        .locked(locked),
        .clk_in1(Clk)
    );
    
    //VGA Sync signal generator
    vga_controller vga (
        .pixel_clk(clk_25MHz),
        .reset(reset_ah),
        .hs(hsync),
        .vs(vsync),
        .active_nblank(vde),
        .drawX(drawX),
        .drawY(drawY)
    );    

    //Real Digital VGA to HDMI converter
    hdmi_tx_0 vga_to_hdmi (
        //Clocking and Reset
        .pix_clk(clk_25MHz),
        .pix_clkx5(clk_125MHz),
        .pix_clk_locked(locked),
        //Reset is active LOW
        .rst(reset_ah),
        //Color and Sync Signals
        .red(red),
        .green(green),
        .blue(blue),
        .hsync(hsync),
        .vsync(vsync),
        .vde(vde),
        
        //aux Data (unused)
        .aux0_din(4'b0),
        .aux1_din(4'b0),
        .aux2_din(4'b0),
        .ade(1'b0),
        
        //Differential outputs
        .TMDS_CLK_P(hdmi_tmds_clk_p),          
        .TMDS_CLK_N(hdmi_tmds_clk_n),          
        .TMDS_DATA_P(hdmi_tmds_data_p),         
        .TMDS_DATA_N(hdmi_tmds_data_n)          
    );

    
    //Ball Module
    ball ball_instance(
        .Reset(reset_ah),
        .frame_clk(vsync),                    //Figure out what this should be so that the ball will move
        .keycode(keycode0_gpio[7:0]),    //Notice: only one keycode connected to ball by default
        .BTN2(BTN2),
        .BTN3(BTN3),
        .pipe_offset1(pipe_offset1), 
        .pipe_offset2(pipe_offset2), 
        .pipe_offset3(pipe_offset3), 
        .pipe_offset4(pipe_offset4),
        
        .BallX(ballxsig),
        .BallY(ballysig),
        .BallS(ballsizesig),
        .PipeX1(pipex1sig),
        .PipeY1(pipey1sig),
        .PipeX2(pipex2sig),
        .PipeY2(pipey2sig),
        .PipeX3(pipex3sig),
        .PipeY3(pipey3sig),
        .PipeX4(pipex4sig),
        .PipeY4(pipey4sig),
        .counter(counter_score),
        .game_start(game_start),
        .level(level)
    );

   // Color Mapper
    color_mapper color_instance(
        .BallX(ballxsig),
        .BallY(ballysig),
        .DrawX(drawX),
        .DrawY(drawY),
        .PipeX1(pipex1sig),
        .PipeY1(pipey1sig),
        .PipeX2(pipex2sig),
        .PipeY2(pipey2sig),
        .PipeX3(pipex3sig),
        .PipeY3(pipey3sig),
        .PipeX4(pipex4sig),
        .PipeY4(pipey4sig),
        .keycode(keycode0_gpio[7:0]),
        .BTN2(BTN2),
        .vga_clk(clk_25MHz),
        .blank(vsync),
        .Reset(reset_ah),
        .game_start(game_start),
        
        .Red(red),
        .Green(green),
        .Blue(blue),
        .pipe_offset1(pipe_offset1), 
        .pipe_offset2(pipe_offset2), 
        .pipe_offset3(pipe_offset3), 
        .pipe_offset4(pipe_offset4)
    );
   
endmodule
