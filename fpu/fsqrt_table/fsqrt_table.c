#include <stdio.h>
#include <math.h>

union ufloat {
  float f;
  unsigned u;
};

int main(void) {

  FILE *fp;
  fp = fopen("fsqrt_table.txt", "w");

  //1.0~2.0の範囲
  for (int i = 0; i < 512; i++) {
    double grad = 512.0 * (sqrt((double)(513+i)/512.0) - sqrt((double)(512+i)/512.0));
    double slice = (2.0*sqrt((double)(1025+2*i)/1024.0) + sqrt((double)(513+i)/512.0) + sqrt((double)(512+i)/512.0)) / 4.0
                   - ((double)(1025+2*i)/2.0) * (sqrt((double)(513+i)/512.0) - sqrt((double)(512+i)/512.0));
    union ufloat u1;
    u1.f = (float) grad;
    union ufloat u2;
    u2.f = (float) slice;

    // 傾きの絶対値n 切片nの順番でファイルに出力
    for (int j = 0; j < 32; j++) {
      int bin = 1 & ((u1.u)>>(31-j));
      fprintf(fp, "%d", bin);
    }
    fprintf(fp, "n");
    for (int j = 0; j < 32; j++) {
      int bin = 1 & ((u2.u)>>(31-j));
      fprintf(fp, "%d", bin);
    }
    fprintf(fp, "n");
  }

  //2.0~4.0の範囲
  for (int i = 0; i < 512; i++) {
    double grad = 256.0 * (sqrt((double)(513+i)/256.0) - sqrt((double)(512+i)/256.0));
    double slice = (2.0*sqrt((double)(1025+2*i)/512.0) + sqrt((double)(513+i)/256.0) + sqrt((double)(512+i)/256.0)) / 4.0
                   - ((double)(1025+2*i)/2.0) * (sqrt((double)(513+i)/256.0) - sqrt((double)(512+i)/256.0));
    union ufloat u1;
    u1.f = (float) grad;
    union ufloat u2;
    u2.f = (float) slice;

    // 傾きの絶対値n 切片nの順番でファイルに出力
    for (int j = 0; j < 32; j++) {
      int bin = 1 & ((u1.u)>>(31-j));
      fprintf(fp, "%d", bin);
    }
    fprintf(fp, "n");
    for (int j = 0; j < 32; j++) {
      int bin = 1 & ((u2.u)>>(31-j));
      fprintf(fp, "%d", bin);
    }
    fprintf(fp, "n");
  }

  fclose(fp);

  return 0;
}
