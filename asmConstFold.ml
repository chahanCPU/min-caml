open Asm

let rec pow2 n = if n = 0 then 1 else 2 * pow2 (n - 1)  (* 2のべき乗 *)

let memi x env = match x with
  | V(x') -> (match M.find_opt x' env with Some(Set(_)) -> true | _ -> false)
  | C(_) -> true
(* findじゃなくてfind_optなのは、$gpとか最初envに入ってなさそうなので *)
(* fundefの引数もそうか *)
let memf x env = match x with
  | W(x') -> (match M.find_opt x' env with Some(FSetD(_)) -> true | _ -> false)
  | D(_) -> true

let findi x env = match x with
  | V(x') -> (match M.find_opt x' env with Some(Set(i)) -> i | _ -> raise Not_found)
  | C(i) -> i
let findf x env = match x with
  | W(x') -> (match M.find_opt x' env with Some(FSetD(f)) -> f | _ -> assert false)
  | D(f) -> f

let rec g env = function  (* 命令列の定数畳み込み *)
  | Ans(exp) -> g' env exp
  | Let((x, t) as xt, exp, e) ->
  (* concat *)
      let rec insert = function
        | Ans(exp') -> 
            if is_reg x then Let(xt, exp', g env e)  (* 破壊的代入が行われる変数は環境に加えない *)
            else Let(xt, exp', g (M.add x exp' env) e)
        | Let(yt, exp2, e2) -> Let(yt, exp2, insert e2) in
      insert (g' env exp)

      (* concat (g' env exp) xt (if x = reg_hp then g env e else g (M.add x exp' env) e) *)
      (* concat (g' env exp) xt (g (if x = reg_hp then env else )) *)
      (* insertは副作用を気にしなくてよいか。Assocみたいに *)
      (* いや、気をつける必要があった。次の例を参照。 *)
      (*
      let $gp = 64 in
      let y = if 100 = 100 then
                  let $gp = $gp + 4 in 5
              else
                  0  in
      $gp  ←実際は68なのに、環境は{$gp=64, y=5}である。
      *)
      (* 対策として、破壊的代入が行われる変数(いわばグローバル変数?)は環境に加えないことにする *)
      (* 普通、命令型言語と違って、関数型言語では変数の値が後から変わることはないんだけどね *)

      (* (match g' env exp with
      | Ans(exp') -> Let((x, t), exp', g (M.add x exp' env) e)
      | Let(_) -> assert false
      ) *)

(* 後で小数も *)
and g' env = function  (* 各命令の定数畳み込み *)
  | Mov(x) when memi x env -> Ans(Set(findi x env))
  | Add(x, y) when memi x env && memi y env -> Ans(Set(findi x env + findi y env))
  | Add(x, y) when memi x env && findi x env = 0 -> Ans(Mov(y))
  | Add(x, y) when memi x env && -32768 <= findi x env && findi x env < 32768 -> Ans(Addi(y, findi x env))
  | Add(x, y) when memi y env && findi y env = 0 -> Ans(Mov(x))
  | Add(x, y) when memi y env && -32768 <= findi y env && findi y env < 32768 -> Ans(Addi(x, findi y env))
  | Addi(x, i) when memi x env -> Ans(Set(findi x env + i))
  | Addi(x, 0) -> Ans(Mov(x))
  | Sub(x, y) when memi x env && memi y env -> Ans(Set(findi x env - findi y env))
  (* | Sub(x, y) when memi x env && findi x env = 0 -> Sub(C(0), y) *)
  | Sub(x, y) when memi y env && findi y env = 0 -> Ans(Mov(x))
  | Sub(x, y) when memi y env && -32768 <= -(findi y env) && -(findi y env) < 32768 -> Ans(Addi(x, -(findi y env)))
  | Mul(x, y) when memi x env && memi y env -> Ans(Set(findi x env * findi y env))
  | Mul(x, y) when memi x env && findi x env = -1 -> Ans(Sub(C(0), y))
  | Mul(x, y) when memi x env && findi x env = 0 -> Ans(Set(0))
  | Mul(x, y) when memi x env && findi x env = 1 -> Ans(Mov(y))
  | Mul(x, y) when memi x env && findi x env = pow2 1 -> Ans(SLL(y, 1))
  | Mul(x, y) when memi x env && findi x env = pow2 2 -> Ans(SLL(y, 2))
  | Mul(x, y) when memi x env && findi x env = pow2 3 -> Ans(SLL(y, 3))
  | Mul(x, y) when memi x env && findi x env = pow2 4 -> Ans(SLL(y, 4))
  | Mul(x, y) when memi x env && findi x env = pow2 5 -> Ans(SLL(y, 5))
  | Mul(x, y) when memi x env && findi x env = pow2 6 -> Ans(SLL(y, 6))
  | Mul(x, y) when memi x env && findi x env = pow2 7 -> Ans(SLL(y, 7))
  | Mul(x, y) when memi x env && findi x env = pow2 8 -> Ans(SLL(y, 8))
  | Mul(x, y) when memi x env && findi x env = pow2 9 -> Ans(SLL(y, 9))
  | Mul(x, y) when memi x env && findi x env = pow2 10 -> Ans(SLL(y, 10))
  | Mul(x, y) when memi x env && findi x env = pow2 11 -> Ans(SLL(y, 11))
  | Mul(x, y) when memi x env && findi x env = pow2 12 -> Ans(SLL(y, 12))
  | Mul(x, y) when memi x env && findi x env = pow2 13 -> Ans(SLL(y, 13))
  | Mul(x, y) when memi x env && findi x env = pow2 14 -> Ans(SLL(y, 14))
  | Mul(x, y) when memi x env && findi x env = pow2 15 -> Ans(SLL(y, 15))
  | Mul(x, y) when memi x env && findi x env = pow2 16 -> Ans(SLL(y, 16))
  | Mul(x, y) when memi x env && findi x env = pow2 17 -> Ans(SLL(y, 17))
  | Mul(x, y) when memi x env && findi x env = pow2 18 -> Ans(SLL(y, 18))
  | Mul(x, y) when memi x env && findi x env = pow2 19 -> Ans(SLL(y, 19))
  | Mul(x, y) when memi x env && findi x env = pow2 20 -> Ans(SLL(y, 20))
  | Mul(x, y) when memi x env && findi x env = pow2 21 -> Ans(SLL(y, 21))
  | Mul(x, y) when memi x env && findi x env = pow2 22 -> Ans(SLL(y, 22))
  | Mul(x, y) when memi x env && findi x env = pow2 23 -> Ans(SLL(y, 23))
  | Mul(x, y) when memi x env && findi x env = pow2 24 -> Ans(SLL(y, 24))
  | Mul(x, y) when memi x env && findi x env = pow2 25 -> Ans(SLL(y, 25))
  | Mul(x, y) when memi x env && findi x env = pow2 26 -> Ans(SLL(y, 26))
  | Mul(x, y) when memi x env && findi x env = pow2 27 -> Ans(SLL(y, 27))
  | Mul(x, y) when memi x env && findi x env = pow2 28 -> Ans(SLL(y, 28))
  | Mul(x, y) when memi x env && findi x env = pow2 29 -> Ans(SLL(y, 29))
  | Mul(x, y) when memi x env && findi x env = pow2 30 -> Ans(SLL(y, 30))
  | Mul(x, y) when memi x env && findi x env = pow2 31 -> Ans(SLL(y, 31))
  | Mul(x, y) when memi y env && findi y env = -1 -> Ans(Sub(C(0), x))
  | Mul(x, y) when memi y env && findi y env = 0 -> Ans(Set(0))
  | Mul(x, y) when memi y env && findi y env = 1 -> Ans(Mov(x))
  | Mul(x, y) when memi y env && findi y env = pow2 1 -> Ans(SLL(x, 1))
  | Mul(x, y) when memi y env && findi y env = pow2 2 -> Ans(SLL(x, 2))
  | Mul(x, y) when memi y env && findi y env = pow2 3 -> Ans(SLL(x, 3))
  | Mul(x, y) when memi y env && findi y env = pow2 4 -> Ans(SLL(x, 4))
  | Mul(x, y) when memi y env && findi y env = pow2 5 -> Ans(SLL(x, 5))
  | Mul(x, y) when memi y env && findi y env = pow2 6 -> Ans(SLL(x, 6))
  | Mul(x, y) when memi y env && findi y env = pow2 7 -> Ans(SLL(x, 7))
  | Mul(x, y) when memi y env && findi y env = pow2 8 -> Ans(SLL(x, 8))
  | Mul(x, y) when memi y env && findi y env = pow2 9 -> Ans(SLL(x, 9))
  | Mul(x, y) when memi y env && findi y env = pow2 10 -> Ans(SLL(x, 10))
  | Mul(x, y) when memi y env && findi y env = pow2 11 -> Ans(SLL(x, 11))
  | Mul(x, y) when memi y env && findi y env = pow2 12 -> Ans(SLL(x, 12))
  | Mul(x, y) when memi y env && findi y env = pow2 13 -> Ans(SLL(x, 13))
  | Mul(x, y) when memi y env && findi y env = pow2 14 -> Ans(SLL(x, 14))
  | Mul(x, y) when memi y env && findi y env = pow2 15 -> Ans(SLL(x, 15))
  | Mul(x, y) when memi y env && findi y env = pow2 16 -> Ans(SLL(x, 16))
  | Mul(x, y) when memi y env && findi y env = pow2 17 -> Ans(SLL(x, 17))
  | Mul(x, y) when memi y env && findi y env = pow2 18 -> Ans(SLL(x, 18))
  | Mul(x, y) when memi y env && findi y env = pow2 19 -> Ans(SLL(x, 19))
  | Mul(x, y) when memi y env && findi y env = pow2 20 -> Ans(SLL(x, 20))
  | Mul(x, y) when memi y env && findi y env = pow2 21 -> Ans(SLL(x, 21))
  | Mul(x, y) when memi y env && findi y env = pow2 22 -> Ans(SLL(x, 22))
  | Mul(x, y) when memi y env && findi y env = pow2 23 -> Ans(SLL(x, 23))
  | Mul(x, y) when memi y env && findi y env = pow2 24 -> Ans(SLL(x, 24))
  | Mul(x, y) when memi y env && findi y env = pow2 25 -> Ans(SLL(x, 25))
  | Mul(x, y) when memi y env && findi y env = pow2 26 -> Ans(SLL(x, 26))
  | Mul(x, y) when memi y env && findi y env = pow2 27 -> Ans(SLL(x, 27))
  | Mul(x, y) when memi y env && findi y env = pow2 28 -> Ans(SLL(x, 28))
  | Mul(x, y) when memi y env && findi y env = pow2 29 -> Ans(SLL(x, 29))
  | Mul(x, y) when memi y env && findi y env = pow2 30 -> Ans(SLL(x, 30))
  | Mul(x, y) when memi y env && findi y env = pow2 31 -> Ans(SLL(x, 31))
  | Div(x, y) when memi y env && findi y env = 0 -> failwith "Division by zero"
  | Div(x, y) when memi x env && memi y env -> Ans(Set(findi x env / findi y env))
  | Div(x, y) when memi x env && findi x env = 0 -> Ans(Set(0))
  | Div(x, y) when memi y env && findi y env = -1 -> Ans(Sub(C(0), x))
  | Div(x, y) when memi y env && findi y env = 1 -> Ans(Mov(x))
  | Div(x, y) when memi y env && findi y env = pow2 1 -> Ans(SRA(x, 1))
  | Div(x, y) when memi y env && findi y env = pow2 2 -> Ans(SRA(x, 2))
  | Div(x, y) when memi y env && findi y env = pow2 3 -> Ans(SRA(x, 3))
  | Div(x, y) when memi y env && findi y env = pow2 4 -> Ans(SRA(x, 4))
  | Div(x, y) when memi y env && findi y env = pow2 5 -> Ans(SRA(x, 5))
  | Div(x, y) when memi y env && findi y env = pow2 6 -> Ans(SRA(x, 6))
  | Div(x, y) when memi y env && findi y env = pow2 7 -> Ans(SRA(x, 7))
  | Div(x, y) when memi y env && findi y env = pow2 8 -> Ans(SRA(x, 8))
  | Div(x, y) when memi y env && findi y env = pow2 9 -> Ans(SRA(x, 9))
  | Div(x, y) when memi y env && findi y env = pow2 10 -> Ans(SRA(x, 10))
  | Div(x, y) when memi y env && findi y env = pow2 11 -> Ans(SRA(x, 11))
  | Div(x, y) when memi y env && findi y env = pow2 12 -> Ans(SRA(x, 12))
  | Div(x, y) when memi y env && findi y env = pow2 13 -> Ans(SRA(x, 13))
  | Div(x, y) when memi y env && findi y env = pow2 14 -> Ans(SRA(x, 14))
  | Div(x, y) when memi y env && findi y env = pow2 15 -> Ans(SRA(x, 15))
  | Div(x, y) when memi y env && findi y env = pow2 16 -> Ans(SRA(x, 16))
  | Div(x, y) when memi y env && findi y env = pow2 17 -> Ans(SRA(x, 17))
  | Div(x, y) when memi y env && findi y env = pow2 18 -> Ans(SRA(x, 18))
  | Div(x, y) when memi y env && findi y env = pow2 19 -> Ans(SRA(x, 19))
  | Div(x, y) when memi y env && findi y env = pow2 20 -> Ans(SRA(x, 20))
  | Div(x, y) when memi y env && findi y env = pow2 21 -> Ans(SRA(x, 21))
  | Div(x, y) when memi y env && findi y env = pow2 22 -> Ans(SRA(x, 22))
  | Div(x, y) when memi y env && findi y env = pow2 23 -> Ans(SRA(x, 23))
  | Div(x, y) when memi y env && findi y env = pow2 24 -> Ans(SRA(x, 24))
  | Div(x, y) when memi y env && findi y env = pow2 25 -> Ans(SRA(x, 25))
  | Div(x, y) when memi y env && findi y env = pow2 26 -> Ans(SRA(x, 26))
  | Div(x, y) when memi y env && findi y env = pow2 27 -> Ans(SRA(x, 27))
  | Div(x, y) when memi y env && findi y env = pow2 28 -> Ans(SRA(x, 28))
  | Div(x, y) when memi y env && findi y env = pow2 29 -> Ans(SRA(x, 29))
  | Div(x, y) when memi y env && findi y env = pow2 30 -> Ans(SRA(x, 30))
  | Div(x, y) when memi y env && findi y env = pow2 31 -> Ans(SRA(x, 31))
  | SLL(x, i) when memi x env -> Ans(Set((findi x env) lsl i))
  | SRA(x, i) when memi x env -> Ans(Set((findi x env) asr i))
  (* Ld, St は???? *)
  | IfEq(x, y, e1, e2) when memi x env && memi y env -> if findi x env = findi y env then g env e1 else g env e2
  | IfEq(x, y, e1, e2) -> Ans(IfEq(x, y, g env e1, g env e2))
  | IfLE(x, y, e1, e2) when memi x env && memi y env -> if findi x env <= findi y env then g env e1 else g env e2
  | IfLE(x, y, e1, e2) -> Ans(IfLE(x, y, g env e1, g env e2))
  | IfFEq(x, y, e1, e2) when memf x env && memf y env -> if findf x env = findf y env then g env e1 else g env e2
  | IfFEq(x, y, e1, e2) -> Ans(IfFEq(x, y, g env e1, g env e2))
  | IfFLE(x, y, e1, e2) when memf x env && memf y env -> if findf x env <= findf y env then g env e1 else g env e2
  | IfFLE(x, y, e1, e2) -> Ans(IfFLE(x, y, g env e1, g env e2))

  | FMovD(x) when memf x env -> Ans(FSetD(findf x env))
  | FNegD(x) when memf x env -> Ans(FSetD(-.(findf x env)))
  | FAddD(x, y) when memf x env && memf y env -> Ans(FSetD(findf x env +. findf y env))
  | FAddD(x, y) when memf x env && findf x env = 0. -> Ans(FMovD(y))
  | FAddD(x, y) when memf y env && findf y env = 0. -> Ans(FMovD(x))
  | FSubD(x, y) when memf x env && memf y env -> Ans(FSetD(findf x env -. findf y env))
  | FSubD(x, y) when memf x env && findf x env = 0. -> Ans(FNegD(y))
  | FSubD(x, y) when memf y env && findf y env = 0. -> Ans(FMovD(x))
  | FMulD(x, y) when memf x env && memf y env -> Ans(FSetD(findf x env *. findf y env))
  | FMulD(x, y) when memf x env && findf x env = -1. -> Ans(FNegD(y))
  | FMulD(x, y) when memf x env && findf x env = 0. -> Ans(FSetD(0.))
  | FMulD(x, y) when memf x env && findf x env = 1. -> Ans(FMovD(y))
  | FMulD(x, y) when memf y env && findf y env = -1. -> Ans(FNegD(x))
  | FMulD(x, y) when memf y env && findf y env = 0. -> Ans(FSetD(0.))
  | FMulD(x, y) when memf y env && findf y env = 1. -> Ans(FMovD(x))
  | FInv(x) when memf x env && findf x env = 0. -> failwith "Division by zero"
  | FInv(x) when memf x env -> Ans(FSetD(1. /. findf x env))

  | FAbs(x) when memf x env -> Ans(FSetD(abs_float (findf x env)))
  | FSqrt(x) when memf x env -> Ans(FSetD(sqrt (findf x env)))
  | FTOI(x) when memf x env -> Ans(Set(int_of_float (findf x env)))
  | ITOF(x) when memi x env -> Ans(FSetD(float_of_int (findi x env)))

  | exp -> Ans(exp)

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =  (* トップレベル関数の定数畳み込み *)
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) =  (* プログラム全体の定数畳み込み *)
  Prog(List.map h fundefs, g M.empty e)

(* alpha変換が有効か *)
(* $gp等 *)
