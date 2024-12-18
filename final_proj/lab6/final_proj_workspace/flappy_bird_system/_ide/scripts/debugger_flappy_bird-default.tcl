# Usage with Vitis IDE:
# In Vitis IDE create a Single Application Debug launch configuration,
# change the debug type to 'Attach to running target' and provide this 
# tcl script in 'Execute Script' option.
# Path of this script: C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\final_proj_workspace\flappy_bird_system\_ide\scripts\debugger_flappy_bird-default.tcl
# 
# 
# Usage with xsct:
# To debug using xsct, launch xsct and run below command
# source C:\Users\austi\OneDrive\Desktop\385Labs\final_proj\lab6\final_proj_workspace\flappy_bird_system\_ide\scripts\debugger_flappy_bird-default.tcl
# 
connect -url tcp:127.0.0.1:3121
targets -set -filter {jtag_cable_name =~ "RealDigital Boo 8874292300B3A" && level==0 && jtag_device_ctx=="jsn1-0362f093-0"}
fpga -file C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/final_proj_workspace/flappy_bird/_ide/bitstream/flappy_bird_final_proj.bit
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
loadhw -hw C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/final_proj_workspace/flappy_bird_final_proj/export/flappy_bird_final_proj/hw/flappy_bird_final_proj.xsa -regs
configparams mdm-detect-bscan-mask 2
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
rst -system
after 3000
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
dow C:/Users/austi/OneDrive/Desktop/385Labs/final_proj/lab6/final_proj_workspace/flappy_bird/Debug/flappy_bird.elf
targets -set -nocase -filter {name =~ "*microblaze*#0" && bscan=="USER2" }
con
