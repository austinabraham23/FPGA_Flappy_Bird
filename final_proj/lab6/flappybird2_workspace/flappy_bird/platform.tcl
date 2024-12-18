# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\flappybird2_workspace\flappy_bird\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\flappybird2_workspace\flappy_bird\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {flappy_bird}\
-hw {C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\flappy_bird.xsa}\
-out {C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/flappybird2_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {flappy_bird}
platform generate -quick
platform clean
platform generate
