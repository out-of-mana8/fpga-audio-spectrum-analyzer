# =============================================================================
#  pin_assignments.tcl
#  DE2-115 Pin Assignments for Spectrum Analyzer
#
#  Usage:  In Quartus, Tools → Tcl Scripts → Run,
#          or from the Quartus Tcl console:  source pin_assignments.tcl
#
#  Covers: CLOCK, KEYs, Audio codec, I2C, 7-Segment HEX, LEDs, VGA
# =============================================================================

package require ::quartus::project

# ─── Clock ──────────────────────────────────────────────────────────────────
set_location_assignment PIN_Y2  -to CLOCK_50
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to CLOCK_50

# ─── Push buttons (active low) ──────────────────────────────────────────────
set_location_assignment PIN_M23 -to KEY[0]
set_location_assignment PIN_M21 -to KEY[1]
set_location_assignment PIN_N21 -to KEY[2]
set_location_assignment PIN_R24 -to KEY[3]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[0]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[1]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[2]
set_instance_assignment -name IO_STANDARD "2.5 V" -to KEY[3]

# ─── Audio codec (WM8731) ──────────────────────────────────────────────────
set_location_assignment PIN_E1  -to AUD_XCK
set_location_assignment PIN_F2  -to AUD_BCLK
set_location_assignment PIN_C2  -to AUD_ADCLRCK
set_location_assignment PIN_D2  -to AUD_ADCDAT
set_location_assignment PIN_E3  -to AUD_DACLRCK
set_location_assignment PIN_D1  -to AUD_DACDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_XCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_BCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCLRCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_ADCDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACLRCK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to AUD_DACDAT

# ─── I2C (codec configuration) ─────────────────────────────────────────────
set_location_assignment PIN_B7  -to I2C_SCLK
set_location_assignment PIN_A8  -to I2C_SDAT
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I2C_SCLK
set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to I2C_SDAT

# ─── Green LEDs ─────────────────────────────────────────────────────────────
set_location_assignment PIN_E21 -to LEDG[0]
set_location_assignment PIN_E22 -to LEDG[1]
set_location_assignment PIN_E25 -to LEDG[2]
set_location_assignment PIN_E24 -to LEDG[3]
set_location_assignment PIN_H21 -to LEDG[4]
set_location_assignment PIN_G20 -to LEDG[5]
set_location_assignment PIN_G22 -to LEDG[6]
set_location_assignment PIN_G21 -to LEDG[7]
foreach i {0 1 2 3 4 5 6 7} {
    set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDG[$i]
}

# ─── Red LEDs ───────────────────────────────────────────────────────────────
set_location_assignment PIN_G19 -to LEDR[0]
set_location_assignment PIN_F19 -to LEDR[1]
set_location_assignment PIN_E19 -to LEDR[2]
set_location_assignment PIN_F21 -to LEDR[3]
set_location_assignment PIN_F18 -to LEDR[4]
set_location_assignment PIN_E18 -to LEDR[5]
set_location_assignment PIN_J19 -to LEDR[6]
set_location_assignment PIN_H19 -to LEDR[7]
set_location_assignment PIN_J17 -to LEDR[8]
set_location_assignment PIN_G17 -to LEDR[9]
set_location_assignment PIN_J15 -to LEDR[10]
set_location_assignment PIN_H16 -to LEDR[11]
set_location_assignment PIN_J16 -to LEDR[12]
set_location_assignment PIN_H17 -to LEDR[13]
set_location_assignment PIN_F15 -to LEDR[14]
set_location_assignment PIN_G15 -to LEDR[15]
set_location_assignment PIN_G16 -to LEDR[16]
set_location_assignment PIN_H15 -to LEDR[17]
foreach i {0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17} {
    set_instance_assignment -name IO_STANDARD "2.5 V" -to LEDR[$i]
}

# ─── 7-Segment HEX displays (active low) ───────────────────────────────────
# HEX0
set_location_assignment PIN_G18 -to HEX0[0]
set_location_assignment PIN_F22 -to HEX0[1]
set_location_assignment PIN_E17 -to HEX0[2]
set_location_assignment PIN_L26 -to HEX0[3]
set_location_assignment PIN_L25 -to HEX0[4]
set_location_assignment PIN_J22 -to HEX0[5]
set_location_assignment PIN_H22 -to HEX0[6]

# HEX1
set_location_assignment PIN_M24 -to HEX1[0]
set_location_assignment PIN_Y22 -to HEX1[1]
set_location_assignment PIN_W21 -to HEX1[2]
set_location_assignment PIN_W22 -to HEX1[3]
set_location_assignment PIN_W25 -to HEX1[4]
set_location_assignment PIN_U23 -to HEX1[5]
set_location_assignment PIN_U24 -to HEX1[6]

# HEX2
set_location_assignment PIN_AA25 -to HEX2[0]
set_location_assignment PIN_AA26 -to HEX2[1]
set_location_assignment PIN_Y25  -to HEX2[2]
set_location_assignment PIN_W26  -to HEX2[3]
set_location_assignment PIN_Y26  -to HEX2[4]
set_location_assignment PIN_W27  -to HEX2[5]
set_location_assignment PIN_W28  -to HEX2[6]

# HEX3
set_location_assignment PIN_V21  -to HEX3[0]
set_location_assignment PIN_U21  -to HEX3[1]
set_location_assignment PIN_AB20 -to HEX3[2]
set_location_assignment PIN_AA21 -to HEX3[3]
set_location_assignment PIN_AD24 -to HEX3[4]
set_location_assignment PIN_AF23 -to HEX3[5]
set_location_assignment PIN_Y19  -to HEX3[6]

# HEX4
set_location_assignment PIN_AB19 -to HEX4[0]
set_location_assignment PIN_AA19 -to HEX4[1]
set_location_assignment PIN_AG21 -to HEX4[2]
set_location_assignment PIN_AH21 -to HEX4[3]
set_location_assignment PIN_AE19 -to HEX4[4]
set_location_assignment PIN_AF19 -to HEX4[5]
set_location_assignment PIN_AE18 -to HEX4[6]

# HEX5
set_location_assignment PIN_AD18 -to HEX5[0]
set_location_assignment PIN_AC18 -to HEX5[1]
set_location_assignment PIN_AB18 -to HEX5[2]
set_location_assignment PIN_AH19 -to HEX5[3]
set_location_assignment PIN_AG19 -to HEX5[4]
set_location_assignment PIN_AF18 -to HEX5[5]
set_location_assignment PIN_AH18 -to HEX5[6]

# HEX6
set_location_assignment PIN_AA17 -to HEX6[0]
set_location_assignment PIN_AB16 -to HEX6[1]
set_location_assignment PIN_AA16 -to HEX6[2]
set_location_assignment PIN_AB17 -to HEX6[3]
set_location_assignment PIN_AB15 -to HEX6[4]
set_location_assignment PIN_AA15 -to HEX6[5]
set_location_assignment PIN_AC17 -to HEX6[6]

# HEX7
set_location_assignment PIN_AD17 -to HEX7[0]
set_location_assignment PIN_AE17 -to HEX7[1]
set_location_assignment PIN_AG17 -to HEX7[2]
set_location_assignment PIN_AH17 -to HEX7[3]
set_location_assignment PIN_AF17 -to HEX7[4]
set_location_assignment PIN_AG18 -to HEX7[5]
set_location_assignment PIN_AA14 -to HEX7[6]

foreach h {HEX0 HEX1 HEX2 HEX3 HEX4 HEX5 HEX6 HEX7} {
    foreach i {0 1 2 3 4 5 6} {
        set_instance_assignment -name IO_STANDARD "2.5 V" -to ${h}[$i]
    }
}

# ─── VGA (ADV7123 DAC) ─────────────────────────────────────────────────────
# Control
set_location_assignment PIN_A12 -to VGA_CLK
set_location_assignment PIN_G13 -to VGA_HS
set_location_assignment PIN_C13 -to VGA_VS
set_location_assignment PIN_F11 -to VGA_BLANK_N
set_location_assignment PIN_C10 -to VGA_SYNC_N

# Red channel
set_location_assignment PIN_E12 -to VGA_R[0]
set_location_assignment PIN_E11 -to VGA_R[1]
set_location_assignment PIN_D10 -to VGA_R[2]
set_location_assignment PIN_F12 -to VGA_R[3]
set_location_assignment PIN_G10 -to VGA_R[4]
set_location_assignment PIN_J12 -to VGA_R[5]
set_location_assignment PIN_H8  -to VGA_R[6]
set_location_assignment PIN_H10 -to VGA_R[7]

# Green channel
set_location_assignment PIN_G8  -to VGA_G[0]
set_location_assignment PIN_G11 -to VGA_G[1]
set_location_assignment PIN_F8  -to VGA_G[2]
set_location_assignment PIN_H12 -to VGA_G[3]
set_location_assignment PIN_C8  -to VGA_G[4]
set_location_assignment PIN_B8  -to VGA_G[5]
set_location_assignment PIN_F10 -to VGA_G[6]
set_location_assignment PIN_C9  -to VGA_G[7]

# Blue channel
set_location_assignment PIN_B10 -to VGA_B[0]
set_location_assignment PIN_A10 -to VGA_B[1]
set_location_assignment PIN_C11 -to VGA_B[2]
set_location_assignment PIN_B11 -to VGA_B[3]
set_location_assignment PIN_A11 -to VGA_B[4]
set_location_assignment PIN_C12 -to VGA_B[5]
set_location_assignment PIN_D11 -to VGA_B[6]
set_location_assignment PIN_D12 -to VGA_B[7]

foreach sig {VGA_CLK VGA_HS VGA_VS VGA_BLANK_N VGA_SYNC_N} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $sig
}
foreach ch {VGA_R VGA_G VGA_B} {
    foreach i {0 1 2 3 4 5 6 7} {
        set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to ${ch}[$i]
    }
}

# ─── Done ───────────────────────────────────────────────────────────────────
puts "Pin assignments applied successfully."
