SRCS = src/clk_div.v src/vga_timing.v src/btn_debounce.v src/game_controller.v src/renderer.v src/top_platformer.v
IVERILOG = iverilog
VVP = vvp

.PHONY: all sim_game sim_renderer clean

all: sim_game sim_renderer

sim_game:
	@echo "=== Running Game Controller Testbench ==="
	$(IVERILOG) -o sim_game.out $(SRCS) sim/tb_game_controller.v
	$(VVP) sim_game.out

sim_renderer:
	@echo "=== Running Renderer Testbench ==="
	$(IVERILOG) -o sim_renderer.out $(SRCS) sim/tb_renderer.v
	$(VVP) sim_renderer.out

clean:
	rm -f *.out *.vcd
