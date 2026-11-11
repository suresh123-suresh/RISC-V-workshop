vlib work
vlog riscv_2stage.v
vlog tb_riscv_waveform.v
vsim -voptargs=+acc work.tb_riscv_waveform

add wave -divider "Clock and Fetch"
add wave -radix hexadecimal sim:/tb_riscv_waveform/clk
add wave -radix hexadecimal sim:/tb_riscv_waveform/reset
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/pc
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/if_id_pc
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/if_id_instruction

add wave -divider "Execute and Write Back"
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/alu_result
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/write_data
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/reg_write
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/rd

add wave -divider "Branch"
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/branch_taken
add wave -radix hexadecimal sim:/tb_riscv_waveform/dut/branch_target

add wave -divider "Architectural State"
add wave -radix unsigned sim:/tb_riscv_waveform/dut/registers(1)
add wave -radix unsigned sim:/tb_riscv_waveform/dut/registers(2)
add wave -radix unsigned sim:/tb_riscv_waveform/dut/registers(3)
add wave -radix unsigned sim:/tb_riscv_waveform/dut/data_mem(0)

run -all
