(* 覗き穴最適化 *)

open Asm

let rec g = function  (* 命令列の覗き穴最適化 *)
  | Let((x, tx), Addi(y, i), Let((z, tz), Ld(x', 0), e)) when V(x) = x' ->
      Let((x, tx), Addi(y, i), Let((z, tz), Ld(y, i), g e))
  | Let((x, tx), Addi(y, i), Let((z, tz), LdDF(x', 0), e)) when V(x) = x' ->
      Let((x, tx), Addi(y, i), Let((z, tz), LdDF(y, i), g e))
  | Let((x, tx), Addi(y, i), Let((u, tu), St(z, x', 0), e)) when V(x) = x' ->
      Let((x, tx), Addi(y, i), Let((u, tu), St(z, y, i), g e))
  | Let((x, tx), Addi(y, i), Let((u, tu), StDF(z, x', 0), e)) when V(x) = x' ->
      Let((x, tx), Addi(y, i), Let((u, tu), StDF(z, y, i), g e))
  | Ans(exp) -> Ans(g' exp)
  | Let(xt, exp, e) -> Let(xt, g' exp, g e)

and g' = function  (* 各命令の覗き穴最適化 *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g e1, g e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g e1, g e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g e1, g e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g e1, g e2)
  | exp -> exp

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =  (* トップレベル関数の覗き穴最適化 *)
  { name = l; args = xs; fargs = ys; body = g e; ret = t }

let f (Prog(fundefs, e)) =  (* プログラム全体の覗き穴最適化 *)
  Prog(List.map h fundefs, g e)
