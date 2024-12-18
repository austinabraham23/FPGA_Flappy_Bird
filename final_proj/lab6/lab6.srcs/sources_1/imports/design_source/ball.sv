module ball 
( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,
    input  logic        BTN2, BTN3,
    input  logic [9:0]  pipe_offset1, pipe_offset2, pipe_offset3, pipe_offset4,

    output logic [9:0]  BallX, 
    output logic [9:0]  BallY, 
    output logic [9:0]  BallS,
    output logic [9:0]  PipeX1, PipeX2, PipeX3, PipeX4,
    output logic [9:0]  PipeY1, PipeY2, PipeY3, PipeY4,
    output logic [15:0] counter,
    output logic game_start,
    output logic [15:0] level
);

    parameter [9:0] Ball_X_Center = 320;  // Center position on the X axis
    parameter [9:0] Ball_Y_Center = 240;  // Center position on the Y axis
    parameter [9:0] Ball_Y_Max = 479;     // Bottommost point on the Y axis
    parameter [9:0] Ball_Y_Min = 0;       // Topmost point on the Y axis
    parameter [9:0] gravity = 10'd1;      // Gravity constant
    parameter gravity_delay = 8;          // Slows gravity
    parameter [9:0] Screen_Width = 639;   // Screen width
    parameter [7:0] UP_KEYCODE_1 = 8'h1A; // Keycode for "W"
    parameter [7:0] UP_KEYCODE_2 = 8'h52; // Keycode for "Up Arrow"
    parameter [7:0] DOWN_KEYCODE_1 = 8'h16;
    parameter [7:0] DOWN_KEYCODE_2 = 8'h51;
    //parameter [9:0] PIPE_SPACING = 250;   // Spacing between pipes
    
    parameter [9:0] PIPE_WIDTH = 26;
    parameter [9:0] BIRD_WIDTH = 17;
    parameter [9:0] BIRD_HEIGHT = 12;
    parameter [9:0] GAP = 60;

    logic [9:0] Ball_Y_Motion;            // Ball vertical motion
    logic [9:0] Ball_Y_Motion_next;       // Next value for vertical motion
    logic [9:0] Ball_Y_next;              // Next ball Y position

    logic [3:0] gravity_counter;          // Counter for slowing gravity
    logic key_pressed;                    // State flag for key press detection
    logic [3:0] pipe_passed;              // Track whether each pipe has been passed
    
    logic collision_occurred;             // Flag for collision detection
    logic [9:0] Pipe_Speed;       // Speed of pipe movement
    logic [9:0] difficulty;
    logic pipe_start;
    logic [9:0] PIPE_SPACING;

    assign BallS = 12;  // Default ball size
    assign Ball_Y_next = BallY + Ball_Y_Motion;

    // Initialize the game state and start logic
    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            game_start <= 1'b0;
        end else if (keycode == DOWN_KEYCODE_1 || keycode == DOWN_KEYCODE_2 || BTN3 == 1) begin
            game_start <= 1'b1;
        end else if (collision_occurred) begin
            game_start <= 1'b0;
        end
    end
    
    // Ball motion logic
    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            Ball_Y_Motion <= 10'd0; 
            BallY <= Ball_Y_Center;
            BallX <= Ball_X_Center;
            gravity_counter <= 4'd0;
            key_pressed <= 1'b0;
            collision_occurred <= 1'b0;
            
            // Initialize pipe positions
            PipeX1 <= Screen_Width + 1;
            PipeX2 <= Screen_Width + 1;
            PipeX3 <= Screen_Width + 1;
            PipeX4 <= Screen_Width + 1;
            
        end else if (game_start) begin               
            if (collision_occurred) begin
                collision_occurred = 0;
                BallY <= Ball_Y_Center;
                BallX <= Ball_X_Center;
                Ball_Y_Motion <= 10'd0;
                gravity_counter <= 4'd0;
                key_pressed <= 1'b0;
                
                PipeX1 <= Screen_Width + 1;
                PipeX2 <= Screen_Width + 1;
                PipeX3 <= Screen_Width + 1;
                PipeX4 <= Screen_Width + 1;
            end else begin
                // Update gravity counter
                if (gravity_counter == gravity_delay - 1)
                    gravity_counter <= 4'd0;
                else
                    gravity_counter <= gravity_counter + 1;
    
                // Apply gravity
                if (gravity_counter == 4'd0)
                    Ball_Y_Motion <= Ball_Y_Motion + gravity;            
                
                // Handle key press
                if ((keycode == UP_KEYCODE_1 || keycode == UP_KEYCODE_2 || BTN2 == 1) && !key_pressed) begin
                    Ball_Y_Motion <= -10'd3;  // Apply upward motion
                    key_pressed <= 1'b1;
                end else if (!(keycode == UP_KEYCODE_1 || keycode == UP_KEYCODE_2 || BTN2 == 1)) begin
                    key_pressed <= 1'b0;
                end
    
                // Reset ball position if it hits the bottom
                if ((BallY + BallS) >= Ball_Y_Max) begin
                    collision_occurred <= 1'b1;
                end else begin
                    BallY <= Ball_Y_next;  // Update ball position
                end
    
                // Collision detection with PipeX1
                if ((BallX + BIRD_WIDTH) >= PipeX1 && BallX <= (PipeX1 + PIPE_WIDTH)) begin
                    if (BallY >= (420 - pipe_offset1) && (BallY + BIRD_HEIGHT) <= (420 - pipe_offset1 + GAP)) begin
                        collision_occurred <= 1'b0;
                    end else begin
                        collision_occurred <= 1'b1;
                    end
                end
                
                // Collision detection with PipeX2
                if ((BallX + BIRD_WIDTH) >= PipeX2 && BallX <= (PipeX2 + PIPE_WIDTH)) begin
                    if (BallY >= (420 - pipe_offset2) && (BallY + BIRD_HEIGHT) <= (420 - pipe_offset2 + GAP)) begin
                        collision_occurred <= 1'b0;
                    end else begin
                        collision_occurred <= 1'b1;
                    end
                end
                
                // Collision detection with PipeX3
                if ((BallX + BIRD_WIDTH) >= PipeX3 && BallX <= (PipeX3 + PIPE_WIDTH)) begin
                    if (BallY >= (420 - pipe_offset3) && (BallY + BIRD_HEIGHT) <= (420 - pipe_offset3 + GAP)) begin
                        collision_occurred <= 1'b0;
                    end else begin
                        collision_occurred <= 1'b1;
                    end
                end
                
                // Collision detection with PipeX4
                if ((BallX + BIRD_WIDTH) >= PipeX4 && BallX <= (PipeX4 + PIPE_WIDTH)) begin
                    if (BallY >= (420 - pipe_offset4) && (BallY + BIRD_HEIGHT) <= (420 - pipe_offset4 + GAP)) begin
                        collision_occurred <= 1'b0;
                    end else begin
                        collision_occurred <= 1'b1;
                    end
                end
    
                // Move pipes in a rolling cycle
                if (PipeX1 == Screen_Width + 1) begin
                    PipeX1 = Screen_Width;
                end else if (PipeX1 > 0 && PipeX1 < Screen_Width + 1) begin
                    PipeX1 <= PipeX1 - Pipe_Speed;
                end else if (PipeX4 <= Screen_Width - PIPE_SPACING) begin
                    PipeX1 <= Screen_Width;
                end
    
                if (PipeX2 > 0 && PipeX2 < Screen_Width + 1) begin
                    PipeX2 <= PipeX2 - Pipe_Speed;
                end else if (PipeX1 <= Screen_Width - PIPE_SPACING) begin
                    PipeX2 <= Screen_Width;
                end
    
                if (PipeX3 > 0 && PipeX3 < Screen_Width + 1) begin
                    PipeX3 <= PipeX3 - Pipe_Speed;
                end else if (PipeX2 <= Screen_Width - PIPE_SPACING) begin
                    PipeX3 <= Screen_Width;
                end
    
                if (PipeX4 > 0 && PipeX4 < Screen_Width + 1) begin
                    PipeX4 <= PipeX4 - Pipe_Speed;
                end else if (PipeX3 <= Screen_Width - PIPE_SPACING) begin
                    PipeX4 <= Screen_Width;
                end

            end
        end
    end

    // Score counter logic
    always_ff @(posedge frame_clk or posedge Reset) begin
        if (Reset) begin
            counter <= 16'd0;       // Reset counter
            difficulty <= 16'd0;
            level <= 1;
            pipe_passed <= 4'b0000; // Reset tracking for all pipes
            Pipe_Speed <= 2;
            PIPE_SPACING = 250;
        end else if (difficulty == 5) begin
            PIPE_SPACING = PIPE_SPACING - 50;
            difficulty = 0;
            level = level + 1;
        end else if (collision_occurred) begin
            Pipe_Speed = 2;
            PIPE_SPACING = 250;
            difficulty = 0;
        end else if (!game_start && (keycode == DOWN_KEYCODE_1 || keycode == DOWN_KEYCODE_2 || BTN3 == 1)) begin
            level = 1;
            counter = 0;        
        end else begin
            // Check if the bird has passed each pipe
            if ((BallX > PipeX1 + 26) && !pipe_passed[0]) begin
                counter <= counter + 1;
                difficulty <= difficulty + 1;
                pipe_passed[0] <= 1'b1;
            end else if (PipeX1 > BallX) begin
                pipe_passed[0] <= 1'b0; // Reset passed flag when pipe resets
            end

            if ((BallX > PipeX2 + 26) && !pipe_passed[1]) begin
                counter <= counter + 1;
                difficulty <= difficulty + 1;
                pipe_passed[1] <= 1'b1;
            end else if (PipeX2 > BallX) begin
                pipe_passed[1] <= 1'b0; // Reset passed flag when pipe resets
            end

            if ((BallX > PipeX3 + 26) && !pipe_passed[2]) begin
                counter <= counter + 1;
                difficulty <= difficulty + 1;
                pipe_passed[2] <= 1'b1;
            end else if (PipeX3 > BallX) begin
                pipe_passed[2] <= 1'b0; // Reset passed flag when pipe resets
            end

            if ((BallX > PipeX4 + 26) && !pipe_passed[3]) begin
                counter <= counter + 1;
                difficulty <= difficulty + 1;
                pipe_passed[3] <= 1'b1;
            end else if (PipeX4 > BallX) begin
                pipe_passed[3] <= 1'b0; // Reset passed flag when pipe resets
            end
        end
    end
endmodule