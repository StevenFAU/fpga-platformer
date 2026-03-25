# FPGA Platformer

A hardware platformer game running on the Nexys4 DDR (Artix-7 XC7A100T), displayed over VGA at 640×480 @ 60Hz.

## Status

| Phase | Description | Status |
|-------|-------------|--------|
| 1 | Project scaffold + VGA timing | ✅ |
| 2 | Button debouncing | ⬜ |
| 3 | Static scene renderer | ⬜ |
| 4 | Game controller (physics) | ⬜ |
| 5 | Top-level integration | ⬜ |

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

### Modules so far

- **`clk_div.v`** — Divides 100 MHz board clock to 25 MHz pixel clock (2-bit counter)
- **`vga_timing.v`** — Generates 640×480 @ 60 Hz VGA sync signals, pixel coordinates, and video enable

## Game Design

- **Player:** 16×24 red rectangle
- **Platforms:** 5 brown floating platforms in a staircase layout
- **Ground:** Green bar at y=448
- **Background:** Dark blue
- **Physics:** Fixed-point gravity (4 fractional bits), 0.7s jump arc

## Controls

| Button | Action |
|--------|--------|
| BTNL | Move left |
| BTNR | Move right |
| BTNU | Jump |
| BTNC | Reset |

## Build

### Simulation (Icarus Verilog)
```bash
make all
```

### Synthesis (Vivado)
```bash
vivado -mode batch -source create_project.tcl
vivado vivado_build/fpga_platformer.xpr
# Run Synthesis → Implementation → Generate Bitstream → Program
```

## Platform Layout

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

## Roadmap

- [ ] Sprite engine (replace rectangles with pixel art)
- [ ] Scrolling camera
- [ ] Enemies with patrol AI
- [ ] Coins and score display (seven-segment)
- [ ] Multiple levels via block RAM
- [ ] Sound effects (PWM)
- [ ] UART bridge for loading levels from PC
