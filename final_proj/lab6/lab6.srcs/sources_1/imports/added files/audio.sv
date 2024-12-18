module pwm_sine_wave (
    input logic clk_100MHz,  // Input 
    input logic [15:0] freq,
    input logic [2:0] volume,
    input logic lock,
    output logic SPK       // PWM output for left channel
);

    logic [7:0] sine_table[0:31];      // Sine wave lookup table (32 steps, 8-bit values)
    logic [4:0] index  = 0;            // Index for sine table
    logic [7:0] duty_cycle = 0;        // Current PWM duty cycle
    logic [18:0] counter = 0;          // Counter for PWM timing  // 18 bits are sufficient to count to 142,857
    
    // Initialize sine wave lookup table
    //sin(degree) = ((degree+1)/2) * 255
    initial begin
        sine_table[0]  = 128; // Sin(0°) = 0.5 (normalized to 8-bit range)
        sine_table[1]  = 153; // Sin(11.25°)
        sine_table[2]  = 178; // Sin(22.5°)
        sine_table[3]  = 201; // Sin(33.75°)
        sine_table[4]  = 222; // Sin(45°)
        sine_table[5]  = 239; // Sin(56.25°)
        sine_table[6]  = 252; // Sin(67.5°)
        sine_table[7]  = 255; // Sin(78.75°)
        sine_table[8]  = 252; // Sin(90°)
        sine_table[9]  = 239;
        sine_table[10] = 222;
        sine_table[11] = 201;
        sine_table[12] = 178;
        sine_table[13] = 153;
        sine_table[14] = 128;
        sine_table[15] = 102;
        sine_table[16] = 77;
        sine_table[17] = 54;
        sine_table[18] = 33;
        sine_table[19] = 16;
        sine_table[20] = 3;
        sine_table[21] = 0;
        sine_table[22] = 3;
        sine_table[23] = 16;
        sine_table[24] = 33;
        sine_table[25] = 54;
        sine_table[26] = 77;
        sine_table[27] = 102;
        sine_table[28] = 128;
        sine_table[29] = 153; 
        sine_table[30] = 178;
        sine_table[31] = 201;
    end
    
    //code for a sampled sine wave (current implementation: 250 Hz)
    logic [31:0] slow_counter = 0;  // Slow counter to divide the clock
    logic [7:0] pwm_counter = 0;       // Counter for PWM generation

    //slow_counter = 100_MHz clk / (number of entries in wave table * frequency of sine wave)
    // = 100,000,000 / (32 * 250)= 12500 cycles 
    // Volume control scaling factor (integer-based)
    localparam int scale_factor_numerator = 50;  // Scale factor numerator (e.g., 0.5 as 50)
    localparam int scale_factor_denominator = 100; // Scale factor denominator (e.g., 1.0 as 100)
    always_ff @(posedge clk_100MHz) begin
        // Ensure frequency and volume are non-zero
        if (freq == 0 || volume == 0 || lock == 0) begin
            SPK = 0;
        end else begin
            // Slow counter logic
            if (slow_counter < (100000000/(freq* 32)) - 1) begin
                slow_counter = slow_counter + 1;
            end else begin
                slow_counter = 0;
                if (index == 31) begin
                    index = 0;
                end else begin
                    index = index + 1;
                end
            end
         end
        // Update the duty cycle based on the scaled sine wave value
        duty_cycle = (sine_table[index] * scale_factor_numerator * volume) / scale_factor_denominator;
        
        // Generate PWM signal for SPKL and SPKR
        if (pwm_counter < duty_cycle) begin
            SPK = 1;
        end else begin
            SPK = 0;
        end

        // Increment the PWM counter
        pwm_counter = pwm_counter + 1;
    end

endmodule


module hardware_only_audio(
    input clk_100MHz,
    input [15:0] sw_i,
    input reset_rtl_0,
    input BTN2,
    input [7:0] keycode,
    
    output SPKL,
    output SPKR
);
  
  parameter [7:0] UP_KEYCODE_1 = 8'h1A; // Keycode for "W"
  parameter [7:0] UP_KEYCODE_2 = 8'h52; // Keycode for "Up Arrow"
  
  // Array of frequencies
  localparam int TAB_SIZE = 38;
  localparam logic [15:0] frequencies[TAB_SIZE] = '{
        300, 300, 299, 300, 400, 300, 400, 400, 
        300, 300, 300, 300, 400, 400, 400, 400, 500, 
        500, 600, 600, 700, 800, 800, 900, 1000, 1000,
        1100, 1100, 1100, 1100, 1100, 1100, 1100, 1100,
        1100, 1100, 1100, 1028
  };

  logic [2:0] volume;
  logic [15:0] frequency = 0;
  logic [31:0] counter;
  logic [5:0] i;
  logic lock = 0;

  assign volume = sw_i[2:0];

  // ----------------------------------------
  // Button Press Detection
  // ----------------------------------------
  logic BTN2_prev = 0; 
  logic button_pressed = 0; 
  always_ff @(posedge clk_100MHz) begin
    if ((BTN2 == 1 || keycode == UP_KEYCODE_1 || keycode == UP_KEYCODE_2) && BTN2_prev == 0) 
      button_pressed <= 1;
    else
      button_pressed <= 0;
      
    BTN2_prev <= BTN2;
  end

  // ----------------------------------------
  // Frequency Cycling Logic
  // ----------------------------------------
  always_ff @(posedge clk_100MHz or posedge reset_rtl_0) begin
    if (reset_rtl_0) begin
      counter <= 0;
      i <= 0;
      frequency <= frequencies[0];
    end else if (!lock) begin
      // If lock is 0, reset the sequence
      counter <= 0;
      i <= 0;
      frequency <= frequencies[0];
    end else if (button_pressed) begin
      // If the button is pressed again while playing, restart sequence
      counter <= 0;
      i <= 0;
      frequency <= frequencies[0];
    end else begin
      // Normal operation: increment counter and cycle through frequencies
      if (counter == 5_000_000) begin
        counter <= 0;
        i <= (i + 1) % TAB_SIZE;
        frequency <= frequencies[i];
      end else begin
        counter <= counter + 1;
      end
    end
  end

  // ----------------------------------------
  // Lock Logic
  // ----------------------------------------
  logic [31:0] lock_counter = 0;
  always_ff @(posedge clk_100MHz) begin
    if (button_pressed) begin
      lock <= 1;
      lock_counter <= 0;
    end else if (lock == 1) begin
      if (lock_counter == 40_000_000) begin
        lock <= 0;
        lock_counter <= 0;
      end else begin
        lock_counter <= lock_counter + 1;
      end
    end
  end

  // ----------------------------------------
  // PWM Sine Wave Generation
  // ----------------------------------------
  pwm_sine_wave pwm_sine_wave (
    .clk_100MHz(clk_100MHz),
    .freq(frequency),
    .volume(volume),
    .SPK(SPKR),
    .lock(lock)
  );

endmodule
