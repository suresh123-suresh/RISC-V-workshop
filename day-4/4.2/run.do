vlib work
vlog riscv_5stage.v
vlog tb_riscv_5stage_control.v
vsim -voptargs=+acc work.tb_riscv_5stage_control
add wave -divider "Fetch"
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/pc
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/IF_ID_pc
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/IF_ID_instruction
add wave -divider "Control Hazard"
add wave -radix binary sim:/tb_riscv_5stage_control/dut/branch_taken
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/branch_target
add wave -radix binary sim:/tb_riscv_5stage_control/dut/ID_EX_branch
add wave -radix binary sim:/tb_riscv_5stage_control/dut/ID_EX_jump
add wave -divider "Pipeline Control"
add wave -radix binary sim:/tb_riscv_5stage_control/dut/stall
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/ID_EX_pc
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/EX_MEM_alu_result
add wave -divider "Writeback"
add wave -radix hexadecimal sim:/tb_riscv_5stage_control/dut/MEM_WB_data
add wave -radix binary sim:/tb_riscv_5stage_control/dut/MEM_WB_reg_write
run -all
