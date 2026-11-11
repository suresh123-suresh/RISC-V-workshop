vlib work
vlog riscv_5stage.v
vlog tb_riscv_5stage_hazards.v
vsim -voptargs=+acc work.tb_riscv_5stage_hazards
add wave -divider "Fetch and Decode"
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/pc
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/IF_ID_pc
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/IF_ID_instruction
add wave -divider "Hazard Detection"
add wave -radix binary sim:/tb_riscv_5stage_hazards/dut/stall
add wave -radix binary sim:/tb_riscv_5stage_hazards/dut/forward_a
add wave -radix binary sim:/tb_riscv_5stage_hazards/dut/forward_b
add wave -divider "Execute and Memory"
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/alu_result
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/EX_MEM_alu_result
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/EX_MEM_write_data
add wave -radix binary sim:/tb_riscv_5stage_hazards/dut/branch_taken
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/branch_target
add wave -divider "Writeback"
add wave -radix hexadecimal sim:/tb_riscv_5stage_hazards/dut/MEM_WB_data
add wave -radix binary sim:/tb_riscv_5stage_hazards/dut/MEM_WB_reg_write
run -all
