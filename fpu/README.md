# FPUについてのまとめ

## パイプライン段数
120MHzでタイミング的に余裕をもって動作する段数とした。

| モジュール | 段数 |
| ----------| -----|
|fadd, fsub| 5|
|fmul | 2|
|finv| 8|
|fdiv|11|
|fsqrt|8|
|fhalf|1|
|fcvtws|2|
|fcvtsw|4|
|ffloor|8|
|flt|1|
|fmadd, fmsub|7|


ストールすべきクロック数は「段数-1」クロック

## テスト関数の使い方
`test`ディレクトリ下にtest_f---.svファイルがある。これらを用いてFPUの各モジュールが実装基準を満たしていることを検証するためには、Vivadoのコマンドプロンプト上で以下のコマンドを打てばよい。
```
$ xvlog --sv test_f---.sv f---.sv f===.sv
$ xelab -debug typical test_f--- -s test_f---.sim
$ xsim -runall test_f---.sim
```
ここで、f===はf---内でインスタンス化されるモジュールである。
例えば、fdivの場合次のようになる。
```
$ xvlog --sv test_fdiv.sv fdiv.sv fmul.sv fsub.sv
$ xelab -debug typical test_fdiv -s test_fdiv.sim
$ xsim -runall test_fdiv.sim
```
以上のコマンドを打つ過程ではVivadoにより大量のファイルが生成されるため、実際に検証する際には新たにtest_f---などのディレクトリを作成し、そこにf---.svとtest_f---.svなどをコピーしてそのディレクトリ上で実行を行うとよい。

`emu_test`には、FPUエミュレータと本ディレクトリ下の各モジュールで挙動が一致することを確かめるためのテスト関数などが置いてあり、上と同様の方法で実行できる。
