# cpuex_group7_core

CPU 実験 2022 年度 7 班 コア・FPU・メモリ

## 使用ソフト

Vivado v2020.2

## はじめに

以下のディレクトリ構成のうち memory, ip, vivado_project ディレクトリは著作権などの問題で削除されています。そのためこのプロジェクトをそのまま Vivado で合成することはできません。

## ディレクトリ構成

```
.
├── Makefile
├── README.md
├── vivado_project : Vivadoプロジェクトのディレクトリ
├── board.xdc : 制約ファイル
├── bram.sv : Block RAMのための汎用的なモジュール
├── config.vlt : Verilator用のconfiguration
├── core.sv
├── fpu
├── images
├── inst_mem.sv : 命令メモリ
├── io
│   ├── input_controller.sv : 入力の受け取り、バッファ、読み出し
│   ├── output_controller.sv : 出力の書き込み、バッファ、送信
│   ├── uart_buf_rx.sv : 入力を4バイトごとにまとめる
│   ├── uart_rx.sv
│   └── uart_tx.sv
├── io.md : I/O周りの仕様説明
├── io_core_controller.sv : コア、メモリ、I/Oのwrapper
├── ip : IPコアたち
├── memory
├── modules
│   ├── alu.sv : ALU(分岐演算含む)
│   ├── branch_predict.sv : 2bit飽和カウンタ分岐予測器
│   ├── control_unit.sv : 命令デコード
│   ├── imm_extend.sv : 即値符号拡張
│   └── register_file.sv : レジスタファイル
├── simulation
│   ├── sim_top.sv : Vivadoシミュ用のテストベンチ
│   └── server.sv : Vivadoシミュ用のserver.py簡易エミュレート
├── stall.md : hazardやstallについての説明
├── top.v : 全体のwrapper
└── utils.sv : 諸々のパラメタ定義など
```
