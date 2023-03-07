`ifndef UTILS_SV
`define UTILS_SV

package utils;
    // DDRを入れるとシミュレーションが遅いのでmock_ddrを使う
    parameter USE_MOCK_DDR = 0;

    // 各種メモリに予めプログラムをセットしておきたいとき
    // data memoryはmockのときのみ有効
    parameter USE_MEM_INIT_FILE = 0;
    parameter INST_MEM_INIT_FILE = "D:/cpuex/core/test/load_store_large.hex";
    parameter DATA_MEM_INIT_FILE = "D:/cpuex/core/test/fpu_mem_init.txt";

    // データメモリの諸々のサイズ 
    localparam STACK_SIZE       = 256;
    localparam HEAP_SIZE        = USE_MOCK_DDR ? 98304 : 262144;
    localparam GLOBAL_SIZE      = 1024;
    localparam BRAM_SIZE        = 16384;

    // 命令メモリのサイズ
    parameter INST_MEM_SIZE = 16384;

    // コンパイラに合わせてこのパラメータを切り替える
    parameter USE_WORD_ADDRESSING = 1;
    parameter USE_WORD_ADDRESSING_FOR_PC = 0;

    // 送受信の速度。baudrateによって決まる
    parameter CLK_PER_HALF_BIT = 39;

    typedef cache_def::cpu_req_type mem_req_t;
    typedef cache_def::cpu_result_type mem_res_t;
    
    // BRAMにwriteアクセスするための構造体
    /* verilator lint_off UNPACKED */
    typedef struct {
      bit [31:0]  waddr;
      bit [31:0]  wdata;
      bit         wenable;
    } bram_wreq_t;
    /* verilator lint_on UNPACKED */

endpackage
`endif