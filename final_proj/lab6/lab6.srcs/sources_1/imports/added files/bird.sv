module  bird ( 
    input  logic        Reset, 
    input  logic        frame_clk,
    input  logic [7:0]  keycode,

    output logic [9:0]  birdX, 
    output logic [9:0]  birdY, 
    output logic [9:0]  birdS 
);
    

	 
    parameter [9:0] bird_X_Center=320;  // Center position on the X axis
    parameter [9:0] bird_Y_Center=240;  // Center position on the Y axis
    parameter [9:0] bird_X_Min=0;       // Leftmost point on the X axis
    parameter [9:0] bird_X_Max=639;     // Rightmost point on the X axis
    parameter [9:0] bird_Y_Min=0;       // Topmost point on the Y axis
    parameter [9:0] bird_Y_Max=479;     // Bottommost point on the Y axis
    parameter [9:0] bird_X_Step=1;      // Step size on the X axis
    parameter [9:0] bird_Y_Step=1;      // Step size on the Y axis
    
    // added
    parameter [9:0] gravity = 10'd1;    // Gravity constant
    parameter [9:0] flap_force = 10'd5; // Upward force applied on "flap"

    logic [9:0] bird_X_Motion;
    logic [9:0] bird_X_Motion_next;
    logic signed [9:0] bird_Y_Motion;      // changed to signed for gravity
    logic signed [9:0] bird_Y_Motion_next; // changed to signed for gravity

    logic [9:0] bird_X_next;
    logic [9:0] bird_Y_next;

    always_comb begin
        bird_Y_Motion_next = bird_Y_Motion; // set default motion to be same as prev clock cycle 
        bird_X_Motion_next = bird_X_Motion;
        
        // gravity 
//        bird_Y_Motion_next = bird_Y_Motion_next + gravity;

        //modify to control bird motion with the keycode    
        if (keycode == 8'h1A || keycode == 8'h52) // W & up arrow
        begin
            bird_X_Motion_next = 10'd0;
            bird_Y_Motion_next = -10'd1;
        end

        if ( (birdY + birdS) >= bird_Y_Max )  // bird is at the bottom edge, BOUNCE!
        begin
            bird_Y_Motion_next = (~ (bird_Y_Step) + 1'b1);  // set to -1 via 2's complement.
        end
        else if ( (birdY - birdS) <= bird_Y_Min )  // bird is at the top edge, BOUNCE!
        begin
            bird_Y_Motion_next = bird_Y_Step;
        end  
       //fill in the rest of the motion equations here to bounce left and right
       else if((birdX - birdS) <= bird_X_Min)
            bird_X_Motion_next = bird_X_Step;
       else if((birdX+ birdS) >= bird_X_Max)
            bird_X_Motion_next = (~ (bird_X_Step) + 1'b1);
       else
            bird_Y_Motion = bird_Y_Motion;

    end

    assign birdS = 16;  // default bird size
    assign bird_X_next = (birdX + bird_X_Motion_next);
    assign bird_Y_next = (birdY + bird_Y_Motion_next);
   
    always_ff @(posedge frame_clk) //make sure the frame clock is instantiated correctly
    begin: Move_bird
        if (Reset)
        begin 
            bird_Y_Motion <= 10'd0; //bird_Y_Step;
			bird_X_Motion <= 10'd1; //bird_X_Step;
            
			birdY <= bird_Y_Center;
			birdX <= bird_X_Center;
        end
        else 
        begin 

			bird_Y_Motion <= bird_Y_Motion_next; 
			bird_X_Motion <= bird_X_Motion_next; 

            birdY <= bird_Y_next;  // Update bird position
            birdX <= bird_X_next;
			
		end  
    end


    
      
endmodule
