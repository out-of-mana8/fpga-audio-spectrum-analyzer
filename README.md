<div align="center">
  
# 🎛️ FPGA Audio Spectrum Analyzer
**Real-Time Audio Spectrum Visualization on Altera DE2-115**

[![Cyclone IV](https://img.shields.io/badge/Intel_FPGA-Cyclone_IV_E-blue?logo=intel)](https://www.intel.com/)
[![Language](https://img.shields.io/badge/Hardware-SystemVerilog_%7C_VHDL-green)](#)
[![Display](https://img.shields.io/badge/Video-VGA_640x480@60Hz-orange)](#)
[![Audio Interface](https://img.shields.io/badge/Audio-WM8731_Codec-yellow)](#)

</div>

---

## 🌟 Overview
A massive, real-time hardware audio spectrum analyzer demonstrating mixed-language FPGA logic design (SystemVerilog & VHDL). Targeted at the **Terasic DE2-115 development board** (Cyclone IV E), this project captures real-time audio via the onboard microphone, computes a 256-point Fast Fourier Transform (FFT), and renders a beautiful, highly dynamic GUI entirely in hardware via VGA output.

Forget boring command-line debug outputs. This project visualizes sound in real-time with stunning logarithmic bar graphs, falling peak markers, and a fully functional scrolling thermal waterfall spectrogram.

---

## ✨ Features
* **🎙️ Audio Capture Pipeline (I2S & I2C):** Interfaces directly with the Wolfson WM8731 Audio Codec using custom `i2c_master` and `i2s_capture` cores.
* **⚡ Blazing Fast HW FFT Engine:** Custom, 8-stage **256-point Radix-2 FFT** written natively in SystemVerilog, sporting an embedded twiddle-factor ROM.
* **📺 High-Fidelity VGA Display Engine (VHDL):**  
  * **640x480 @ 60Hz** native signal generation (using a 25 MHz pixel clock).
  * **128-bin Logarithmic Bar Graph:** A smooth, glowing visualizer mapping frequency magnitudes to visual heights using piece-wise logarithmic estimation.
  * **Smooth Animations:** Instant attack and slow, graceful 3-pixel/frame decay.
  * **Peak Hold Markers:** Small, bright cyan floating markers over each frequency bin that hold the peak and slowly trickle down.
  * **Waterfall Spectrogram:** 128-row scrolling "heat-map" history with dynamic coloring.
  * **Pixel Text Overlays:** Axis grid lines and labels generated completely in hardware logic using a custom minimal 4x5 font ROM.
* **🔊 LED VU Meter:** Dynamic, real-time audio volume monitoring utilizing 18 red LEDs on the DE2-115.
* **🔢 7-Segment Feedback:** Real-time BCD conversion pushing the exact peak frequency (Hz) and magnitude directly to the board's 8 HEX displays.

---

## 🛠️ Hardware Requirements
* **FPGA Board:** Terasic DE2-115 (Altera Cyclone IV E `EP4CE115F29C7`)
* **Audio:** Microphone or Line-In audio source (for the WM8731 mic/line jack)
* **Display:** Standard VGA-compatible monitor
* **Cables:** VGA Cable, 3.5mm Audio Cable

---

## 📂 Project Structure
```text
fpga-audio-spectrum-analyzer/
├── spectrum_analyzer_top.sv    # Top-level module, FFT Engine, I2S capture, I2C, VU meter
├── vga_spectrum_display.vhd    # VHDL Display Controller (Bar graph, Waterfall, VGA Syncing)
├── pll_audio.vhd               # Audio Clock Generation (50MHz -> 12.288MHz)
├── pin_assignments.tcl         # Comprehensive TCL script for DE2-115 pin mappings
├── vga_pin_assignments.qsf     # Specific pin mappings for the ADV7123 VGA DAC
└── spectrum.qsf / .qpf         # Quartus project architecture configuration files
```

---

## 🚀 Getting Started

### 1. Build and Compile
1. Clone the repository and open `spectrum.qpf` in **Intel Quartus Prime**.
2. Run the included Tcl assignment scripts from the TCL console to configure pinout:
   ```tcl
   source pin_assignments.tcl
   ```
3. Hit **Compile**! Quartus will analyze, map, and fit the mixed SV/VHDL sources to the Cyclone IV fabric.

### 2. Run on the DE2-115
1. Ensure your DE2-115 is plugged into power and your computer via USB-Blaster.
2. Hook up a VGA monitor to the VGA output port.
3. Plug a dynamic microphone into the physical MIC-IN standard pink audio jack.  
   *(Optionally, plug headphones into LINE-OUT to hear the passthrough audio).*
4. Open the **Programmer** in Quartus, select your `output_files/spectrum_analyzer_top.sof`, and click **Start**.

### 3. Making Noise!
Once the design is loaded, make some noise! 
* The **Green LEDs** denote system statuses (PLL lock, Codec Ready, Frame capture rate).
* The **Red LEDs** map to a real-time amplitude VU meter.
* Look at the **VGA Display** and wait to be mesmerized by the real-time audio spectral density!

---

## 🧠 Under the Hood

### The FFT Core
The Fast Fourier Transform lives in `spectrum_analyzer_top.sv`. It runs an 8-stage continuous pipeline, converting windowed time-domain audio samplings pulled from the I2S capture buffers directly into complex frequency bins. It feeds these magnitudes out dynamically for downstream rendering.

### The Display Architecture
Written natively in VHDL (`vga_spectrum_display.vhd`), the display engine utilizes a heavily pipelined pixel-clock system operating precisely at the standard 25 MHz for `640x480 @ 60 Hz`. It takes linear frequency magnitudes and leverages combinational hardware priority encoders to instantly approximate a base-2 log function, compressing magnitude scales gracefully into visually appeasing on-screen heights and thermal gradient heatmap indices.

---

## 📝 License
This project is open-source and free to be used for educational, personal, or commercial means. Have fun building and hacking!

<div align="center">
  <i>If you like this project, consider giving it a ⭐!</i>
</div>
