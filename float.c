#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#define Float_val(v) ((float) (* (double *)(v)))    // 直接float->bit列(int32_t)にしたい

/* 単精度 */
typedef union {
  int32_t i;
  float f;
} flt;

value getfloat(value v) {
  flt f;
  f.f = Float_val(v);
  return copy_int32(f.i);
}

/* 倍精度 */
typedef union {
  int32_t i[2];
  double d;
} dbl;

value gethi(value v) {
  dbl d;
  d.d = Double_val(v);
  return copy_int32(d.i[0]);
}

value getlo(value v) {
  dbl d;
  d.d = Double_val(v);
  return copy_int32(d.i[1]);
}
