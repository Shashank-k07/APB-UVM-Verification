vlog +incdir+C:/questasim64_10.7c/verilog_src/uvm-1.1c/src run.sv
vopt work.apb_top +cover=fcbest -o apb
vsim -coverage apb -sv_lib C:/questasim64_10.7c/uvm-1.1c/win64/uvm_dpi
add wave -position insertpoint sim:/apb_top/vif/*
coverage save -onexit run.ucdb
run -all
