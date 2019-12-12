open Asm

(* FSetDはどうしよう? *)
let rec g env = function (* 命令列の16bit即値最適化 (caml2html: simm16_g) *)
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), Set(i), e) when -32768 <= i && i < 32768 -> (* 2^15 = 32768 *)
      (* Format.eprintf "found simm16 %s = %d@." x i; *)
      let e' = g (M.add x i env) e in
      if List.mem x (fv e') then Let((x, t), Set(i), e') else
      ((* Format.eprintf "erased redundant Set to %s@." x; *)
       e')
  | Let(xt, SLL(y, C(i)), e) when M.mem y env -> (* for array access *)
      (* Format.eprintf "erased redundant SLL on %s@." x; *)
      g env (Let(xt, Set((M.find y env) lsl i), e))
  | Let(xt, exp, e) -> Let(xt, g' env exp, g env e)
and g' env = function (* 各命令の16bit即値最適化 (caml2html: simm16_gprime) *)
  | Add(x, V(y)) when M.mem y env -> Add(x, C(M.find y env))
  | Add(x, V(y)) when M.mem x env -> Add(y, C(M.find x env))
  | Sub(x, V(y)) when M.mem y env -> Sub(x, C(M.find y env))
  | Mul(x, y) when (M.mem y env) && (M.find y env = 4) -> SLL(x, C(2)) (* minrt.mlの *4 に対応 *)
  | Div(x, y) when (M.mem y env) && (M.find y env = 2) -> SRA(x, 1) (* minrt.mlの /2 に対応 *)
  | SLL(x, V(y)) when M.mem y env -> SLL(x, C(M.find y env))
  | Ld(x, V(y)) when M.mem y env -> Ld(x, C(M.find y env))
  | St(x, y, V(z)) when M.mem z env -> St(x, y, C(M.find z env))
  | LdDF(x, V(y)) when M.mem y env -> LdDF(x, C(M.find y env))
  | StDF(x, y, V(z)) when M.mem z env -> StDF(x, y, C(M.find z env))
  | IfEq(x, V(y), e1, e2) when M.mem y env -> IfEq(x, C(M.find y env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem y env -> IfLE(x, C(M.find y env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem y env -> IfGE(x, C(M.find y env), g env e1, g env e2)
  | IfEq(x, V(y), e1, e2) when M.mem x env -> IfEq(y, C(M.find x env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem x env -> IfGE(y, C(M.find x env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem x env -> IfLE(y, C(M.find x env), g env e1, g env e2)
  | IfEq(x, y', e1, e2) -> IfEq(x, y', g env e1, g env e2)
  | IfLE(x, y', e1, e2) -> IfLE(x, y', g env e1, g env e2)
  | IfGE(x, y', e1, e2) -> IfGE(x, y', g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g env e1, g env e2)
  | e -> e

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の16bit即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) = (* プログラム全体の16bit即値最適化 *)
  Prog(List.map h fundefs, g M.empty e)
