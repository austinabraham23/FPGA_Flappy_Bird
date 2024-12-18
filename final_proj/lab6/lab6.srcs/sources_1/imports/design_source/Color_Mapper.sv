module color_mapper (
    input  logic [9:0] BallX, BallY, DrawX, DrawY,  // Ball position and current pixel being drawn
    input  logic [9:0] PipeX1, PipeX2, PipeX3, PipeX4,
    input  logic [9:0] PipeY1, PipeY2, PipeY3, PipeY4,
    input  logic [7:0] keycode,
    input  logic BTN2,                              // Button input
    input  logic vga_clk,                           // VGA clock for background module
    input  logic blank,                             // Blank signal for background
    input  logic Reset,
    input  logic game_start,
    
    output logic [3:0] Red, Green, Blue,             // RGB output
    output logic [9:0] pipe_offset1, pipe_offset2, pipe_offset3, pipe_offset4                 // Offset for the pipe Y location
);

    logic bird_on, pipe_on; // Flags to check if bird or pipe is being drawn
    logic [2:0] active_pal;        // Active palette (bird or pipe)
    logic [2:0] bird_no_flap_pal;  // Palette value from the no-flap sprite
    logic [2:0] bird_flap_pal;     // Palette value from the flap sprite
    logic [2:0] pipe_pal, pipe_pal_1, pipe_pal_2, pipe_pal_3, pipe_pal_4;          // Palette value from the pipe sprite
    logic [4:0] bird_no_flap_X, bird_flap_X; // Column in the sprite (0-16, reversed for mirroring)
    logic [4:0] pipe_X1, pipe_X2, pipe_X3, pipe_X4;                      // Column in the pipe sprite
    logic [9:0] pipe_Y1, pipe_Y2, pipe_Y3, pipe_Y4;
    logic [9:0] bird_no_flap_Y, bird_flap_Y; // Row in the sprites
    logic [9:0] Width, Height;               // Width and height of the rectangle
    logic [3:0] bg_red, bg_green, bg_blue;   // Background RGB values
    logic [3:0] ss_red, ss_green, ss_blue;
    
    logic [15:0] lfsr; // 16-bit LFSR for randomness
    logic [9:0] random_offset;
    logic update_offsets;
    logic pipe_on1, pipe_on2, pipe_on3, pipe_on4;

    parameter BIRD_WIDTH = 17;               // Bird rectangle width
    parameter BIRD_HEIGHT = 12;              // Bird rectangle height
    parameter PIPE_WIDTH = 26;               // Pipe rectangle width
    parameter PIPE_HEIGHT = 480;             // Pipe rectangle height
    parameter [7:0] UP_KEYCODE_1 = 8'h1A;    // Keycode for "W"
    parameter [7:0] UP_KEYCODE_2 = 8'h52;    // Keycode for "Up Arrow"
    
    // LFSR for random number generation
    always_ff @(posedge vga_clk or posedge Reset) begin
        if (Reset) begin
            lfsr <= 16'hACE1; // Seed value
        end else begin
            lfsr <= {lfsr[14:0], lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};
        end
    end
    
    // Generate a random offset in the range [50, 380]
    assign random_offset = 50 + (lfsr[9:0] % 330);
    
    always_ff @(posedge vga_clk or posedge Reset) begin
        if (Reset) begin
            update_offsets <= 1'b0;
        end else if (PipeX1 <= 0) begin
            update_offsets <= 1'b1; // Set when any pipe resets
        end else begin
            update_offsets <= 1'b0; // Reset after updating offsets
        end
    end
    
    always_ff @(posedge vga_clk or posedge Reset) begin
        if (Reset) begin
            pipe_offset1 = 380;
            pipe_offset2 = 150;
            pipe_offset3 = 200;
            pipe_offset4 = 330;
        end else begin
            if (PipeX1 < 640 && PipeX1 > 0) begin
                pipe_offset1 = pipe_offset1;
            end else begin
                pipe_offset1 = random_offset;
            end
            
            if (PipeX2 < 640 && PipeX2 > 0) begin
                pipe_offset2 = pipe_offset2;
            end else begin
                pipe_offset2 = random_offset;
            end
            
            if (PipeX3 < 640 && PipeX3 > 0) begin
                pipe_offset3 = pipe_offset3;
            end else begin
                pipe_offset3 = random_offset;
            end
            
            if (PipeX4 < 640 && PipeX4 > 0) begin
                pipe_offset4 = pipe_offset4;
            end else begin
                pipe_offset4 = random_offset;
            end
        end        
    end

    // Instantiate the bird no-flap sprite module
    bird_no_flap_sprite NOFLAPBIRD(
        .X(bird_no_flap_X),         // 5 bits for 17 columns (0 to 16, reversed for mirroring)
        .Y(bird_no_flap_Y),         // 4 bits for 12 rows (0 to 11)
        
        .pal(bird_no_flap_pal)      // 3-bit pixel output
    );

    // Instantiate the bird flap sprite module
    bird_flap_sprite FLAPPINGBIRD(
        .X(bird_flap_X),            // 5 bits for 17 columns (0 to 16, reversed for mirroring)
        .Y(bird_flap_Y),            // 4 bits for 12 rows (0 to 11)
        
        .pal(bird_flap_pal)         // 3-bit pixel output
    );

    // Instantiate the pipe sprite module
    pipe_sprite PIPE1(
        .X(pipe_X1),                 // 5 bits for 26 columns (0 to 25)
        .Y(pipe_Y1 + pipe_offset1),   // 10 bits for vertical resolution
        
        .pal(pipe_pal_1)              // 2-bit pixel output
    );
    
    pipe_sprite PIPE2(
        .X(pipe_X2),                 // 5 bits for 26 columns (0 to 25)
        .Y(pipe_Y2 + pipe_offset2),   // 10 bits for vertical resolution
        
        .pal(pipe_pal_2)              // 2-bit pixel output
    );
    
    pipe_sprite PIPE3(
        .X(pipe_X3),                 // 5 bits for 26 columns (0 to 25)
        .Y(pipe_Y3 + pipe_offset3),   // 10 bits for vertical resolution
        
        .pal(pipe_pal_3)              // 2-bit pixel output
    );
    
    pipe_sprite PIPE4(
        .X(pipe_X4),                 // 5 bits for 26 columns (0 to 25)
        .Y(pipe_Y4 + pipe_offset4),   // 10 bits for vertical resolution
        
        .pal(pipe_pal_4)              // 2-bit pixel output
    );

    // Instantiate the background module
    flappy_bird_background_sprite BACKGROUND(
        .vga_clk(vga_clk),
        .DrawX(DrawX),
        .DrawY(DrawY),
        .blank(blank),
        
        .red(bg_red),
        .green(bg_green),
        .blue(bg_blue)
    );
    
    // Instantiate start screen
    start_screen_sprite START_SCREEN(
        .vga_clk(vga_clk),
        .DrawX(DrawX),
        .DrawY(DrawY),
        .blank(blank),
        
        .red(ss_red),
        .green(ss_green),
        .blue(ss_blue)
    );

    // Determine if the current pixel is within the bird or pipe rectangles
    always_comb begin
        Width = BIRD_WIDTH;    // Original width (17 pixels)
        Height = BIRD_HEIGHT;  // Original height (12 pixels)
        
        bird_on = 1'b0;  // Default: bird sprite not active
        if (game_start == 1) begin
            if ((DrawX >= BallX) && (DrawX < BallX + Width) &&
                (DrawY >= BallY) && (DrawY < BallY + Height)) begin
                bird_on = 1'b1;  // Sprite active
            end
        end
        
        pipe_on1 = (DrawX >= PipeX1) && (DrawX < PipeX1 + PIPE_WIDTH) &&
               (DrawY >= PipeY1) && (DrawY < PipeY1 + PIPE_HEIGHT);

        pipe_on2 = (DrawX >= PipeX2) && (DrawX < PipeX2 + PIPE_WIDTH) &&
                   (DrawY >= PipeY2) && (DrawY < PipeY2 + PIPE_HEIGHT);

        pipe_on3 = (DrawX >= PipeX3) && (DrawX < PipeX3 + PIPE_WIDTH) &&
                   (DrawY >= PipeY3) && (DrawY < PipeY3 + PIPE_HEIGHT);
        
        pipe_on4 = (DrawX >= PipeX4) && (DrawX < PipeX4 + PIPE_WIDTH) &&
                   (DrawY >= PipeY4) && (DrawY < PipeY4 + PIPE_HEIGHT);
                           
        pipe_on = pipe_on1 || pipe_on2 || pipe_on3 || pipe_on4;  // Combine the flags
    end

    // Map the screen position to sprite grid coordinates
    always_comb begin
        if (bird_on) begin
            // Map DrawX and DrawY to the bird sprite grid (no scaling)
            bird_no_flap_X = BIRD_WIDTH - 1 - (DrawX - BallX);  // Reverse X for mirroring
            bird_no_flap_Y = (DrawY - BallY);                  // Use unscaled Y

            bird_flap_X = BIRD_WIDTH - 1 - (DrawX - BallX);    // Reverse X for mirroring
            bird_flap_Y = (DrawY - BallY);                    // Use unscaled Y
        end else begin
            bird_no_flap_X = 5'b0;
            bird_no_flap_Y = 4'b0;

            bird_flap_X = 5'b0;
            bird_flap_Y = 4'b0;
        end
        
        if (pipe_on1) begin
            // Map DrawX and DrawY to the pipe sprite grid
            pipe_X1 = (DrawX - PipeX1); // Horizontal position relative to pipe
            pipe_Y1 = (DrawY - PipeY1); // Vertical position relative to pipe
        end else begin
            pipe_X1 = 5'b0;
            pipe_Y1 = 10'b0;
        end
        
        if (pipe_on2) begin
            // Map DrawX and DrawY to the pipe sprite grid
            pipe_X2 = (DrawX - PipeX2); // Horizontal position relative to pipe
            pipe_Y2 = (DrawY - PipeY2); // Vertical position relative to pipe
        end else begin
            pipe_X2 = 5'b0;
            pipe_Y2 = 10'b0;
        end
        
        if (pipe_on3) begin
            // Map DrawX and DrawY to the pipe sprite grid
            pipe_X3 = (DrawX - PipeX3); // Horizontal position relative to pipe
            pipe_Y3 = (DrawY - PipeY3); // Vertical position relative to pipe
        end else begin
            pipe_X3 = 5'b0;
            pipe_Y3 = 10'b0;
        end
        
        if (pipe_on4) begin
            // Map DrawX and DrawY to the pipe sprite grid
            pipe_X4 = (DrawX - PipeX4); // Horizontal position relative to pipe
            pipe_Y4 = (DrawY - PipeY4); // Vertical position relative to pipe
        end else begin
            pipe_X4 = 5'b0;
            pipe_Y4 = 10'b0;
        end
    end

    // Select the active palette based on bird or pipe
    always_comb begin
        if (bird_on) begin
            if (BTN2 || keycode == UP_KEYCODE_1 || keycode == UP_KEYCODE_2) begin
                active_pal = bird_flap_pal;  // Use flap sprite palette when BTN2 == 1
            end else begin
                active_pal = bird_no_flap_pal;  // Use no-flap sprite palette when BTN2 == 0
            end
        end else begin
            active_pal = 3'b000; // Default to transparent
        end
        
        if (pipe_on1) begin
            pipe_pal = pipe_pal_1;
        end else if (pipe_on2) begin
            pipe_pal = pipe_pal_2;
        end else if (pipe_on3) begin
            pipe_pal = pipe_pal_3;
        end else if (pipe_on4) begin
            pipe_pal = pipe_pal_4;
        end else begin
            pipe_pal = 3'b000;  // Default to alpha
        end
    end

    logic [11:0] black  = 12'h000; // Black
    logic [11:0] white  = 12'hFFF; // White
    logic [11:0] red    = 12'hD00; // Red
    logic [11:0] yellow = 12'hDD0; // Yellow
    logic [11:0] orange = 12'hD70; // Orange
    logic [11:0] green  = 12'h0F0; // Green for the pipe

    always_comb begin: RGB_Display
        if (bird_on) begin
            // Map the active palette value (active_pal) to RGB colors
            case (active_pal) 
                3'b001: begin // Black
                    Red = black[11:8];
                    Green = black[7:4];
                    Blue = black[3:0];
                end
                3'b010: begin // White
                    Red = white[11:8];
                    Green = white[7:4];
                    Blue = white[3:0];
                end
                3'b011: begin // Yellow
                    Red = yellow[11:8];
                    Green = yellow[7:4];
                    Blue = yellow[3:0];
                end
                3'b100: begin // Orange
                    Red = orange[11:8];
                    Green = orange[7:4];
                    Blue = orange[3:0];
                end
                3'b101: begin // Red
                    Red = red[11:8];
                    Green = red[7:4];
                    Blue = red[3:0];
                end
                default: begin // Default to background
                    if (game_start == 1) begin
                        Red = bg_red; 
                        Green = bg_green;
                        Blue = bg_blue;
                    end else begin
                        Red = ss_red; 
                        Green = ss_green;
                        Blue = ss_blue;
                    end
                end
            endcase
        end else if (pipe_on) begin
            case (pipe_pal)
                2'b01: begin // Black
                    Red = black[11:8];
                    Green = black[7:4];
                    Blue = black[3:0];
                end
                
                2'b10: begin // Green
                    Red = green[11:8];
                    Green = green[7:4];
                    Blue = green[3:0];
                end
                
                default: begin // Default to background
                    if (game_start == 1) begin
                        Red = bg_red; 
                        Green = bg_green;
                        Blue = bg_blue;
                    end else begin
                        Red = ss_red; 
                        Green = ss_green;
                        Blue = ss_blue;
                    end
                end
            endcase
        end else begin 
            // Background gradient when outside the sprite
            if (game_start == 1) begin
                Red = bg_red; 
                Green = bg_green;
                Blue = bg_blue;
            end else begin
                Red = ss_red; 
                Green = ss_green;
                Blue = ss_blue;
            end
        end      
    end
endmodule