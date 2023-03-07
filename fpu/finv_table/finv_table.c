#include <stdio.h>

union ufloat {
  float f;
  unsigned u;
};

int main(void) {

  FILE *fp;
  fp = fopen("finv_table.txt", "w");

  for (int i = 0; i < 1024; i++) {
    double grad = 1024.0 * (1024.0/(1024.0+(double)i) - 1024.0/(1025.0+(double)i));
    //double slice = 1024.0*(1.0 - (1024.0+(double)i)/(1025.0+(double)i)) + (256.0/(1024.0+(double)i) + 256/(1025.0+(double)i) + 1024/(2049+(double)(2*i)));
    double slice = 1024.0*(1.0 - (1024.0+(double)i)/(1025.0+(double)i)) + (768.0/(1024.0+(double)i) - 256/(1025.0+(double)i) + 1024/(2049+(double)(2*i)));

    union ufloat u1;
    u1.f = (float) grad;
    union ufloat u2;
    u2.f = (float) slice;

    /* 傾きの絶対値n 切片nの順番でファイルに出力 */
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
