# FPGA Platformer — Nexys4 DDR (Artix-7 XC7A100T)

## Project Goal
A simple platformer game displayed via VGA (640×480 @ 60Hz) on the Nexys4 DDR.
Player is a colored rectangle that can run and jump across platforms.
Designed to be extended with sprites, enemies, scrolling, and scoring later.

## Board Details
- **FPGA:** Xilinx Artix-7 XC7A100T-1CSG324C
- **System clock:** 100 MHz (pin E3)
- **VGA output:** 12-bit color (4-bit R, 4-bit G, 4-bit B)
- **Target resolution:** 640×480 @ ~60 Hz (25 MHz pixel clock)
- **Inputs:** BTNL (left), BTNR (right), BTNU (jump), BTNC (reset)
- **Toolchain:** Vivado (synth/impl/bitstream), Icarus Verilog (simulation)

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │         top_platformer.v            │
                        │                                     │
  100 MHz ──► clk_div ──► 25 MHz pixel clock                  │
                        │         │                           │
         BTNU ──► debounce ──►┐                               │
         BTNL ──► debounce ──►├──► game_controller.v          │
         BTNR ──► debounce ──►┘   │  - player position        │
         BTNC ──► rst_n           │  - velocity / gravity     │
                        │         │  - collision detection    │
                        │         │  - on_ground state        │
                        │         └──► player_x, player_y     │
                        │                    │                │
                        │    vga_timing.v    │                │
                        │    │ pixel_x ──────┤                │
                        │    │ pixel_y ──────┤                │
                        │    │ video_on      │                │
                        │         │          │                │
                        │         ▼          ▼                │
                        │       renderer.v                    │
                        │       │ player rect → red           │
                        │       │ platforms   → brown         │
                        │       │ ground      → green         │
                        │       │ background  → dark blue     │
                        │       └──► rgb[11:0]                │
                        │                                     │
                        │  Outputs: vga_r/g/b, hsync, vsync   │
                        └─────────────────────────────────────┘
```

## Module Specifications

### `clk_div.v` — Clock Divider (reused from VGA Hello World)
- 100 MHz → 25 MHz via 2-bit counter

### `vga_timing.v` — VGA Sync Generator (reused)
- 640×480 @ 60 Hz, outputs hsync, vsync, pixel_x, pixel_y, video_on

### `btn_debounce.v` — Button Debouncer
- Two-stage synchronizer + 20ms stability counter
- One instance per button (3 total: left, right, jump)
- Input: raw button (active-high on Nexys4 DDR)
- Output: clean, debounced, synchronized signal

### `game_controller.v` — Game Logic
- Updates once per frame (on vsync rising edge)
- **Player state:**
  - `pos_x` [9:0]: horizontal pixel position (integer)
  - `pos_y_full` [15:0] signed: vertical position with 4 fractional bits
    - Pixel position = `pos_y_full[13:4]`
  - `vel_y` [9:0] signed: vertical velocity in sub-pixel units
  - `on_ground`: flag, set when standing on a platform
- **Constants:**
  - PLAYER_W = 16, PLAYER_H = 24
  - SPEED_X = 3 (pixels/frame)
  - GRAVITY = 3 (sub-pixels/frame², with 4 frac bits = 0.1875 px/frame²)
  - JUMP_VEL = -64 (sub-pixels/frame = -4 px/frame)
  - TERMINAL_VEL = 80 (sub-pixels/frame = 5 px/frame)
- **Per-frame update order:**
  1. Horizontal movement (button → pos_x ± SPEED_X, clamped to screen)
  2. Jump initiation (if btn_jump AND on_ground → vel_y = JUMP_VEL)
  3. Apply gravity (vel_y += GRAVITY, clamped to TERMINAL_VEL)
  4. Apply vertical velocity (pos_y_full += vel_y)
  5. Platform collision (if falling into a platform, snap to top, vel_y = 0)
  6. Screen bounds clamping
- **Collision detection:**
  - AABB overlap: player bottom edge vs platform top edge
  - Only when vel_y >= 0 (falling or stationary)
  - Horizontal overlap check: player_right > plat_left AND player_left < plat_right
  - Vertical check: player_bottom >= plat_y AND old_bottom < plat_y + tolerance
- Outputs: player_x[9:0], player_y[9:0] (pixel coords for renderer)

### `renderer.v` — Pixel Color Generator
- Combinational: given pixel_x, pixel_y, player_x, player_y → RGB
- Draw priority (highest first):
  1. Player rectangle → Red (R=F, G=2, B=0)
  2. Platform rectangles → Brown (R=8, G=5, B=1)
  3. Ground block → Green (R=1, G=8, B=1)
  4. Background → Dark Blue (R=0, G=0, B=3)
- Platform layout (all 8px thick):
  - Ground: x=0, y=448, w=640, h=32
  - Plat 0: x=80,  y=368, w=120
  - Plat 1: x=280, y=304, w=140
  - Plat 2: x=440, y=368, w=120
  - Plat 3: x=180, y=240, w=120
  - Plat 4: x=380, y=176, w=100
- Platform coordinates are duplicated in game_controller.v and renderer.v
  (future refactor: shared include file `platform_defs.vh`)

### `top_platformer.v` — Top-Level Module
- Instantiates clk_div, vga_timing, 3× btn_debounce, game_controller, renderer
- Maps VGA pins and button pins from XDC
- Reset from BTNC (active-high → active-low inversion)

## Platform Layout (Visual)
```
  0       100     200     300     400     500     600
  ·········|·······|·······|·······|·······|·······|···
                                    ┌──────────┐
  y=176                             │  Plat 4  │
                                    └──────────┘
               ┌──────────┐
  y=240        │  Plat 3  │
               └──────────┘
                           ┌────────────┐
  y=304                    │   Plat 1   │
                           └────────────┘
  ┌──────────┐                         ┌──────────┐
  y=368 │  Plat 0  │                   │  Plat 2  │
        └──────────┘                   └──────────┘

  ════════════════════════════════════════════════════
  y=448                    GROUND
  ════════════════════════════════════════════════════
  y=480
```

## Constraints File
- `constraints/nexys4ddr.xdc` — VGA + clock + buttons (BTNL, BTNR, BTNU, BTNC)

## Simulation Strategy
- `sim/tb_game_controller.v` — Verify gravity, jumping, landing, screen bounds
- `sim/tb_renderer.v` — Verify pixel colors at known positions
- Run with: `iverilog -o sim_out src/*.v sim/tb_*.v && vvp sim_out`

## Coding Style
- Verilog-2001 (Icarus compatible)
- `timescale 1ns / 1ps
- No vendor-specific IP
- Active-low reset (`rst_n`)
- `localparam` for internal constants

## Extension Points (for future work)
1. **Sprite engine:** Replace colored rectangles with bitmap sprites from a ROM
2. **Scrolling:** Add camera_x offset, tile map in block RAM
3. **Enemies:** Additional game objects with simple AI (patrol back and forth)
4. **Coins/collectibles:** Score counter displayed on seven-segment
5. **Multiple levels:** Tile maps stored in block RAM, loaded on level completion
6. **Sound:** Use PWM output for simple beeps on jump/collect
7. **UART bridge:** Load levels or sprite data from PC via serial

## Build Flow
```bash
# Simulation
make all

# Vivado (from Tcl script)
vivado -mode batch -source create_project.tcl
# Then open vivado_build/vga_hello_world.xpr, synth → impl → bitstream → program
```
