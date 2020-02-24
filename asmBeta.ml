(* β簡約 *)
(* 各ブロックごとにしか、β簡約していない *)

open Asm

(* 置換のための関数群 *)
let find x env = try M.find x env with Not_found -> x
let findi x env = match x with V(x') -> V(find x' env) | C(_) -> x 
let findf x env = match x with W(x') -> W(find x' env) | D(_) -> x

let rec g env = function  (* 命令列のβ簡約 *)
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), exp, e) ->
      (match g' env exp with
      | Mov(V(y)) when not (is_reg x || is_reg y) ->  (* 破壊的代入がされる変数は考えない *)
          Format.eprintf "[AsmBeta] beta-reducing %s = %s@." x y;
          g (M.add x y env) e
      | FMovD(W(y)) when not (is_reg x || is_reg y) ->  (* 破壊的代入がされる変数は考えない *)
          Format.eprintf "[AsmBeta] beta-reducing %s = %s@." x y;
          g (M.add x y env) e
      | exp' ->
          let e' = g env e in
          Let((x, t), exp', e'))

and g' env = function  (* 各命令のβ簡約 *)
  | Nop -> Nop
  | Set(i) -> Set(i)
  | FSetD(f) -> FSetD(f)
  | SetL(l) -> SetL(l)
  | Mov(x) -> Mov(findi x env)
  | Add(x, y) -> Add(findi x env, findi y env)
  | Addi(x, i) -> Addi(findi x env, i)
  | Sub(x, y) -> Sub(findi x env, findi y env)
  | Mul(x, y) -> Mul(findi x env, findi y env)
  | Div(x, y) -> Div(findi x env, findi y env)
  | SLL(x, i) -> SLL(findi x env, i)
  | SRA(x, i) -> SRA(findi x env, i)
  | Ld(x, i) -> Ld(findi x env, i)
  | St(x, y, i) -> St(findi x env, findi y env, i)
  | FMovD(x) -> FMovD(findf x env)
  | FNegD(x) -> FNegD(findf x env)
  | FAddD(x, y) -> FAddD(findf x env, findf y env)
  | FSubD(x, y) -> FSubD(findf x env, findf y env)
  | FMulD(x, y) -> FMulD(findf x env, findf y env)
  | FInv(x) -> FInv(findf x env)
  | LdDF(x, i) -> LdDF(findi x env, i)
  | StDF(x, y, i) -> StDF(findf x env, findi y env, i)
  | IfEq(x, y, e1, e2) -> IfEq(findi x env, findi y env, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(findi x env, findi y env, g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(findf x env, findf y env, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(findf x env, findf y env, g env e1, g env e2)
  | CallCls(x, ys, zs) -> CallCls(find x env, List.map (fun y -> find y env) ys, List.map (fun z -> find z env) zs)
  | CallDir(l, ys, zs) -> CallDir(l, List.map (fun y -> find y env) ys, List.map (fun z -> find z env) zs)
  | Save(_) -> assert false  (* 考えるのがめんどー。どうせレジスタ割当の前だし。 *)
  | Restore(_) -> assert false  (* 考えるのがめんどー。どうせレジスタ割当の前だし。 *)
  | In -> In
  | Out(x) -> Out(findi x env)
  | OutInt(x) -> OutInt(findi x env)
  | FAbs(x) -> FAbs(findf x env)
  | FSqrt(x) -> FSqrt(findf x env)
  | FTOI(x) -> FTOI(findf x env)
  | ITOF(x) -> ITOF(findi x env)

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =  (* トップレベル関数のβ簡約 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) =  (* プログラム全体のβ簡約 *)
  Prog(List.map h fundefs, g M.empty e)
(* 各ブロックごとにしか、β簡約していない *)
