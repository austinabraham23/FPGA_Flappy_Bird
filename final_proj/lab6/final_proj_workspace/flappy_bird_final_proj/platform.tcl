# 
# Usage: To re-create this platform project launch xsct with below options.
# xsct C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\final_proj_workspace\flappy_bird_final_proj\platform.tcl
# 
# OR launch xsct and run below command.
# source C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\final_proj_workspace\flappy_bird_final_proj\platform.tcl
# 
# To create the platform in a different location, modify the -out option of "platform create" command.
# -out option specifies the output directory of the platform project.

platform create -name {flappy_bird_final_proj}\
-hw {C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\flappy_bird_final_proj.xsa}\
-out {C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/final_proj_workspace}

platform write
domain create -name {standalone_microblaze_0} -display-name {standalone_microblaze_0} -os {standalone} -proc {microblaze_0} -runtime {cpp} -arch {32-bit} -support-app {hello_world}
platform generate -domains 
platform active {flappy_bird_final_proj}
platform generate -quick
platform clean
platform generate
platform config -updatehw {C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/flappy_bird_final_proj.xsa}
platform clean
platform generate
platform config -updatehw {C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/flappy_bird_final_proj.xsa}
platform clean
platform generate