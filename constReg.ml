(* 全体的に改善の余地あり *)
(* Asm用の定数畳み込みを書くこと *)
  (* 以下のMovを消すようにする *)

(* Set(7) *)
(* Mov($7) *)
(* どっちが良いか *)
(* MovをSetに変換 *)


(* 定数レジスタの活用 *)
(* いまはゼロレジスタのみ *)
(* その後、小数もどうしようか *)

open Asm

let findi x env = match x with
  | V(x') -> 
      (match M.find_opt x' env with 
      | Some(Set(i)) when List.mem_assoc i regs_const -> C(i) 
      | _ -> x)
  | C(_) -> x
(* findじゃなくてfind_optなのは、$gpとか最初envに入ってなさそうなので *)
(* fundefの引数もそうか *)
let findf x env = match x with
  | W(x') ->
      (match M.find_opt x' env with
      | Some(FSetD(f)) when List.mem_assoc f fregs_const -> D(f)
      | _ -> x)
  | D(_) -> x

let rec g env = function  (* 命令列の定数レジスタ活用 *)
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), exp, e) ->
      let exp' = g' env exp in
      let e' = if is_reg x (* x = reg_hp *) (* is_reg x ????, 破壊的代入される変数 *) then g env e  (* 破壊的代入される変数は環境に加えない *)
               else g (M.add x exp' env) e in
      Let((x, t), exp', e')

and g' env = function  (* 各命令の定数レジスタ活用 *)
  | Mov(x) -> Mov(findi x env)
  | Add(x, y) -> Add(findi x env, findi y env)
  | Addi(x, i) -> Addi(findi x env, i)
  | Sub(x, y) -> Sub(findi x env, findi y env)
  | Mul(x, y) -> Mul(findi x env, findi y env)
  | Div(x, y) -> Div(findi x env, findi y env)
  | SLL(x, i) -> SLL(findi x env, i)
  | SRA(x, i) -> SRA(findi x env, i)
  | FMovD(x) -> FMovD(findf x env)
  | FNegD(x) -> FNegD(findf x env)
  | FAddD(x, y) -> FAddD(findf x env, findf y env)
  | FSubD(x, y) -> FSubD(findf x env, findf y env)
  | FMulD(x, y) -> FMulD(findf x env, findf y env)
  | FInv(x) -> FInv(findf x env)
  | IfEq(x, y, e1, e2) -> IfEq(findi x env, findi y env, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(findi x env, findi y env, g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(findf x env, findf y env, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(findf x env, findf y env, g env e1, g env e2)
  | Out(x) -> Out(findi x env)
  | OutInt(x) -> OutInt(findi x env)
  | FAbs(x) -> FAbs(findf x env)
  | FSqrt(x) -> FSqrt(findf x env)
  | FTOI(x) -> FTOI(findf x env)
  | ITOF(x) -> ITOF(findi x env)
  | exp -> exp

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =  (* トップレベル関数の定数レジスタ活用 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) =  (* プログラム全体の定数レジスタ活用 *)
  Prog(List.map h fundefs, g M.empty e)
  
(* alpha変換が有効か *)
(* $gp等 *)
