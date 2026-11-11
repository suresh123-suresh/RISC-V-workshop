vlib work
vlog riscv_2stage.v
vlog tb_riscv_day3_programs.v
vsim -voptargs=+acc work.tb_riscv_day3_programs
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/clk
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/reset
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/dut/pc
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/dut/if_id_instruction
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/dut/alu_result
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/dut/write_data
add wave -radix hexadecimal sim:/tb_riscv_day3_programs/dut/branch_taken
run -all
