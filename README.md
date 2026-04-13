<div align="center">

<br>

```
  ██████  ██▓███  ▓█████  ▄████▄  ▄▄▄█████▓ ██▀███   █    ██  ███▄ ▄███▓
▒██    ▒ ▓██░  ██▒▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒▓██ ▒ ██▒ ██  ▓██▒▓██▒▀█▀ ██▒
░ ▓██▄   ▓██░ ██▓▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░▓██ ░▄█ ▒▓██  ▒██░▓██    ▓██░
  ▒   ██▒▒██▄█▓▒ ▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ ▒██▀▀█▄  ▓▓█  ░██░▒██    ▒██ 
▒██████▒▒▒██▒ ░  ░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ ░██▓ ▒██▒▒▒█████▓ ▒██▒   ░██▒
▒ ▒▓▒ ▒ ░▒▓▒░ ░  ░░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   ░ ▒▓ ░▒▓░░▒▓▒ ▒ ▒ ░ ▒░   ░  ░
```

# FPGA Audio Spectrum Analyzer

**Real-Time 256-Point FFT · Logarithmic Bar Graph · Waterfall Spectrogram · VGA 640×480@60Hz**

Built from scratch in **SystemVerilog + VHDL** for the Terasic DE2-115 (Altera Cyclone IV E)

<br>

[![FPGA](https://img.shields.io/badge/FPGA-Cyclone_IV_EP4CE115F29C7-0071C5?style=for-the-badge&logo=intel&logoColor=white)](#hardware-requirements)
[![HDL](https://img.shields.io/badge/HDL-SystemVerilog_|_VHDL--93-4FC08D?style=for-the-badge)](#project-structure)
[![VGA](https://img.shields.io/badge/Video-VGA_640×480@60Hz-E34F26?style=for-the-badge)](#display-engine-architecture)
[![Audio](https://img.shields.io/badge/Codec-WM8731_I²S/I²C-FFD700?style=for-the-badge)](#audio-capture-pipeline)
[![FFT](https://img.shields.io/badge/DSP-256--pt_Radix--2_FFT-9B59B6?style=for-the-badge)](#fft-engine)
[![License](https://img.shields.io/badge/License-Open_Source-2ECC71?style=for-the-badge)](#license)

</div>

---

## Overview

A fully hardware-implemented, real-time audio spectrum analyzer. No soft-core processors, no NIOS, no software stack — every operation from microphone capture through FFT computation to pixel-level VGA rendering is implemented as dedicated combinational and sequential logic on the FPGA fabric.

The system captures 16-bit audio at 48 kHz via the Wolfson WM8731 codec over I²S, computes a continuous-pipeline 256-point Radix-2 Decimation-in-Time FFT, and drives a rich multi-zone VGA display at 640×480@60Hz through the onboard ADV7123 triple 10-bit DAC. Peripheral outputs include an 18-LED VU meter and 8 seven-segment displays showing real-time peak frequency (Hz) and magnitude.

The design is fully mixed-language: the top-level datapath, FFT core, audio interfaces, and control logic are written in **SystemVerilog**, while the pixel-pipelined VGA display engine is written in **VHDL-93** — demonstrating seamless cross-language module instantiation in Intel Quartus Prime.

---

## System Architecture

```
                         ┌─────────────────────────────────────────────────────────────┐
                         │                    CYCLONE IV FPGA                          │
                         │                                                             │
  ┌──────────┐   I²S     │  ┌───────────┐   256 samples   ┌──────────────┐             │
  │  WM8731  │──────────▶│  │ I2S       │   (bit-rev'd)   │  256-pt FFT  │             │
  │  Codec   │◀──────────│  │ Capture   │────────────────▶│  Radix-2 DIT │             │
  │          │   I²C     │  └───────────┘                  │  8 Stages    │             │
  └──────────┘◀──────────│  ┌───────────┐                  │              │             │
       │         init    │  │ WM8731    │                  │  Twiddle ROM │             │
   MIC IN                │  │ Init (I²C)│                  │  128 × 32b   │             │
                         │  └───────────┘                  └──────┬───────┘             │
                         │                                        │                     │
                         │                    128 × 16-bit magnitudes                   │
                         │                           │                                  │
                         │          ┌────────────────┬┴──────────────────┐               │
                         │          ▼                ▼                   ▼               │
                         │   ┌─────────────┐  ┌───────────┐    ┌──────────────┐         │
                         │   │ Peak Detect │  │  VU Meter  │    │ VGA Display  │         │
                         │   │ + BCD Conv  │  │  18× LEDR  │    │ Engine       │         │
                         │   └──────┬──────┘  └───────────┘    │ (VHDL)       │         │
                         │          ▼                           │              │  ──▶ VGA│
                         │   ┌─────────────┐                   │ Bar Graph    │         │
                         │   │ 8× HEX 7seg│                   │ Peak Hold    │         │
                         │   │ Freq + Mag  │                   │ Waterfall    │         │
                         │   └─────────────┘                   │ Axis Labels  │         │
                         │                                     └──────────────┘         │
                         └─────────────────────────────────────────────────────────────┘
```

---

## Features

### Audio Capture Pipeline

The WM8731 codec is initialized over I²C using a bit-banged master (`i2c_master`) at a clock divider of 200 (250 kHz SCL from 50 MHz). The initialization sequencer (`wm8731_init`) writes 11 register values configuring the codec for line-in capture at full volume, 48 kHz sample rate, I²S format, 16-bit word length, and digital audio interface activation.

The `i2s_capture` module synchronizes the asynchronous `AUD_BCLK`, `AUD_ADCLRCK`, and `AUD_ADCDAT` signals into the 50 MHz clock domain using triple-register synchronizers. Left-channel samples are captured on the falling edge of LRCLK and shifted in MSB-first over 16 bit-clock rising edges. Each sample is stored directly into a 256-deep capture buffer at a **bit-reversed address** — performing the DIT input reordering in hardware, eliminating a separate permutation stage.

Audio loopback is wired: `AUD_DACDAT = AUD_ADCDAT`, allowing headphone monitoring of the input signal.

### FFT Engine

The FFT core (`fft_core`) implements an 8-stage, in-place, Radix-2 Decimation-in-Time butterfly computation over 256 complex samples stored in dual 256×32-bit register-file RAMs (real and imaginary).

**Pipeline stages:**

| State | Operation |
|:------|:----------|
| `F_LOAD` | Bulk-load 256 bit-reversed samples from capture buffer into `ram_re[]`, zero-fill `ram_im[]` |
| `F_SINIT` | Initialize stage parameters: half-size, block size, block count |
| `F_RA/RB` | Compute butterfly pair indices: `top = blk × bsz + bfy`, `bot = top + hsz` |
| `F_TW` | Address twiddle ROM: `addr = bfy << (7 - stage)` |
| `F_CMP` | Butterfly: multiply-accumulate using 4 parallel 16×32 multipliers with Q15 fixed-point scaling |
| `F_WR` | Write back: `ram[top] = (A + W·B) >> 1`, `ram[bot] = (A - W·B) >> 1` (scaling prevents overflow) |
| `F_MAG` | Magnitude estimation via `max(|Re|,|Im|) + min(|Re|,|Im|)/4` (no sqrt needed) |

The twiddle factor ROM stores 128 pre-computed entries as packed `{cos[15:0], sin[15:0]}` words in Q15 format, covering a full period of `e^{-j2πk/256}`. Butterfly complex multiplication resolves to four real multiplies and two additions, producing results in Q15 fixed-point with a 1-bit right-shift per stage to maintain headroom across all 8 stages.

Magnitude output is clamped to 16 bits and streamed for bins 0–127 (positive-frequency half of the symmetric spectrum).

### VGA Display Engine

The display controller (`vga_spectrum_display.vhd`) generates a standard 640×480@60Hz VGA signal by dividing the 50 MHz system clock to 25 MHz. Pixel generation is organized into a 2-stage pipeline clocked on alternating phases of the pixel enable signal.

**Screen layout (480 vertical lines):**

```
  y=0  ┌──────────────────────────────────────┐
       │         (header / margin)             │  20 px
 y=20  ├──────────────────────────────────────┤
       │                                      │
       │     128-BIN BAR GRAPH                │  320 px
       │     (logarithmic magnitude scaling)  │
       │     with peak-hold markers           │
       │                                      │
y=339  ├──────────────────────────────────────┤
       │  DIVIDER (axis labels: 0,5k,10k...) │  10 px
y=349  ├──────────────────────────────────────┤
       │                                      │
       │     WATERFALL SPECTROGRAM            │  128 px
       │     (scrolling heat-map history)     │
       │                                      │
y=477  └──────────────────────────────────────┘
```

Each of the 128 frequency bins occupies 5 horizontal pixels (4 filled + 1 gap), spanning the full 640-pixel width. Bin-to-pixel mapping uses synthesized **divide-by-5 and mod-5 lookup tables** (640 entries each) to avoid runtime division hardware.

**Logarithmic magnitude scaling** is computed with a priority-encoder-based `log_height()` function: the leading-one position yields the integer part of `log₂(magnitude)`, and 4 fractional bits below it are extracted via a case statement (avoiding non-constant bit-select). Height output is `22 × log₂(mag) + frac`, clamped to [0, 319].

**Bar animation** runs once per VGA frame (triggered on vsync falling edge): instant attack to target height, then a smooth 3-pixel/frame exponential decay. **Peak-hold markers** (bright cyan, 2px tall) follow the highest bar target and decay at 1 pixel every 4 frames.

The **waterfall spectrogram** stores 128 rows × 128 columns in a 16 KB M9K block RAM. Each new FFT frame writes one row at the current `wf_wr_row` pointer (incrementing modulo 128). Magnitude values are compressed from 16-bit to 8-bit using piecewise log scaling (`compress8`). During scanout, the row address wraps relative to `wf_wr_row` to create the scrolling effect.

**Thermal color palette** (5-zone gradient for both bars and waterfall):

| Zone | Bar Region | Waterfall Value | Color Transition |
|:-----|:-----------|:----------------|:-----------------|
| 0 | 0–79 px | 0–31 | Black → Deep Blue |
| 1 | 80–159 px | 32–95 | Blue → Cyan |
| 2 | 160–239 px | 96–159 | Cyan → Yellow |
| 3 | 240–319 px | 160–223 | Yellow → Red |
| 4 | (glow only) | 224–255 | Red → White-hot |

**Text overlays** are rendered via a custom **4×5 pixel font ROM** (17 characters: `0-9`, `k`, `H`, `z`, `d`, `B`, `-`, space) stored as 85 × 4-bit entries. X-axis labels (0, 5k, 10k, 15k, 20k, kHz) and Y-axis dB scale markers (−20, −40, −60, −80) are hard-coded at specific pixel coordinates and rendered in a blue-gray tone.

### Peripheral Outputs

**VU Meter:** The 18 red LEDs implement a peak-hold VU meter with 18 non-linear thresholds (64, 128, 256, …, 32000) applied to the absolute value of each I²S sample. Peak tracking uses a sample-rate decay with a configurable hold counter.

**7-Segment Displays:** HEX7–HEX4 show the dominant frequency bin converted to Hz (`bin × 188 Hz/bin` at 48 kHz / 256 points) via a Double-Dabble binary-to-BCD converter. HEX3–HEX0 show the raw peak magnitude in hexadecimal.

**Status LEDs (Green):**

| LED | Signal |
|:----|:-------|
| LEDG[0] | PLL locked (12.288 MHz audio MCLK) |
| LEDG[1] | WM8731 I²C configuration complete |
| LEDG[2] | FFT engine busy |
| LEDG[3] | Frame capture rate indicator (pulse stretcher) |

---

## Hardware Requirements

| Component | Specification |
|:----------|:-------------|
| **FPGA Board** | Terasic DE2-115 — Altera Cyclone IV E `EP4CE115F29C7` |
| **Audio Source** | 3.5mm microphone or line-level source into the WM8731 MIC/LINE jack |
| **Display** | Any VGA-compatible monitor (640×480@60Hz minimum) |
| **Cables** | VGA cable, 3.5mm audio cable |
| **Toolchain** | Intel Quartus Prime 25.1+ (Lite Edition is sufficient) |

---

## Project Structure

```
fpga-audio-spectrum-analyzer/
│
├── spectrum_analyzer_top.sv        ← Top-level: reset, PLL, codec init, I2S, FFT,
│                                     peak detect, BCD, VU meter, VGA instantiation
│   ├── twiddle_rom                   128-entry cos/sin ROM (Q15 packed 32-bit)
│   ├── i2c_master                    Bit-banged I²C controller (250 kHz)
│   ├── wm8731_init                   11-register codec configuration sequencer
│   ├── i2s_capture                   I²S receiver with bit-reversed sample buffer
│   ├── fft_core                      256-point Radix-2 DIT FFT engine
│   ├── hex_display                   Active-low 7-segment decoder
│   └── audio_pll                     PLL wrapper (50 MHz → 12.288 MHz)
│
├── vga_spectrum_display.vhd        ← VHDL display controller
│   ├── VGA timing generator          800×525 total, 25 MHz pixel clock
│   ├── Magnitude capture & latch     Double-buffered FFT output
│   ├── Log-scale converter           Priority-encoder log₂ approximation
│   ├── Bar animator                  Attack/decay state machine
│   ├── Peak-hold tracker             Per-bin peak with frame-rate decay
│   ├── Waterfall RAM (M9K)           16 KB circular row buffer
│   ├── 2-stage pixel pipeline        Bin lookup → color generation
│   └── Font ROM & label renderer     4×5 bitmap font, axis annotations
│
├── pll_audio.vhd                   ← Quartus MegaWizard ALTPLL IP
├── pll_audio.qip                   ← IP component declaration
├── pll_audio.ppf                   ← PLL parameter file
│
├── pin_assignments.tcl             ← Complete DE2-115 pin mapping (Tcl script)
├── vga_pin_assignments.qsf         ← VGA DAC pin subset
├── spectrum.qpf                    ← Quartus project file
└── spectrum.qsf                    ← Quartus settings file
```

---

## Getting Started

### Build

1. Clone this repository and open `spectrum.qpf` in Intel Quartus Prime.
2. Source the pin assignments from the Tcl console:
   ```tcl
   source pin_assignments.tcl
   ```
3. Compile (Analysis & Synthesis → Fitter → Assembler). Quartus handles the mixed SystemVerilog + VHDL compilation natively.

### Program

1. Connect the DE2-115 via USB-Blaster.
2. Plug a VGA monitor into the VGA port and a microphone into the pink MIC-IN jack.
3. Open the Quartus Programmer, load `output_files/spectrum_analyzer_top.sof`, and click **Start**.

### Verify

| Indicator | Expected State |
|:----------|:---------------|
| LEDG[0] | ON — PLL locked |
| LEDG[1] | ON — Codec configured |
| LEDG[2] | Blinking — FFT processing frames |
| LEDG[3] | ON — Audio frames arriving |
| LEDR[0–17] | Bouncing with audio level |
| VGA Monitor | Bar graph + waterfall rendering |
| HEX7–4 | Dominant frequency in decimal Hz |

---

## Technical Deep-Dives

### Clock Domains

The design operates across two clock domains:

| Domain | Frequency | Source | Usage |
|:-------|:----------|:-------|:------|
| `CLOCK_50` | 50 MHz | Board oscillator (PIN_Y2) | System clock, FFT, VGA timing, I²C |
| `clk_12` | 12.288 MHz | ALTPLL from 50 MHz | WM8731 MCLK (`AUD_XCK`) |

The I²S interface signals (`AUD_BCLK`, `AUD_ADCLRCK`, `AUD_ADCDAT`) are generated by the codec in the 12.288 MHz domain and crossed into the 50 MHz domain via triple-register synchronizers in `i2s_capture`.

The 25 MHz VGA pixel clock is derived from `CLOCK_50` via a toggle flip-flop (`pclk_en`), driving the ADV7123 DAC clock output and gating pixel-pipeline advancement.

### FFT Numerical Format

All butterfly computations use 32-bit signed fixed-point internally. Input samples are sign-extended from 16-bit to 32-bit on load. Twiddle factors are Q15 (1 sign bit + 15 fractional bits). Butterfly products are 48-bit and right-shifted by 15 to return to Q32. An additional 1-bit right-shift per stage (the `>>>1` on output assignments) prevents overflow accumulation across 8 stages, equivalent to a 1/N scaling.

### Magnitude Approximation

The `F_MAG` state avoids expensive square-root hardware by using the `alpha-max-beta-min` approximation:

```
|Z| ≈ max(|Re|, |Im|) + min(|Re|, |Im|) / 4
```

This provides ~4% maximum error relative to the true Euclidean magnitude — more than sufficient for display purposes and dramatically cheaper in LUT/register usage than a CORDIC or multiplier-based approach.

### Display Rendering Budget

At 25 MHz pixel clock, the display engine has exactly **40 ns per pixel**. The 2-stage pipeline ensures all combinational logic (bin lookup via LUT, bar/peak comparison, color gradient computation, waterfall RAM read, font ROM lookup, and mux) is partitioned across two 50 MHz clock cycles, meeting timing with margin.

The waterfall RAM is implemented in Cyclone IV M9K block RAM (inferred via the `ramstyle` attribute), providing single-cycle read latency with no resource pressure on the logic fabric.

---

## Resource Utilization (Estimated)

| Resource | Usage | Available | Notes |
|:---------|:------|:----------|:------|
| Logic Elements | ~6,000 | 114,480 | FFT butterfly + VGA pipeline |
| M9K Blocks | ~2 | 432 | Waterfall RAM + twiddle ROM |
| PLLs | 1 | 4 | 50 MHz → 12.288 MHz |
| Multipliers | 4 | 532 | FFT butterfly (18×18 embedded) |
| I/O Pins | ~120 | 528 | VGA (27) + Audio (6) + HEX (56) + LED (26) |

---

## License

This project is open-source. Free for educational, personal, and commercial use. Attribution appreciated but not required.

<div align="center">
<br>

*Built with RTL, not software.*

</div>
