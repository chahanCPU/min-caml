(* 全体的に改善の余地あり *)
(* Asm用の定数畳み込みを書くこと *)
  (* 以下のMovを消すようにする *)

open Asm

(* FSetDはどうしよう? *)
let rec g env = function (* 命令列の16bit即値最適化 (caml2html: simm16_g) *)
  | Ans(exp) -> Ans(g' env exp)
  (* | Let((x, t), Set(i), e) when -32768 <= i && i < 32768 -> (* 2^15 = 32768 *) *)
  | Let((x, t), Set(i), e) when -32768 < i && i < 32768 -> (* 2^15 = 32768 *) (* 引き算の即値最適化のため、-32768は含めなかった sub(x, -32768) *)
      (* Format.eprintf "found simm16 %s = %d@." x i; *)
      let e' = g (M.add x i env) e in
      if List.mem x (fv e') then Let((x, t), Set(i), e') else
      ((* Format.eprintf "erased redundant Set to %s@." x; *)
       e')
  | Let(xt, SLL(y, i), e) when M.mem y env -> (* for array access *)
      (* Format.eprintf "erased redundant SLL on %s@." x; *)
      g env (Let(xt, Set((M.find y env) lsl i), e))
  | Let(xt, exp, e) -> Let(xt, g' env exp, g env e)
and g' env = function (* 各命令の16bit即値最適化 (caml2html: simm16_gprime) *)
  (* 以下のMovを消すようにする *)
  | Add(x, y) when M.mem y env -> 
      let i = M.find y env in
      if i = 0 then Mov(x) else Addi(x, i)
  | Add(x, y) when M.mem x env -> 
      let i = M.find x env in
      if i = 0 then Mov(y) else Addi(y, i)
  | Sub(x, y) when M.mem y env -> 
      let i = M.find y env in
      if i = 0 then Mov(x) else Addi(x, -i)
  | Mul(x, y) when M.mem y env ->
      (match M.find y env with
      | 0 -> Set(0)
      | 1 -> Mov(x)
      | 2 -> SLL(x, 1)
      | 4 -> SLL(x, 2)
      | 8 -> SLL(x, 3)
      | 16 -> SLL(x, 4)
      | 32 -> SLL(x, 5)
      | 64 -> SLL(x, 6)
      | 128 -> SLL(x, 7)
      | 256 -> SLL(x, 8)
      | 512 -> SLL(x, 9)
      | 1024 -> SLL(x, 10)
      | 2048 -> SLL(x, 11)
      | 4096 -> SLL(x, 12)
      | 8192 -> SLL(x, 13)
      | 16384 -> SLL(x, 14)
      | _ -> Mul(x, y))
  | Mul(x, y) when M.mem x env ->
      (match M.find x env with
      | 0 -> Set(0)
      | 1 -> Mov(y)
      | 2 -> SLL(y, 1)
      | 4 -> SLL(y, 2)
      | 8 -> SLL(y, 3)
      | 16 -> SLL(y, 4)
      | 32 -> SLL(y, 5)
      | 64 -> SLL(y, 6)
      | 128 -> SLL(y, 7)
      | 256 -> SLL(y, 8)
      | 512 -> SLL(y, 9)
      | 1024 -> SLL(y, 10)
      | 2048 -> SLL(y, 11)
      | 4096 -> SLL(y, 12)
      | 8192 -> SLL(y, 13)
      | 16384 -> SLL(y, 14)
      | _ -> Mul(x, y))
  | Div(x, y) when M.mem y env ->
      (match M.find y env with
      | 0 -> failwith "Division_by_zero"
      | 1 -> Mov(x)
      | 2 -> SRA(x, 1)
      | 4 -> SRA(x, 2)
      | 8 -> SRA(x, 3)
      | 16 -> SRA(x, 4)
      | 32 -> SRA(x, 5)
      | 64 -> SRA(x, 6)
      | 128 -> SRA(x, 7)
      | 256 -> SRA(x, 8)
      | 512 -> SRA(x, 9)
      | 1024 -> SRA(x, 10)
      | 2048 -> SRA(x, 11)
      | 4096 -> SRA(x, 12)
      | 8192 -> SRA(x, 13)
      | 16384 -> SRA(x, 14)
      | _ -> Div(x, y))
  (* 以下のやつは今後 *)
  (* | SLL(x, V(y)) when M.mem y env -> SLL(x, C(M.find y env)) *)
  (* | Ld(x, V(y)) when M.mem y env -> Ld(x, C(M.find y env)) *)
  (* | St(x, y, V(z)) when M.mem z env -> St(x, y, C(M.find z env)) *)
  (* | LdDF(x, V(y)) when M.mem y env -> LdDF(x, C(M.find y env)) *)
  (* | StDF(x, y, V(z)) when M.mem z env -> StDF(x, y, C(M.find z env)) *)
  (* | IfEq(x, V(y), e1, e2) when M.mem y env -> IfEq(x, C(M.find y env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem y env -> IfLE(x, C(M.find y env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem y env -> IfGE(x, C(M.find y env), g env e1, g env e2)
  | IfEq(x, V(y), e1, e2) when M.mem x env -> IfEq(y, C(M.find x env), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) when M.mem x env -> IfGE(y, C(M.find x env), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) when M.mem x env -> IfLE(y, C(M.find x env), g env e1, g env e2) *)
  (* ↑C(y)の形を許さない、C(0)のときだけつくりたい *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g env e1, g env e2)
  | IfGE(x, y, e1, e2) -> IfGE(x, y, g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g env e1, g env e2)
  | e -> e

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = (* トップレベル関数の16bit即値最適化 *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) = (* プログラム全体の16bit即値最適化 *)
  Prog(List.map h fundefs, g M.empty e)

(* 何度も回す必要あり???? *)
(* 定数+定数とかはないのか。既に定数畳み込みされてる？ *)
(* gのパターンをもっと設定する必要があるのか *)
(* 特別にSetZeroを作りたい。ゼロレジスタがあるので *)
