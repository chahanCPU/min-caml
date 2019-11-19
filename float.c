// chahanでは、OcamlのモジュールInt32を用いたので不要

#include <stdio.h>
#include <stdint.h>
#include <caml/mlvalues.h>
#include <caml/alloc.h>
#define Float_val(v) ((float) (* (double *)(v)))    // 直接float->bit列(int32_t)にしたい

/* double-precision floating-point number to 32-bit binary */
typedef union {
  int32_t i;
  float f;
} flt;

value double_to_binary32(value v) {
  flt f;
  f.f = Float_val(v);
  return copy_int32(f.i);
}

/* double-precision floating-point number to 64-bit binary */
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
