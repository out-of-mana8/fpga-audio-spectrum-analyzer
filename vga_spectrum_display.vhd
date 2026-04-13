-- =============================================================================
-- VGA Spectrum Analyzer Display
-- Target : DE2-115 (Cyclone IV E), VHDL-93 compatible
--
-- Features:
--   * 640x480 @ 60 Hz VGA output (25 MHz pixel clock from 50 MHz)
--   * 128-bin bar graph with logarithmic magnitude scaling
--   * Smooth bar animation (instant attack, gradual decay)
--   * Per-bin peak-hold markers with slow descent
--   * 128-row scrolling waterfall / spectrogram (heat-map palette)
--   * Multi-zone colour gradient on bars (blue->cyan->green->yellow->red)
--   * Horizontal reference grid lines
--   * Bright glow highlight at bar tops
--   * Dark themed background with subtle gradient
-- =============================================================================
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_spectrum_display is
    port (
        clk_50        : in  std_logic;
        rst_n         : in  std_logic;
        fft_mag_valid : in  std_logic;
        fft_mag_addr  : in  std_logic_vector(6 downto 0);
        fft_mag_data  : in  std_logic_vector(15 downto 0);
        vga_clk       : out std_logic;
        vga_hs        : out std_logic;
        vga_vs        : out std_logic;
        vga_blank_n   : out std_logic;
        vga_sync_n    : out std_logic;
        vga_r         : out std_logic_vector(7 downto 0);
        vga_g         : out std_logic_vector(7 downto 0);
        vga_b         : out std_logic_vector(7 downto 0)
    );
end entity vga_spectrum_display;

architecture rtl of vga_spectrum_display is

    -- ================================================================
    -- VGA 640x480 @ 60 Hz timing
    -- ================================================================
    constant H_VIS   : integer := 640;
    constant H_FP    : integer := 16;
    constant H_SYNC  : integer := 96;
    constant H_BP    : integer := 48;
    constant H_TOTAL : integer := 800;

    constant V_VIS   : integer := 480;
    constant V_FP    : integer := 10;
    constant V_SYNC  : integer := 2;
    constant V_BP    : integer := 33;
    constant V_TOTAL : integer := 525;

    -- ================================================================
    -- Layout constants
    -- ================================================================
    constant BAR_Y_TOP : integer := 20;
    constant BAR_Y_BOT : integer := 339;
    constant BAR_H     : integer := 320;
    constant DIV_Y_TOP : integer := 340;
    constant DIV_Y_BOT : integer := 349;
    constant WF_Y_TOP  : integer := 350;
    constant WF_Y_BOT  : integer := 477;
    constant WF_H      : integer := 128;

    -- ================================================================
    -- Divide-by-5 and mod-5 LUTs (synth-friendly, no divider)
    -- ================================================================
    type div5_lut_t is array (0 to 639) of unsigned(6 downto 0);
    function build_div5 return div5_lut_t is
        variable t : div5_lut_t;
    begin
        for i in 0 to 639 loop
            t(i) := to_unsigned(i / 5, 7);
        end loop;
        return t;
    end function;
    constant DIV5 : div5_lut_t := build_div5;

    type mod5_lut_t is array (0 to 639) of unsigned(2 downto 0);
    function build_mod5 return mod5_lut_t is
        variable t : mod5_lut_t;
    begin
        for i in 0 to 639 loop
            t(i) := to_unsigned(i mod 5, 3);
        end loop;
        return t;
    end function;
    constant MOD5 : mod5_lut_t := build_mod5;

    -- ================================================================
    -- Signals
    -- ================================================================
    signal pclk_en  : std_logic := '0';
    signal pclk_reg : std_logic := '0';

    signal hc : unsigned(9 downto 0) := (others => '0');
    signal vc : unsigned(9 downto 0) := (others => '0');
    signal hs_reg, vs_reg : std_logic := '1';
    signal blank_reg      : std_logic := '0';

    -- FFT magnitude capture
    type mag_arr is array (0 to 127) of unsigned(15 downto 0);
    signal mag_wr   : mag_arr := (others => (others => '0'));
    signal mag_disp : mag_arr := (others => (others => '0'));
    signal frame_latch : std_logic := '0';

    -- Bar heights: 0..319
    type ht_arr is array (0 to 127) of unsigned(8 downto 0);
    signal bar_target : ht_arr := (others => (others => '0'));
    signal bar_cur    : ht_arr := (others => (others => '0'));
    signal peak_val   : ht_arr := (others => (others => '0'));
    signal peak_frame_cnt : unsigned(5 downto 0) := (others => '0');

    -- Update sequencer
    signal upd_run  : std_logic := '0';
    signal upd_idx  : unsigned(7 downto 0) := (others => '0');

    -- Waterfall RAM: 128 rows x 128 cols, 8-bit
    type wf_ram_t is array (0 to 16383) of unsigned(7 downto 0);
    signal wf_ram : wf_ram_t := (others => (others => '0'));
    attribute ramstyle : string;
    attribute ramstyle of wf_ram : signal is "M9K";
    signal wf_wr_row : unsigned(6 downto 0) := (others => '0');

    -- Pixel pipeline stage 1
    signal s1_px, s1_py : unsigned(9 downto 0);
    signal s1_bin       : unsigned(6 downto 0);
    signal s1_xpos      : unsigned(2 downto 0);
    signal s1_bar_ht    : unsigned(8 downto 0);
    signal s1_peak_ht   : unsigned(8 downto 0);
    signal s1_blank     : std_logic;

    signal wf_rd_addr   : unsigned(13 downto 0);
    signal wf_rd_data   : unsigned(7 downto 0);

    signal out_r, out_g, out_b : unsigned(7 downto 0);

    -- ================================================================
    -- 4x5 pixel font ROM for axis labels
    -- Characters: 0-9, k, H, z, d, B, -, space
    -- Index = char_id * 5 + row,  bit 3 = leftmost pixel
    -- ================================================================
    type font_rom_t is array (0 to 84) of std_logic_vector(3 downto 0);
    constant FONT : font_rom_t := (
        -- '0' (0)          '1' (1)          '2' (2)
        "0110","1001","1001","1001","0110",  -- 0-4
        "0100","1100","0100","0100","1110",  -- 5-9
        "0110","1001","0010","0100","1111",  -- 10-14
        -- '3' (3)          '4' (4)          '5' (5)
        "1110","0001","0110","0001","1110",  -- 15-19
        "1001","1001","1111","0001","0001",  -- 20-24
        "1111","1000","1110","0001","1110",  -- 25-29
        -- '6' (6)          '7' (7)          '8' (8)
        "0110","1000","1110","1001","0110",  -- 30-34
        "1111","0001","0010","0100","0100",  -- 35-39
        "0110","1001","0110","1001","0110",  -- 40-44
        -- '9' (9)          'k' (10)         'H' (11)
        "0110","1001","0111","0001","0110",  -- 45-49
        "1000","1010","1100","1010","1001",  -- 50-54
        "1001","1001","1111","1001","1001",  -- 55-59
        -- 'z' (12)         'd' (13)         'B' (14)
        "1111","0010","0100","1000","1111",  -- 60-64
        "0001","0001","0111","1001","0111",  -- 65-69
        "1110","1001","1110","1001","1110",  -- 70-74
        -- '-' (15)         ' ' (16)
        "0000","0000","1110","0000","0000",  -- 75-79
        "0000","0000","0000","0000","0000"   -- 80-84
    );

    -- ================================================================
    -- Log-scale: magnitude(16-bit) -> bar height (0..319)
    --   Uses priority encoder + case statement (no variable slicing)
    --   height ~ 22 * log2(mag) with fractional interpolation
    -- ================================================================
    function log_height(m : unsigned(15 downto 0)) return unsigned is
        variable p    : integer range 0 to 15;
        variable h    : unsigned(8 downto 0);
        variable frac : unsigned(3 downto 0);
    begin
        if m < 4 then return to_unsigned(0, 9); end if;

        p := 1;
        for i in 15 downto 1 loop
            if m(i) = '1' then p := i; exit; end if;
        end loop;

        h := to_unsigned(p * 22, 9);

        -- Extract 4 fractional bits below the leading one via case
        case p is
            when 15 => frac := m(14 downto 11);
            when 14 => frac := m(13 downto 10);
            when 13 => frac := m(12 downto  9);
            when 12 => frac := m(11 downto  8);
            when 11 => frac := m(10 downto  7);
            when 10 => frac := m( 9 downto  6);
            when  9 => frac := m( 8 downto  5);
            when  8 => frac := m( 7 downto  4);
            when  7 => frac := m( 6 downto  3);
            when  6 => frac := m( 5 downto  2);
            when  5 => frac := m( 4 downto  1);
            when  4 => frac := m( 3 downto  0);
            when  3 => frac := m( 2 downto  0) & "0";
            when  2 => frac := m( 1 downto  0) & "00";
            when others => frac := (others => '0');
        end case;

        h := h + resize(frac, 9);
        if h > 319 then h := to_unsigned(319, 9); end if;
        return h;
    end function;

    -- Compress 16-bit to 8-bit (piecewise log)
    function compress8(m : unsigned(15 downto 0)) return unsigned is
        variable v : unsigned(7 downto 0);
    begin
        if m > 4095 then
            v := to_unsigned(192, 8) + resize(m(15 downto 10), 8);
        elsif m > 1023 then
            v := to_unsigned(128, 8) + resize(m(11 downto  6), 8);
        elsif m > 255 then
            v := to_unsigned(64, 8)  + resize(m( 9 downto  4), 8);
        else
            v := m(7 downto 0);
        end if;
        return v;
    end function;

    -- Saturating arithmetic helpers
    function clamp8(a : unsigned(8 downto 0)) return unsigned is
    begin
        if a > 255 then return to_unsigned(255, 8);
        else return a(7 downto 0); end if;
    end function;

    function sat_sub8(a, b : unsigned(7 downto 0)) return unsigned is
    begin
        if a > b then return resize(a - b, 8);
        else return to_unsigned(0, 8); end if;
    end function;

begin

    -- ================================================================
    -- Pixel clock: 50 MHz -> 25 MHz
    -- ================================================================
    process(clk_50, rst_n)
    begin
        if rst_n = '0' then
            pclk_en  <= '0';
            pclk_reg <= '0';
        elsif rising_edge(clk_50) then
            pclk_en  <= not pclk_en;
            pclk_reg <= not pclk_reg;
        end if;
    end process;

    vga_clk    <= pclk_reg;
    vga_sync_n <= '0';

    -- ================================================================
    -- VGA timing counters
    -- ================================================================
    process(clk_50, rst_n)
    begin
        if rst_n = '0' then
            hc <= (others => '0');
            vc <= (others => '0');
        elsif rising_edge(clk_50) then
            if pclk_en = '1' then
                if hc = H_TOTAL - 1 then
                    hc <= (others => '0');
                    if vc = V_TOTAL - 1 then
                        vc <= (others => '0');
                    else
                        vc <= vc + 1;
                    end if;
                else
                    hc <= hc + 1;
                end if;
            end if;
        end if;
    end process;

    -- Sync and blanking (active-low for DE2-115 ADV7123)
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            if pclk_en = '1' then
                if hc >= (H_VIS + H_FP) and hc < (H_VIS + H_FP + H_SYNC) then
                    hs_reg <= '0';
                else
                    hs_reg <= '1';
                end if;
                if vc >= (V_VIS + V_FP) and vc < (V_VIS + V_FP + V_SYNC) then
                    vs_reg <= '0';
                else
                    vs_reg <= '1';
                end if;
                if hc < H_VIS and vc < V_VIS then
                    blank_reg <= '1';
                else
                    blank_reg <= '0';
                end if;
            end if;
        end if;
    end process;

    vga_hs      <= hs_reg;
    vga_vs      <= vs_reg;
    vga_blank_n <= blank_reg;

    -- ================================================================
    -- FFT magnitude capture
    -- ================================================================
    process(clk_50, rst_n)
    begin
        if rst_n = '0' then
            frame_latch <= '0';
        elsif rising_edge(clk_50) then
            frame_latch <= '0';
            if fft_mag_valid = '1' then
                mag_wr(to_integer(unsigned(fft_mag_addr))) <= unsigned(fft_mag_data);
                if unsigned(fft_mag_addr) = 127 then
                    frame_latch <= '1';
                end if;
            end if;
        end if;
    end process;

    -- ================================================================
    -- Update sequencer: log heights + waterfall write (128 clocks)
    -- ================================================================
    process(clk_50, rst_n)
        variable idx   : integer range 0 to 127;
        variable waddr : unsigned(13 downto 0);
    begin
        if rst_n = '0' then
            upd_run   <= '0';
            upd_idx   <= (others => '0');
            wf_wr_row <= (others => '0');
            for i in 0 to 127 loop
                mag_disp(i)   <= (others => '0');
                bar_target(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk_50) then
            if frame_latch = '1' and upd_run = '0' then
                mag_disp  <= mag_wr;
                upd_run   <= '1';
                upd_idx   <= (others => '0');
                wf_wr_row <= wf_wr_row + 1;
            elsif upd_run = '1' then
                if upd_idx <= 127 then
                    idx := to_integer(upd_idx(6 downto 0));
                    bar_target(idx) <= log_height(mag_disp(idx));
                    waddr := wf_wr_row & upd_idx(6 downto 0);
                    wf_ram(to_integer(waddr)) <= compress8(mag_disp(idx));
                    upd_idx <= upd_idx + 1;
                else
                    upd_run <= '0';
                end if;
            end if;
        end if;
    end process;

    -- ================================================================
    -- Bar animation & peak hold (once per VGA frame at vsync)
    -- ================================================================
    process(clk_50, rst_n)
        variable vs_prev  : std_logic := '1';
        variable idx      : integer range 0 to 127;
        variable anim_run : std_logic := '0';
        variable anim_idx : unsigned(7 downto 0) := (others => '0');
    begin
        if rst_n = '0' then
            vs_prev  := '1';
            anim_run := '0';
            anim_idx := (others => '0');
            peak_frame_cnt <= (others => '0');
            for i in 0 to 127 loop
                bar_cur(i)  <= (others => '0');
                peak_val(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk_50) then
            if vs_prev = '1' and vs_reg = '0' and anim_run = '0' then
                anim_run := '1';
                anim_idx := (others => '0');
                peak_frame_cnt <= peak_frame_cnt + 1;
            end if;
            vs_prev := vs_reg;

            if anim_run = '1' then
                if anim_idx <= 127 then
                    idx := to_integer(anim_idx(6 downto 0));

                    -- Bar: instant attack, smooth 3 px/frame decay
                    if bar_target(idx) > bar_cur(idx) then
                        bar_cur(idx) <= bar_target(idx);
                    elsif bar_cur(idx) > 3 then
                        bar_cur(idx) <= bar_cur(idx) - 3;
                    else
                        bar_cur(idx) <= (others => '0');
                    end if;

                    -- Peak: update if new, decay 1 px every 4 frames
                    if bar_target(idx) > peak_val(idx) then
                        peak_val(idx) <= bar_target(idx);
                    elsif peak_frame_cnt(1 downto 0) = "00" then
                        if peak_val(idx) > 0 then
                            peak_val(idx) <= peak_val(idx) - 1;
                        end if;
                    end if;

                    anim_idx := anim_idx + 1;
                else
                    anim_run := '0';
                end if;
            end if;
        end if;
    end process;

    -- ================================================================
    -- Pixel pipeline Stage 0: bin lookup, bar read, waterfall addr
    -- ================================================================
    process(clk_50)
        variable px_int : integer range 0 to 1023;
        variable py_int : integer range 0 to 1023;
        variable bin    : unsigned(6 downto 0);
        variable wf_row : unsigned(6 downto 0);
    begin
        if rising_edge(clk_50) then
            if pclk_en = '1' then
                px_int := to_integer(hc);
                py_int := to_integer(vc);

                if px_int < 640 then
                    bin := DIV5(px_int);
                    s1_xpos <= MOD5(px_int);
                else
                    bin := (others => '0');
                    s1_xpos <= (others => '0');
                end if;
                s1_bin <= bin;

                s1_bar_ht  <= bar_cur(to_integer(bin));
                s1_peak_ht <= peak_val(to_integer(bin));

                if py_int >= WF_Y_TOP and py_int <= WF_Y_BOT then
                    wf_row := wf_wr_row - to_unsigned(py_int - WF_Y_TOP, 7);
                    wf_rd_addr <= wf_row & bin;
                else
                    wf_rd_addr <= (others => '0');
                end if;

                s1_px    <= hc;
                s1_py    <= vc;
                s1_blank <= blank_reg;
            end if;
        end if;
    end process;

    -- Registered waterfall read
    process(clk_50)
    begin
        if rising_edge(clk_50) then
            wf_rd_data <= wf_ram(to_integer(wf_rd_addr));
        end if;
    end process;

    -- ================================================================
    -- Pixel Stage 1: Colour generation
    -- Executes on alternate clock phase to let wf_rd_data settle.
    -- ================================================================
    process(clk_50)
        variable py_int      : integer range 0 to 1023;
        variable px_int      : integer range 0 to 1023;
        variable y_from_base : integer range -512 to 511;
        variable in_bar      : boolean;
        variable in_peak     : boolean;
        variable is_gap      : boolean;
        variable is_bar_zone : boolean;
        variable is_wf_zone  : boolean;
        variable is_div_zone : boolean;
        variable glow_zone   : boolean;
        variable grid_line   : boolean;
        variable bar_h_int   : integer range 0 to 511;
        variable peak_h_int  : integer range 0 to 511;
        variable t   : unsigned(7 downto 0);
        variable t9  : unsigned(8 downto 0);
        variable r, g, b : unsigned(7 downto 0);
        variable wv  : integer range 0 to 255;
        -- Label overlay
        variable lbl_on    : boolean;
        variable lbl_cid   : integer range 0 to 16;
        variable lbl_row_v : integer range 0 to 4;
        variable lbl_col_v : integer range 0 to 3;
    begin
        if rising_edge(clk_50) then
            if pclk_en = '0' then
                py_int     := to_integer(s1_py);
                px_int     := to_integer(s1_px);
                bar_h_int  := to_integer(s1_bar_ht);
                peak_h_int := to_integer(s1_peak_ht);

                is_bar_zone := (py_int >= BAR_Y_TOP) and (py_int <= BAR_Y_BOT);
                is_wf_zone  := (py_int >= WF_Y_TOP)  and (py_int <= WF_Y_BOT);
                is_div_zone := (py_int >= DIV_Y_TOP)  and (py_int <= DIV_Y_BOT);
                is_gap      := (s1_xpos = 4);

                y_from_base := BAR_Y_BOT - py_int;

                in_bar  := is_bar_zone and (not is_gap) and
                           (y_from_base >= 0) and
                           (y_from_base <= bar_h_int) and (bar_h_int > 0);

                in_peak := is_bar_zone and (not is_gap) and
                           (peak_h_int > 0) and
                           (y_from_base >= 0) and
                           (y_from_base >= peak_h_int) and
                           (y_from_base <= peak_h_int + 1);

                glow_zone := in_bar and (bar_h_int > 5) and
                             (y_from_base >= bar_h_int - 2);

                grid_line := is_bar_zone and (y_from_base >= 0) and
                             ((y_from_base = 64) or (y_from_base = 128) or
                              (y_from_base = 192) or (y_from_base = 256));

                r := (others => '0');
                g := (others => '0');
                b := (others => '0');

                if s1_blank = '0' then
                    -- Blanked
                    null;

                elsif in_peak and (not in_bar or glow_zone) then
                    -- Peak marker: bright cyan-white
                    r := to_unsigned(200, 8);
                    g := to_unsigned(255, 8);
                    b := to_unsigned(255, 8);

                elsif in_bar then
                    -- ---- Bar gradient (4 zones of 80 px) ----
                    if y_from_base < 80 then
                        -- Zone 0: dark blue -> bright blue
                        t := to_unsigned(y_from_base, 8);
                        r := (others => '0');
                        g := (others => '0');
                        b := clamp8(to_unsigned(80, 9) + resize(t, 9) + resize(t, 9));
                    elsif y_from_base < 160 then
                        -- Zone 1: blue -> cyan
                        t := to_unsigned(y_from_base - 80, 8);
                        t9 := resize(t, 9);
                        r := (others => '0');
                        g := clamp8(t9 + t9 + t9);
                        b := to_unsigned(255, 8);
                    elsif y_from_base < 240 then
                        -- Zone 2: cyan -> yellow
                        t := to_unsigned(y_from_base - 160, 8);
                        t9 := resize(t, 9);
                        r := clamp8(t9 + t9 + t9);
                        g := to_unsigned(255, 8);
                        b := sat_sub8(to_unsigned(255, 8), clamp8(t9 + t9 + t9));
                    else
                        -- Zone 3: yellow -> red
                        t := to_unsigned(y_from_base - 240, 8);
                        t9 := resize(t, 9);
                        r := to_unsigned(255, 8);
                        g := sat_sub8(to_unsigned(255, 8), clamp8(t9 + t9 + t9));
                        b := (others => '0');
                    end if;

                    -- Glow at bar top
                    if glow_zone then
                        r := clamp8(resize(r, 9) + to_unsigned(80, 9));
                        g := clamp8(resize(g, 9) + to_unsigned(80, 9));
                        b := clamp8(resize(b, 9) + to_unsigned(80, 9));
                    end if;

                elsif in_peak then
                    r := to_unsigned(200, 8);
                    g := to_unsigned(255, 8);
                    b := to_unsigned(255, 8);

                elsif is_bar_zone and grid_line and (not is_gap) then
                    r := to_unsigned(12, 8);
                    g := to_unsigned(36, 8);
                    b := to_unsigned(44, 8);

                elsif is_bar_zone then
                    -- Near-black background, slight vertical gradient
                    r := to_unsigned(3, 8);
                    g := to_unsigned(4, 8);
                    if y_from_base >= 0 then
                        b := to_unsigned(10 + y_from_base / 40, 8);
                    else
                        b := to_unsigned(10, 8);
                    end if;

                elsif is_div_zone then
                    if py_int = DIV_Y_TOP or py_int = DIV_Y_BOT then
                        r := to_unsigned(50, 8);
                        g := to_unsigned(100, 8);
                        b := to_unsigned(140, 8);
                    else
                        r := to_unsigned(6, 8);
                        g := to_unsigned(12, 8);
                        b := to_unsigned(20, 8);
                    end if;

                elsif is_wf_zone then
                    -- ---- Waterfall heat-map ----
                    wv := to_integer(wf_rd_data);
                    if wv < 32 then
                        r := (others => '0');
                        g := (others => '0');
                        b := to_unsigned(wv * 2, 8);
                    elsif wv < 96 then
                        t := to_unsigned(wv - 32, 8);
                        t9 := resize(t, 9);
                        r := (others => '0');
                        g := clamp8(t9 + t9 + t9 + t9);
                        b := clamp8(to_unsigned(64, 9) + t9 + t9 + t9);
                    elsif wv < 160 then
                        t := to_unsigned(wv - 96, 8);
                        t9 := resize(t, 9);
                        r := clamp8(t9 + t9 + t9 + t9);
                        g := to_unsigned(255, 8);
                        b := sat_sub8(to_unsigned(255, 8), clamp8(t9 + t9 + t9 + t9));
                    elsif wv < 224 then
                        t := to_unsigned(wv - 160, 8);
                        t9 := resize(t, 9);
                        r := to_unsigned(255, 8);
                        g := sat_sub8(to_unsigned(255, 8), clamp8(t9 + t9 + t9 + t9));
                        b := (others => '0');
                    else
                        t := to_unsigned(wv - 224, 8);
                        t9 := resize(t, 9);
                        r := to_unsigned(255, 8);
                        g := clamp8(t9 + t9 + t9 + t9 + t9 + t9 + t9 + t9);
                        b := clamp8(t9 + t9 + t9 + t9 + t9 + t9 + t9 + t9);
                    end if;

                else
                    r := to_unsigned(2, 8);
                    g := to_unsigned(2, 8);
                    b := to_unsigned(5, 8);
                end if;

                -- ════════════════════════════════════════════
                -- Axis label overlay (font-rendered text)
                -- ════════════════════════════════════════════
                lbl_on    := false;
                lbl_cid   := 16;   -- space
                lbl_row_v := 0;
                lbl_col_v := 0;

                -- ── X-axis: frequency labels (divider zone y=342..346) ──
                if py_int >= 342 and py_int <= 346 then
                    lbl_row_v := py_int - 342;

                    -- "0"
                    if    px_int >= 6   and px_int <= 9   then
                        lbl_cid := 0; lbl_col_v := px_int - 6;   lbl_on := true;
                    -- "5k"
                    elsif px_int >= 129 and px_int <= 132 then
                        lbl_cid := 5; lbl_col_v := px_int - 129; lbl_on := true;
                    elsif px_int >= 134 and px_int <= 137 then
                        lbl_cid := 10; lbl_col_v := px_int - 134; lbl_on := true;
                    -- "10k"
                    elsif px_int >= 258 and px_int <= 261 then
                        lbl_cid := 1; lbl_col_v := px_int - 258; lbl_on := true;
                    elsif px_int >= 263 and px_int <= 266 then
                        lbl_cid := 0; lbl_col_v := px_int - 263; lbl_on := true;
                    elsif px_int >= 268 and px_int <= 271 then
                        lbl_cid := 10; lbl_col_v := px_int - 268; lbl_on := true;
                    -- "15k"
                    elsif px_int >= 391 and px_int <= 394 then
                        lbl_cid := 1; lbl_col_v := px_int - 391; lbl_on := true;
                    elsif px_int >= 396 and px_int <= 399 then
                        lbl_cid := 5; lbl_col_v := px_int - 396; lbl_on := true;
                    elsif px_int >= 401 and px_int <= 404 then
                        lbl_cid := 10; lbl_col_v := px_int - 401; lbl_on := true;
                    -- "20k"
                    elsif px_int >= 524 and px_int <= 527 then
                        lbl_cid := 2; lbl_col_v := px_int - 524; lbl_on := true;
                    elsif px_int >= 529 and px_int <= 532 then
                        lbl_cid := 0; lbl_col_v := px_int - 529; lbl_on := true;
                    elsif px_int >= 534 and px_int <= 537 then
                        lbl_cid := 10; lbl_col_v := px_int - 534; lbl_on := true;
                    -- "kHz" unit label
                    elsif px_int >= 608 and px_int <= 611 then
                        lbl_cid := 10; lbl_col_v := px_int - 608; lbl_on := true;
                    elsif px_int >= 613 and px_int <= 616 then
                        lbl_cid := 11; lbl_col_v := px_int - 613; lbl_on := true;
                    elsif px_int >= 618 and px_int <= 621 then
                        lbl_cid := 12; lbl_col_v := px_int - 618; lbl_on := true;
                    end if;

                -- ── Y-axis: "dB" title (y=22..26) ──
                elsif py_int >= 22 and py_int <= 26 then
                    lbl_row_v := py_int - 22;
                    if    px_int >= 3 and px_int <= 6 then
                        lbl_cid := 13; lbl_col_v := px_int - 3; lbl_on := true;
                    elsif px_int >= 8 and px_int <= 11 then
                        lbl_cid := 14; lbl_col_v := px_int - 8; lbl_on := true;
                    end if;

                -- ── Y-axis: "-20" at grid line (screen y=81..85) ──
                elsif py_int >= 81 and py_int <= 85 then
                    lbl_row_v := py_int - 81;
                    if    px_int >= 1 and px_int <= 4  then
                        lbl_cid := 15; lbl_col_v := px_int - 1; lbl_on := true;
                    elsif px_int >= 6 and px_int <= 9  then
                        lbl_cid := 2;  lbl_col_v := px_int - 6; lbl_on := true;
                    elsif px_int >= 11 and px_int <= 14 then
                        lbl_cid := 0;  lbl_col_v := px_int - 11; lbl_on := true;
                    end if;

                -- ── Y-axis: "-40" at grid line (screen y=145..149) ──
                elsif py_int >= 145 and py_int <= 149 then
                    lbl_row_v := py_int - 145;
                    if    px_int >= 1 and px_int <= 4  then
                        lbl_cid := 15; lbl_col_v := px_int - 1; lbl_on := true;
                    elsif px_int >= 6 and px_int <= 9  then
                        lbl_cid := 4;  lbl_col_v := px_int - 6; lbl_on := true;
                    elsif px_int >= 11 and px_int <= 14 then
                        lbl_cid := 0;  lbl_col_v := px_int - 11; lbl_on := true;
                    end if;

                -- ── Y-axis: "-60" at grid line (screen y=209..213) ──
                elsif py_int >= 209 and py_int <= 213 then
                    lbl_row_v := py_int - 209;
                    if    px_int >= 1 and px_int <= 4  then
                        lbl_cid := 15; lbl_col_v := px_int - 1; lbl_on := true;
                    elsif px_int >= 6 and px_int <= 9  then
                        lbl_cid := 6;  lbl_col_v := px_int - 6; lbl_on := true;
                    elsif px_int >= 11 and px_int <= 14 then
                        lbl_cid := 0;  lbl_col_v := px_int - 11; lbl_on := true;
                    end if;

                -- ── Y-axis: "-80" at grid line (screen y=273..277) ──
                elsif py_int >= 273 and py_int <= 277 then
                    lbl_row_v := py_int - 273;
                    if    px_int >= 1 and px_int <= 4  then
                        lbl_cid := 15; lbl_col_v := px_int - 1; lbl_on := true;
                    elsif px_int >= 6 and px_int <= 9  then
                        lbl_cid := 8;  lbl_col_v := px_int - 6; lbl_on := true;
                    elsif px_int >= 11 and px_int <= 14 then
                        lbl_cid := 0;  lbl_col_v := px_int - 11; lbl_on := true;
                    end if;
                end if;

                -- Render label pixel (bright blue-gray text)
                if lbl_on then
                    if FONT(lbl_cid * 5 + lbl_row_v)(3 - lbl_col_v) = '1' then
                        r := to_unsigned(160, 8);
                        g := to_unsigned(185, 8);
                        b := to_unsigned(210, 8);
                    end if;
                end if;

                out_r <= r;
                out_g <= g;
                out_b <= b;
            end if;
        end if;
    end process;

    -- ================================================================
    -- VGA output
    -- ================================================================
    vga_r <= std_logic_vector(out_r);
    vga_g <= std_logic_vector(out_g);
    vga_b <= std_logic_vector(out_b);

end architecture rtl;