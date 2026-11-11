vlib work
vlog riscv_2stage.v
vlog cpu_tb.v
vsim -voptargs=+acc work.cpu_tb
add wave -radix hexadecimal sim:/cpu_tb/clk
add wave -radix hexadecimal sim:/cpu_tb/reset
add wave -radix hexadecimal sim:/cpu_tb/dut/pc
add wave -radix hexadecimal sim:/cpu_tb/dut/if_id_pc
add wave -radix hexadecimal sim:/cpu_tb/dut/if_id_instruction
add wave -radix hexadecimal sim:/cpu_tb/dut/alu_result
add wave -radix hexadecimal sim:/cpu_tb/dut/write_data
add wave -radix hexadecimal sim:/cpu_tb/dut/branch_taken
add wave -radix hexadecimal sim:/cpu_tb/dut/branch_target
run -all
