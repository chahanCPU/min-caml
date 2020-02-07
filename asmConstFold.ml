open Asm

let memi x env =
  try (match M.find x env with Set(_) -> true | _ -> false)
  with Not_found -> false
let memf x env =
  try (match M.find x env with FSetD(_) -> true | _ -> false)
  with Not_found -> false

let findi x env = (match M.find x env with Set(i) -> i | _ -> raise Not_found)
let findf x env = (match M.find x env with FSetD(f) -> f | _ -> raise Not_found)

let rec g env = function
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), exp, e) ->
      let exp' = g' env exp in
      let e' = g (M.add x exp' env) e in
      Let((x, t), exp', e')
and g' env = function
(* SetLは? *)
  | Mov(x) when memi x env -> Set(findi x env)
  | Neg(x) when memi x env -> Set(-(findi x env))
  | Add(x, V(y)) when memi x env && memi y env -> Set(findi x env + findi y env)
  | Add(x, V(y)) when memi x env && findi x env = 0 -> Mov(y)
  | Add(x, V(y)) when memi y env && findi y env = 0 -> Mov(x)
  | Add(x, C(y)) when memi x env -> Set(findi x env + y)
  | Add(x, C(0)) -> Mov(x)
  | Sub(x, V(y)) when memi x env && memi y env -> Set(findi x env - findi y env)
  | Sub(x, V(y)) when memi x env && findi x env = 0 -> Neg(y)
  | Sub(x, V(y)) when memi y env && findi y env = 0 -> Mov(x)
  | Sub(x, C(y)) when memi x env -> Set(findi x env - y)
  | Sub(x, C(0)) -> Mov(x)
  | Mul(x, y) when memi x env && memi y env -> Set(findi x env * findi y env)
  | Mul(x, y) when memi x env && findi x env = -1 -> Neg(y)
  | Mul(x, y) when memi x env && findi x env = 0 -> Set(0)
  | Mul(x, y) when memi x env && findi x env = 1 -> Mov(y)
  | Mul(x, y) when memi x env && findi x env = 2 -> SLL(y, C(1))
  | Mul(x, y) when memi x env && findi x env = 4 -> SLL(y, C(2))
  | Mul(x, y) when memi x env && findi x env = 8 -> SLL(y, C(3))
  | Mul(x, y) when memi x env && findi x env = 16 -> SLL(y, C(4))
  | Mul(x, y) when memi x env && findi x env = 32 -> SLL(y, C(5))
  | Mul(x, y) when memi x env && findi x env = 64 -> SLL(y, C(6))
  | Mul(x, y) when memi x env && findi x env = 128 -> SLL(y, C(7))
  | Mul(x, y) when memi x env && findi x env = 256 -> SLL(y, C(8))
  | Mul(x, y) when memi x env && findi x env = 512 -> SLL(y, C(9))
  | Mul(x, y) when memi x env && findi x env = 1024 -> SLL(y, C(10))
  | Mul(x, y) when memi x env && findi x env = 2048 -> SLL(y, C(11))
  | Mul(x, y) when memi x env && findi x env = 4096 -> SLL(y, C(12))
  | Mul(x, y) when memi x env && findi x env = 8192 -> SLL(y, C(13))
  | Mul(x, y) when memi x env && findi x env = 16384 -> SLL(y, C(14))
  | Mul(x, y) when memi x env && findi x env = 32768 -> SLL(y, C(15))
  | Mul(x, y) when memi y env && findi y env = -1 -> Neg(x)
  | Mul(x, y) when memi y env && findi y env = 0 -> Set(0)
  | Mul(x, y) when memi y env && findi y env = 1 -> Mov(x)
  | Mul(x, y) when memi y env && findi y env = 2 -> SLL(x, C(1))
  | Mul(x, y) when memi y env && findi y env = 4 -> SLL(x, C(2))
  | Mul(x, y) when memi y env && findi y env = 8 -> SLL(x, C(3))
  | Mul(x, y) when memi y env && findi y env = 16 -> SLL(x, C(4))
  | Mul(x, y) when memi y env && findi y env = 32 -> SLL(x, C(5))
  | Mul(x, y) when memi y env && findi y env = 64 -> SLL(x, C(6))
  | Mul(x, y) when memi y env && findi y env = 128 -> SLL(x, C(7))
  | Mul(x, y) when memi y env && findi y env = 256 -> SLL(x, C(8))
  | Mul(x, y) when memi y env && findi y env = 512 -> SLL(x, C(9))
  | Mul(x, y) when memi y env && findi y env = 1024 -> SLL(x, C(10))
  | Mul(x, y) when memi y env && findi y env = 2048 -> SLL(x, C(11))
  | Mul(x, y) when memi y env && findi y env = 4096 -> SLL(x, C(12))
  | Mul(x, y) when memi y env && findi y env = 8192 -> SLL(x, C(13))
  | Mul(x, y) when memi y env && findi y env = 16384 -> SLL(x, C(14))
  | Mul(x, y) when memi y env && findi y env = 32768 -> SLL(x, C(15))
  | Div(x, y) when memi y env && findi y env = 0 -> failwith "Division by zero"
  | Div(x, y) when memi x env && memi y env -> Set(findi x env / findi y env) 
  | Div(x, y) when memi x env && findi x env = 0 -> Set(0)
  | Div(x, y) when memi y env && findi y env = -1 -> Neg(x)
  | Div(x, y) when memi y env && findi y env = 1 -> Mov(x)
  | Div(x, y) when memi y env && findi y env = 2 -> SRA(x, 1)
  | Div(x, y) when memi y env && findi y env = 4 -> SRA(x, 2)
  | Div(x, y) when memi y env && findi y env = 8 -> SRA(x, 3)
  | Div(x, y) when memi y env && findi y env = 16 -> SRA(x, 4)
  | Div(x, y) when memi y env && findi y env = 32 -> SRA(x, 5)
  | Div(x, y) when memi y env && findi y env = 64 -> SRA(x, 6)
  | Div(x, y) when memi y env && findi y env = 128 -> SRA(x, 7)
  | Div(x, y) when memi y env && findi y env = 256 -> SRA(x, 8)
  | Div(x, y) when memi y env && findi y env = 512 -> SRA(x, 9)
  | Div(x, y) when memi y env && findi y env = 1024 -> SRA(x, 10)
  | Div(x, y) when memi y env && findi y env = 2048 -> SRA(x, 11)
  | Div(x, y) when memi y env && findi y env = 4096 -> SRA(x, 12)
  | Div(x, y) when memi y env && findi y env = 8192 -> SRA(x, 13)
  | Div(x, y) when memi y env && findi y env = 16384 -> SRA(x, 14)
  | Div(x, y) when memi y env && findi y env = 32768 -> SRA(x, 15)
  | SLL(x, V(y)) when memi x env && memi y env -> Set((findi x env) lsl (findi y env))
  | SLL(x, V(y)) when memi y env && findi y env = 0 -> Mov(x)
  | SLL(x, C(y)) when memi x env -> Set((findi x env) lsl y)
  | SLL(x, C(0)) -> Mov(x)
  | SRA(x, i) when memi x env -> Set((findi x env) asr i)
  | SRA(x, 0) -> Mov(x)
  (* | Ld of Id.t * id *)
  (* | St of Id.t * Id.t * id_or_imm *)
  | FMovD(x) when memf x env -> FSetD(findf x env)
  | FNegD(x) when memf x env -> FSetD(-.(findf x env))
  | FAddD(x, y) when memf x env && memf y env -> FSetD(findf x env +. findf y env)
  | FAddD(x, y) when memf x env && findf x env = 0. -> FMovD(y)
  | FAddD(x, y) when memf y env && findf y env = 0. -> FMovD(x)
  | FSubD(x, y) when memf x env && memf y env -> FSetD(findf x env -. findf y env)
  | FSubD(x, y) when memf x env && findf x env = 0. -> FNegD(y)
  | FSubD(x, y) when memf y env && findf y env = 0. -> FMovD(x)
  | FMulD(x, y) when memf x env && memf y env -> FSetD(findf x env *. findf y env)
  | FMulD(x, y) when memf x env && findf x env = -1. -> FNegD(y)
  | FMulD(x, y) when memf x env && findf x env = 0. -> FSetD(0.)
  | FMulD(x, y) when memf x env && findf x env = 1. -> FMovD(y)
  | FMulD(x, y) when memf y env && findf y env = -1. -> FNegD(x)
  | FMulD(x, y) when memf y env && findf y env = 0. -> FSetD(0.)
  | FMulD(x, y) when memf y env && findf y env = 1. -> FMovD(x)
  | FInv(x) when memf x env && findf x env = 0. -> failwith "Division by zero"
  | FInv(x) when memf x env -> FSetD(1. /. findf x env)
  (* | LdDF of Id.t * id_or_imm *)
  (* | StDF of Id.t * Id.t * id_or_imm *)
  (* | IfEq(x, V(y), e1, e2) when memi x env && memi y env -> if findi x env = findi y env then g env e1 else g env e2
  | IfEq(x, C(y), e1, e2) when memi x env -> if findi x env = y then g env e1 else g env e2
  | IfLE(x, V(y), e1, e2) when memi x env && memi y env -> if findi x env <= findi y env then g env e1 else g env e2
  | IfLE(x, C(y), e1, e2) when memi x env -> if findi x env <= y then g env e1 else g env e2
  | IfGE(x, V(y), e1, e2) when memi x env && memi y env -> if findi x env >= findi y env then g env e1 else g env e2
  | IfGE(x, C(y), e1, e2) when memi x env -> if findi x env >= y then g env e1 else g env e2
  | IfFEq(x, y, e1, e2) when memf x env && memf y env -> if findf x env = findf y env then g env e1 else g env e2
  | IfFLE(x, y, e1, e2) when memf x env && memf y env -> if findf x env <= findf y env then g env e1 else g env e2 *)
  | FAbs(x) when memf x env -> FSetD(abs_float (findf x env))
  | FSqrt(x) when memf x env -> FSetD(sqrt (findf x env))
  | FTOI(x) when memf x env -> Set(int_of_float (findf x env))
  | ITOF(x) when memi x env -> FSetD(float_of_int (findi x env))
  | Cos(x) when memf x env -> FSetD(cos (findf x env))
  | Sin(x) when memf x env -> FSetD(sin (findf x env))
  | Tan(x) when memf x env -> FSetD(tan (findf x env))
  | ATan(x) when memf x env -> FSetD(atan (findf x env))
  | exp -> exp

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) =
  Prog(List.map h fundefs, g M.empty e)

(* alpha変換が有効か *)