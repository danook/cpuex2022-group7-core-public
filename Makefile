SRC	= top.v memory/verilog/cache_def.sv utils.sv modules/*.sv fpu/*.sv io/*.sv mock_ddr.sv bram.sv io_core_controller.sv core.sv

# Vivado required
all: $(SRC)
	verilator -Wall -cc config.vlt $(SRC)

clean:
	rm -r *.log *.pb xsim.dir