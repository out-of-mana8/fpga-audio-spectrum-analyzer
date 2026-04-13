// =============================================================================
//
//  REAL-TIME SPECTRUM ANALYZER — VGA + 7-SEGMENT VERSION
//  Target: DE2-115 (Cyclone IV E)
//
//  Pipeline: Mic → WM8731 → 256-pt FFT → VGA display + HEX + LED VU meter
//
//  VGA:    128-bin bar graph, peak hold, waterfall spectrogram
//  HEX7-4: Peak frequency (Hz, decimal)
//  HEX3-0: Peak magnitude (hex)
//  LEDR:   VU meter (audio level)
//  LEDG:   Status (PLL, codec, FFT, frame)
//
// =============================================================================


// =============================================================================
// Twiddle Factor ROM
// =============================================================================
module twiddle_rom (
    input  logic        clk,
    input  logic [6:0]  addr,
    output logic signed [15:0] cos_out,
    output logic signed [15:0] sin_out
);
    logic [31:0] rom [0:127];
    logic [31:0] data;
    initial begin
        rom[0]=32'h7FFF0000;rom[1]=32'h7FF5FCDC;rom[2]=32'h7FD8F9B8;rom[3]=32'h7FA6F696;
        rom[4]=32'h7F61F374;rom[5]=32'h7F09F055;rom[6]=32'h7E9CED38;rom[7]=32'h7E1DEA1E;
        rom[8]=32'h7D89E707;rom[9]=32'h7CE3E3F5;rom[10]=32'h7C29E0E6;rom[11]=32'h7B5CDDDD;
        rom[12]=32'h7A7CDAD8;rom[13]=32'h7989D7DA;rom[14]=32'h7884D4E1;rom[15]=32'h776BD1EF;
        rom[16]=32'h7641CF05;rom[17]=32'h7504CC21;rom[18]=32'h73B5C946;rom[19]=32'h7254C674;
        rom[20]=32'h70E2C3AA;rom[21]=32'h6F5EC0E9;rom[22]=32'h6DC9BE32;rom[23]=32'h6C23BB86;
        rom[24]=32'h6A6DB8E4;rom[25]=32'h68A6B64C;rom[26]=32'h66CFB3C1;rom[27]=32'h64E8B141;
        rom[28]=32'h62F1AECD;rom[29]=32'h60EBAC65;rom[30]=32'h5ED7AA0B;rom[31]=32'h5CB3A7BE;
        rom[32]=32'h5A82A57E;rom[33]=32'h5842A34D;rom[34]=32'h55F5A129;rom[35]=32'h539B9F15;
        rom[36]=32'h51339D0F;rom[37]=32'h4EBF9B18;rom[38]=32'h4C3F9931;rom[39]=32'h49B4975A;
        rom[40]=32'h471C9593;rom[41]=32'h447A93DD;rom[42]=32'h41CE9237;rom[43]=32'h3F1790A2;
        rom[44]=32'h3C568F1E;rom[45]=32'h398C8DAC;rom[46]=32'h36BA8C4B;rom[47]=32'h33DF8AFC;
        rom[48]=32'h30FB89BF;rom[49]=32'h2E118895;rom[50]=32'h2B1F877C;rom[51]=32'h28268677;
        rom[52]=32'h25288584;rom[53]=32'h222384A4;rom[54]=32'h1F1A83D7;rom[55]=32'h1C0B831D;
        rom[56]=32'h18F98277;rom[57]=32'h15E281E3;rom[58]=32'h12C88164;rom[59]=32'h0FAB80F7;
        rom[60]=32'h0C8C809F;rom[61]=32'h096A805A;rom[62]=32'h06488028;rom[63]=32'h0324800B;
        rom[64]=32'h00008001;rom[65]=32'hFCDC800B;rom[66]=32'hF9B88028;rom[67]=32'hF696805A;
        rom[68]=32'hF374809F;rom[69]=32'hF05580F7;rom[70]=32'hED388164;rom[71]=32'hEA1E81E3;
        rom[72]=32'hE7078277;rom[73]=32'hE3F5831D;rom[74]=32'hE0E683D7;rom[75]=32'hDDDD84A4;
        rom[76]=32'hDAD88584;rom[77]=32'hD7DA8677;rom[78]=32'hD4E1877C;rom[79]=32'hD1EF8895;
        rom[80]=32'hCF0589BF;rom[81]=32'hCC218AFC;rom[82]=32'hC9468C4B;rom[83]=32'hC6748DAC;
        rom[84]=32'hC3AA8F1E;rom[85]=32'hC0E990A2;rom[86]=32'hBE329237;rom[87]=32'hBB8693DD;
        rom[88]=32'hB8E49593;rom[89]=32'hB64C975A;rom[90]=32'hB3C19931;rom[91]=32'hB1419B18;
        rom[92]=32'hAECD9D0F;rom[93]=32'hAC659F15;rom[94]=32'hAA0BA129;rom[95]=32'hA7BEA34D;
        rom[96]=32'hA57EA57E;rom[97]=32'hA34DA7BE;rom[98]=32'hA129AA0B;rom[99]=32'h9F15AC65;
        rom[100]=32'h9D0FAECD;rom[101]=32'h9B18B141;rom[102]=32'h9931B3C1;rom[103]=32'h975AB64C;
        rom[104]=32'h9593B8E4;rom[105]=32'h93DDBB86;rom[106]=32'h9237BE32;rom[107]=32'h90A2C0E9;
        rom[108]=32'h8F1EC3AA;rom[109]=32'h8DACC674;rom[110]=32'h8C4BC946;rom[111]=32'h8AFCCC21;
        rom[112]=32'h89BFCF05;rom[113]=32'h8895D1EF;rom[114]=32'h877CD4E1;rom[115]=32'h8677D7DA;
        rom[116]=32'h8584DAD8;rom[117]=32'h84A4DDDD;rom[118]=32'h83D7E0E6;rom[119]=32'h831DE3F5;
        rom[120]=32'h8277E707;rom[121]=32'h81E3EA1E;rom[122]=32'h8164ED38;rom[123]=32'h80F7F055;
        rom[124]=32'h809FF374;rom[125]=32'h805AF696;rom[126]=32'h8028F9B8;rom[127]=32'h800BFCDC;
    end
    always_ff @(posedge clk) data <= rom[addr];
    assign cos_out = data[31:16];
    assign sin_out = data[15:0];
endmodule


// =============================================================================
// I2C Master
// =============================================================================
module i2c_master (
    input  logic clk, rst_n, start,
    input  logic [6:0] slave_addr,
    input  logic [15:0] data,
    output logic done, busy,
    output logic i2c_sclk,
    inout  wire  i2c_sdat
);
    localparam CLK_DIV=200, HALF=100, QUARTER=50;
    logic sda_out, sda_oe;
    assign i2c_sdat = sda_oe ? sda_out : 1'bz;
    typedef enum logic [3:0] {
        S_IDLE,S_START,S_BYTE0,S_ACK0,S_BYTE1,S_ACK1,S_BYTE2,S_ACK2,S_STOP,S_DONE
    } state_t;
    state_t state;
    logic [7:0] shift_reg, phase_cnt;
    logic [2:0] bit_cnt;
    logic [23:0] tx_data;
    assign busy=(state!=S_IDLE);
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin state<=S_IDLE;i2c_sclk<=1;sda_out<=1;sda_oe<=1;done<=0;phase_cnt<=0;bit_cnt<=0; end
        else begin done<=0;
            case(state)
                S_IDLE: begin i2c_sclk<=1;sda_out<=1;sda_oe<=1;
                    if(start) begin tx_data<={slave_addr,1'b0,data};phase_cnt<=0;state<=S_START; end end
                S_START: begin phase_cnt<=phase_cnt+1;
                    if(phase_cnt<HALF) begin i2c_sclk<=1;sda_out<=1; end
                    else if(phase_cnt<CLK_DIV) sda_out<=0;
                    else begin i2c_sclk<=0;phase_cnt<=0;bit_cnt<=7;shift_reg<=tx_data[23:16];state<=S_BYTE0; end end
                S_BYTE0,S_BYTE1,S_BYTE2: begin phase_cnt<=phase_cnt+1;sda_oe<=1;
                    if(phase_cnt==0) sda_out<=shift_reg[7];
                    else if(phase_cnt==QUARTER) i2c_sclk<=1;
                    else if(phase_cnt==QUARTER+HALF) i2c_sclk<=0;
                    else if(phase_cnt>=CLK_DIV-1) begin phase_cnt<=0;shift_reg<={shift_reg[6:0],1'b0};
                        if(bit_cnt==0) case(state)
                            S_BYTE0:state<=S_ACK0; S_BYTE1:state<=S_ACK1; default:state<=S_ACK2;
                        endcase else bit_cnt<=bit_cnt-1; end end
                S_ACK0,S_ACK1,S_ACK2: begin phase_cnt<=phase_cnt+1;
                    if(phase_cnt==0) sda_oe<=0;
                    else if(phase_cnt==QUARTER) i2c_sclk<=1;
                    else if(phase_cnt==QUARTER+HALF) i2c_sclk<=0;
                    else if(phase_cnt>=CLK_DIV-1) begin phase_cnt<=0;sda_oe<=1;bit_cnt<=7;
                        case(state)
                            S_ACK0: begin shift_reg<=tx_data[15:8];state<=S_BYTE1; end
                            S_ACK1: begin shift_reg<=tx_data[7:0];state<=S_BYTE2; end
                            default: begin sda_out<=0;state<=S_STOP; end
                        endcase end end
                S_STOP: begin phase_cnt<=phase_cnt+1;sda_oe<=1;
                    if(phase_cnt==0) begin sda_out<=0;i2c_sclk<=0; end
                    else if(phase_cnt==QUARTER) i2c_sclk<=1;
                    else if(phase_cnt==QUARTER+HALF) sda_out<=1;
                    else if(phase_cnt>=CLK_DIV-1) state<=S_DONE; end
                S_DONE: begin done<=1;state<=S_IDLE; end
                default: state<=S_IDLE;
            endcase end
    end
endmodule


// =============================================================================
// WM8731 Init
// =============================================================================
module wm8731_init (
    input logic clk, rst_n, output logic config_done,
    output logic i2c_sclk, inout wire i2c_sdat
);
    logic i2c_start,i2c_done,i2c_busy; logic [15:0] i2c_data;
    i2c_master u_i2c(.clk(clk),.rst_n(rst_n),.start(i2c_start),.slave_addr(7'b0011010),
        .data(i2c_data),.done(i2c_done),.busy(i2c_busy),.i2c_sclk(i2c_sclk),.i2c_sdat(i2c_sdat));
    localparam N=11; logic [15:0] tbl[0:N-1];
    assign tbl[0]=16'h1E00; assign tbl[1]=16'h0017; assign tbl[2]=16'h0217;
    assign tbl[3]=16'h0479; assign tbl[4]=16'h0679; assign tbl[5]=16'h0815;
    assign tbl[6]=16'h0A00; assign tbl[7]=16'h0C00; assign tbl[8]=16'h0E42;
    assign tbl[9]=16'h1000; assign tbl[10]=16'h1201;
    typedef enum logic [2:0] {W,S,D,NX,FIN} st_t;
    st_t st; logic [3:0] idx; logic [19:0] dly;
    assign config_done=(st==FIN);
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin st<=W;idx<=0;dly<=0;i2c_start<=0;i2c_data<=0; end
        else begin i2c_start<=0;
            case(st)
                W: begin dly<=dly+1; if(dly>=1000000) st<=S; end
                S: if(!i2c_busy) begin i2c_data<=tbl[idx];i2c_start<=1;st<=D; end
                D: if(i2c_done) begin st<=NX;dly<=0; end
                NX: begin dly<=dly+1; if(dly>=10000) begin
                    if(idx<N-1) begin idx<=idx+1;st<=S; end else st<=FIN; end end
                FIN: ;
            endcase end
    end
endmodule


// =============================================================================
// I2S Capture
// =============================================================================
module i2s_capture #(parameter FFT_SIZE=256) (
    input logic clk,rst_n,enable,
    input logic aud_bclk,aud_adclrck,aud_adcdat,
    output logic sample_valid, output logic signed [15:0] sample_data,
    output logic frame_ready, input logic [7:0] frame_addr,
    output logic signed [15:0] frame_data
);
    logic [2:0] bs,ls,ds;
    always_ff @(posedge clk) begin bs<={bs[1:0],aud_bclk};ls<={ls[1:0],aud_adclrck};ds<={ds[1:0],aud_adcdat}; end
    wire br=(bs[2:1]==2'b01),lrck=ls[2],dat=ds[2];
    typedef enum logic [2:0] {IDLE,WAIT_L,SKIP,CAP,DONE} st_t;
    st_t st; logic [15:0] sr; logic [4:0] bc; logic lp;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin st<=IDLE;sr<=0;bc<=0;sample_valid<=0;sample_data<=0;lp<=1; end
        else begin sample_valid<=0;lp<=lrck;
            case(st)
                IDLE: if(enable) st<=WAIT_L;
                WAIT_L: if(lp&&!lrck) st<=SKIP;
                SKIP: if(br) begin st<=CAP;bc<=15; end
                CAP: if(br) begin sr<={sr[14:0],dat}; if(bc==0) st<=DONE; else bc<=bc-1; end
                DONE: begin sample_data<=sr;sample_valid<=1;st<=WAIT_L; end
            endcase end
    end
    function [7:0] bitrev(input [7:0] x);
        bitrev={x[0],x[1],x[2],x[3],x[4],x[5],x[6],x[7]};
    endfunction
    logic signed [15:0] fbuf[0:FFT_SIZE-1]; logic [7:0] scnt;
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin scnt<=0;frame_ready<=0; end
        else begin frame_ready<=0;
            if(sample_valid&&enable) begin fbuf[bitrev(scnt)]<=sample_data;
                if(scnt==FFT_SIZE-1) begin scnt<=0;frame_ready<=1; end else scnt<=scnt+1; end end
    end
    always_ff @(posedge clk) frame_data<=fbuf[frame_addr];
endmodule


// =============================================================================
// FFT Engine
// =============================================================================
module fft_core #(parameter N=256, STAGES=8) (
    input logic clk,rst_n,start, output logic done,busy,
    output logic [7:0] load_addr, input logic signed [15:0] load_data,
    output logic mag_valid, output logic [6:0] mag_addr, output logic [15:0] mag_data
);
    logic signed [31:0] ram_re[0:N-1],ram_im[0:N-1];
    logic [6:0] tw_addr; logic signed [15:0] tw_cos,tw_sin;
    twiddle_rom u_tw(.clk(clk),.addr(tw_addr),.cos_out(tw_cos),.sin_out(tw_sin));
    logic signed [31:0] ar,ai,br,bi;
    logic signed [47:0] prr,pri,pir,pii;
    logic signed [31:0] wbr,wbi,oar,oai,obr,obi;
    assign prr=(tw_cos*br);assign pri=(tw_sin*bi);
    assign pir=(tw_cos*bi);assign pii=(tw_sin*br);
    assign wbr=(prr-pri)>>>15;assign wbi=(pir+pii)>>>15;
    assign oar=(ar+wbr)>>>1;assign oai=(ai+wbi)>>>1;
    assign obr=(ar-wbr)>>>1;assign obi=(ai-wbi)>>>1;
    typedef enum logic [3:0] {
        F_IDLE,F_LOAD,F_SINIT,F_RA,F_RB,F_TW,F_CMP,F_WR,F_NXT,F_MAG,F_DONE
    } fst_t;
    fst_t fs; logic [3:0] stg; logic [7:0] blk,bfy,hsz,nblk,itop,ibot;
    logic [8:0] bsz,lcnt; logic [6:0] mcnt;
    assign busy=(fs!=F_IDLE);
    always_ff @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin fs<=F_IDLE;done<=0;mag_valid<=0;load_addr<=0;tw_addr<=0;
            stg<=0;blk<=0;bfy<=0;lcnt<=0;mcnt<=0; end
        else begin done<=0;mag_valid<=0;
            case(fs)
                F_IDLE: if(start) begin lcnt<=0;load_addr<=0;fs<=F_LOAD; end
                F_LOAD: begin
                    if(lcnt>0) begin ram_re[lcnt-1]<={{16{load_data[15]}},load_data};ram_im[lcnt-1]<=0; end
                    if(lcnt==N) begin fs<=F_SINIT;stg<=0; end
                    else begin load_addr<=lcnt[7:0];lcnt<=lcnt+1; end end
                F_SINIT: begin hsz<=8'd1<<stg;bsz<=9'd1<<(stg+1);nblk<=N>>(stg+1);
                    blk<=0;bfy<=0;fs<=F_RA; end
                F_RA: begin itop<=blk*bsz[7:0]+bfy;ibot<=blk*bsz[7:0]+bfy+hsz;fs<=F_RB; end
                F_RB: begin ar<=ram_re[itop];ai<=ram_im[itop];br<=ram_re[ibot];bi<=ram_im[ibot];
                    tw_addr<=bfy[6:0]<<(STAGES-1-stg);fs<=F_TW; end
                F_TW: fs<=F_CMP;
                F_CMP: fs<=F_WR;
                F_WR: begin ram_re[itop]<=oar;ram_im[itop]<=oai;
                    ram_re[ibot]<=obr;ram_im[ibot]<=obi;fs<=F_NXT; end
                F_NXT: begin
                    if(bfy<hsz-1) begin bfy<=bfy+1;fs<=F_RA; end
                    else if(blk<nblk-1) begin blk<=blk+1;bfy<=0;fs<=F_RA; end
                    else if(stg<STAGES-1) begin stg<=stg+1;fs<=F_SINIT; end
                    else begin mcnt<=0;fs<=F_MAG; end end
                F_MAG: begin
                    logic signed [31:0] rv,iv; logic [31:0] are,aim,mx,mn,mg;
                    rv=ram_re[mcnt];iv=ram_im[mcnt];
                    are=(rv<0)?-rv:rv;aim=(iv<0)?-iv:iv;
                    mx=(are>aim)?are:aim;mn=(are>aim)?aim:are;
                    mg=mx+(mn>>2);
                    mag_addr<=mcnt;mag_data<=(mg>32'hFFFF)?16'hFFFF:mg[15:0];mag_valid<=1;
                    if(mcnt==127) fs<=F_DONE; else mcnt<=mcnt+1; end
                F_DONE: begin done<=1;fs<=F_IDLE; end
                default: fs<=F_IDLE;
            endcase end
    end
endmodule


// =============================================================================
// 7-Segment Hex Decoder (active low segments for DE2-115)
// =============================================================================
module hex_display (
    input  logic [3:0] val,
    output logic [6:0] seg
);
    always_comb begin
        case (val)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
        endcase
    end
endmodule


// =============================================================================
// PLL wrapper — 50 MHz → 12.288 MHz audio MCLK
// =============================================================================
module audio_pll (
    input  wire clk_in,
    output wire clk_12m,
    output wire locked
);
    pll_audio u_pll (
        .inclk0 (clk_in),
        .c0     (clk_12m),
        .locked (locked)
    );
endmodule


// =============================================================================
// Top Level
// =============================================================================
module spectrum_analyzer_top (
    input  logic        CLOCK_50,
    input  logic [3:0]  KEY,
    // Audio
    output logic        AUD_XCK,
    input  logic        AUD_BCLK,
    input  logic        AUD_ADCLRCK,
    input  logic        AUD_ADCDAT,
    output logic        AUD_DACLRCK,
    output logic        AUD_DACDAT,
    // I2C
    output logic        I2C_SCLK,
    inout  wire         I2C_SDAT,
    // 7-Segment displays
    output logic [6:0]  HEX0, HEX1, HEX2, HEX3,
    output logic [6:0]  HEX4, HEX5, HEX6, HEX7,
    // LEDs
    output logic [7:0]  LEDG,
    output logic [17:0] LEDR,
    // VGA
    output logic        VGA_CLK,
    output logic        VGA_HS,
    output logic        VGA_VS,
    output logic        VGA_BLANK_N,
    output logic        VGA_SYNC_N,
    output logic [7:0]  VGA_R,
    output logic [7:0]  VGA_G,
    output logic [7:0]  VGA_B
);

    // ── Reset ─────────────────────────────────────────────────────────────
    logic rst_n;
    logic [2:0] rst_sync;
    always_ff @(posedge CLOCK_50) rst_sync<={rst_sync[1:0],KEY[0]};
    assign rst_n=rst_sync[2];

    // ── PLL ───────────────────────────────────────────────────────────────
    logic clk_12, pll_locked;
    audio_pll u_pll(.clk_in(CLOCK_50),.clk_12m(clk_12),.locked(pll_locked));
    assign AUD_XCK=clk_12;
    assign AUD_DACDAT=AUD_ADCDAT;       // Loopback: mic → headphone
    assign AUD_DACLRCK=AUD_ADCLRCK;

    // ── CODEC Init ────────────────────────────────────────────────────────
    logic codec_ready;
    wm8731_init u_codec(.clk(CLOCK_50),.rst_n(rst_n & pll_locked),
        .config_done(codec_ready),.i2c_sclk(I2C_SCLK),.i2c_sdat(I2C_SDAT));

    // ── I2S Capture ───────────────────────────────────────────────────────
    logic sample_valid, frame_ready;
    logic signed [15:0] sample_data;
    logic [7:0] frame_rd_addr;
    logic signed [15:0] frame_rd_data;
    i2s_capture #(.FFT_SIZE(256)) u_i2s(
        .clk(CLOCK_50),.rst_n(rst_n),.enable(codec_ready),
        .aud_bclk(AUD_BCLK),.aud_adclrck(AUD_ADCLRCK),.aud_adcdat(AUD_ADCDAT),
        .sample_valid(sample_valid),.sample_data(sample_data),
        .frame_ready(frame_ready),.frame_addr(frame_rd_addr),.frame_data(frame_rd_data));

    // ── FFT ───────────────────────────────────────────────────────────────
    logic fft_start, fft_done, fft_busy;
    logic mag_valid; logic [6:0] mag_addr; logic [15:0] mag_data;
    fft_core #(.N(256),.STAGES(8)) u_fft(
        .clk(CLOCK_50),.rst_n(rst_n),.start(fft_start),.done(fft_done),.busy(fft_busy),
        .load_addr(frame_rd_addr),.load_data(frame_rd_data),
        .mag_valid(mag_valid),.mag_addr(mag_addr),.mag_data(mag_data));

    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if(!rst_n) fft_start<=0; else fft_start<=frame_ready & ~fft_busy;
    end

    // ── Peak Detector ─────────────────────────────────────────────────────
    logic [6:0]  peak_bin;
    logic [15:0] peak_mag;
    logic [6:0]  peak_bin_hold;
    logic [15:0] peak_mag_hold;
    logic [15:0] peak_freq_hold;

    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if (!rst_n) begin
            peak_bin<=0; peak_mag<=0;
            peak_bin_hold<=0; peak_mag_hold<=0; peak_freq_hold<=0;
        end else begin
            if (fft_start) begin
                peak_bin_hold  <= peak_bin;
                peak_mag_hold  <= peak_mag;
                peak_freq_hold <= peak_bin * 16'd188;
                peak_bin <= 0;
                peak_mag <= 0;
            end
            if (mag_valid && mag_addr > 0) begin
                if (mag_data > peak_mag) begin
                    peak_mag <= mag_data;
                    peak_bin <= mag_addr;
                end
            end
        end
    end

    // ── BCD conversion ────────────────────────────────────────────────────
    function [19:0] bin2bcd(input [15:0] bin);
        integer i;
        logic [35:0] s;
        s = {20'd0, bin};
        for (i = 0; i < 16; i++) begin
            if (s[19:16] >= 5) s[19:16] = s[19:16] + 3;
            if (s[23:20] >= 5) s[23:20] = s[23:20] + 3;
            if (s[27:24] >= 5) s[27:24] = s[27:24] + 3;
            if (s[31:28] >= 5) s[31:28] = s[31:28] + 3;
            if (s[35:32] >= 5) s[35:32] = s[35:32] + 3;
            s = s << 1;
        end
        bin2bcd = s[35:16];
    endfunction

    logic [19:0] freq_bcd;
    assign freq_bcd = bin2bcd(peak_freq_hold);

    // ── 7-Segment Displays ────────────────────────────────────────────────
    hex_display d7(.val(freq_bcd[19:16]), .seg(HEX7));
    hex_display d6(.val(freq_bcd[15:12]), .seg(HEX6));
    hex_display d5(.val(freq_bcd[11:8]),  .seg(HEX5));
    hex_display d4(.val(freq_bcd[7:4]),   .seg(HEX4));
    hex_display d3(.val(peak_mag_hold[15:12]), .seg(HEX3));
    hex_display d2(.val(peak_mag_hold[11:8]),  .seg(HEX2));
    hex_display d1(.val(peak_mag_hold[7:4]),   .seg(HEX1));
    hex_display d0(.val(peak_mag_hold[3:0]),   .seg(HEX0));

    // ── Status LEDs ───────────────────────────────────────────────────────
    assign LEDG[0]=pll_locked;
    assign LEDG[1]=codec_ready;
    assign LEDG[2]=fft_busy;
    assign LEDG[7:4]=0;

    logic [19:0] flc;
    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if(!rst_n) flc<=0; else if(frame_ready) flc<='1; else if(|flc) flc<=flc-1;
    end
    assign LEDG[3]=|flc;

    // ── VU Meter on Red LEDs ──────────────────────────────────────────────
    logic [15:0] abs_s, pk; logic [19:0] pd;
    assign abs_s=sample_data[15]?-sample_data:sample_data;
    always_ff @(posedge CLOCK_50 or negedge rst_n) begin
        if(!rst_n) begin pk<=0;pd<=0; end
        else if(sample_valid) begin
            if(abs_s>pk) pk<=abs_s;
            else if(pd==0) begin pd<=50000; if(pk>0) pk<=pk-1; end
            else pd<=pd-1;
        end
    end
    always_comb begin
        LEDR=0;
        if(pk>64) LEDR[0]=1;    if(pk>128) LEDR[1]=1;
        if(pk>256) LEDR[2]=1;   if(pk>512) LEDR[3]=1;
        if(pk>1024) LEDR[4]=1;  if(pk>1536) LEDR[5]=1;
        if(pk>2048) LEDR[6]=1;  if(pk>3072) LEDR[7]=1;
        if(pk>4096) LEDR[8]=1;  if(pk>5120) LEDR[9]=1;
        if(pk>6144) LEDR[10]=1; if(pk>8192) LEDR[11]=1;
        if(pk>10240) LEDR[12]=1;if(pk>12288) LEDR[13]=1;
        if(pk>16384) LEDR[14]=1;if(pk>24576) LEDR[15]=1;
        if(pk>28672) LEDR[16]=1;if(pk>32000) LEDR[17]=1;
    end

    // ── VGA Spectrum Display ──────────────────────────────────────────────
    // Instantiate the VHDL entity (Quartus handles mixed SV + VHDL)
    vga_spectrum_display u_vga (
        .clk_50        (CLOCK_50),
        .rst_n         (rst_n),
        .fft_mag_valid (mag_valid),
        .fft_mag_addr  (mag_addr),
        .fft_mag_data  (mag_data),
        .vga_clk       (VGA_CLK),
        .vga_hs        (VGA_HS),
        .vga_vs        (VGA_VS),
        .vga_blank_n   (VGA_BLANK_N),
        .vga_sync_n    (VGA_SYNC_N),
        .vga_r         (VGA_R),
        .vga_g         (VGA_G),
        .vga_b         (VGA_B)
    );

endmodule
