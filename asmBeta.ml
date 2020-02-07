open Asm

let find x env = try M.find x env with Not_found -> x

let rec g env = function
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), exp, e) ->
      (match g' env exp with
      | Mov(y) -> 
          (* perror *)
          g (M.add x y env) e
      | FMovD(y) ->
          (* perror *)
          g (M.add x y env) e
      | exp' -> Let((x, t), exp', g env e))
and g' env = function
  | Nop | Set(_) | FSetD(_) | SetL(_) as exp -> exp
  | Mov(x) -> Mov(find x env)
  | Neg(x) -> Neg(find x env)
  | Add(x, V(y)) -> Add(find x env, V(find y env))
  | Add(x, C(y)) -> Add(find x env, C(y))
  | Sub(x, V(y)) -> Sub(find x env, V(find y env))
  | Sub(x, C(y)) -> Sub(find x env, C(y))
  | Mul(x, y) -> Mul(find x env, find y env)
  | Div(x, y) -> Div(find x env, find y env)
  | SLL(x, V(y)) -> SLL(find x env, V(find y env))
  | SLL(x, C(y)) -> SLL(find x env, C(y))
  | SRA(x, i) -> SRA(find x env, i)
  (* 要確認 *)
  | Ld(x, V(y)) -> Ld(find x env, V(find y env))
  | Ld(x, C(y)) -> Ld(find x env, C(y))
  | St(x, y, V(z)) -> St(find x env, find y env, V(find z env))
  | St(x, y, C(z)) -> St(find x env, find y env, C(z))
  (* ここまで *)
  | FMovD(x) -> FMovD(find x env)
  | FNegD(x) -> FNegD(find x env)
  | FAddD(x, y) -> FAddD(find x env, find y env)
  | FSubD(x, y) -> FSubD(find x env, find y env)
  | FMulD(x, y) -> FMulD(find x env, find y env)
  | FInv(x) -> FInv(find x env)
  (* 要確認 *)
  | LdDF(x, V(y)) -> LdDF(find x env, V(find y env))
  | LdDF(x, C(y)) -> LdDF(find x env, C(y))
  | StDF(x, y, V(z)) -> StDF(find x env, find y env, V(find z env))
  | StDF(x, y, C(z)) -> StDF(find x env, find y env, C(z))
  (* ここまで *)
  | Comment(_) as exp -> exp
  | IfEq(x, V(y), e1, e2) -> IfEq(find x env, V(find y env), g env e1, g env e2)
  | IfEq(x, C(y), e1, e2) -> IfEq(find x env, C(y), g env e1, g env e2)
  | IfLE(x, V(y), e1, e2) -> IfLE(find x env, V(find y env), g env e1, g env e2)
  | IfLE(x, C(y), e1, e2) -> IfLE(find x env, C(y), g env e1, g env e2)
  | IfGE(x, V(y), e1, e2) -> IfGE(find x env, V(find y env), g env e1, g env e2)
  | IfGE(x, C(y), e1, e2) -> IfGE(find x env, C(y), g env e1, g env e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(find x env, find y env, g env e1, g env e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(find x env, find y env, g env e1, g env e2)
  (* alpha化されてるのか *)
  | CallCls(x, ys, zs) -> CallCls(find x env, List.map (fun y -> find y env) ys, List.map (fun z -> find z env) zs)
  | CallDir(Id.L(x), ys, zs) -> CallDir(Id.L(x), List.map (fun y -> find y env) ys, List.map (fun z -> find z env) zs)
  | Save(x, y) -> Save(find x env, find y env)
  | Restore(x) -> Restore(find x env)
  (* ここまで怪しいかも *)
  | Out(x) -> Out(find x env)
  | OutInt(x) -> OutInt(find x env)
  | FAbs(x) -> FAbs(find x env)
  | FSqrt(x) -> FSqrt(find x env)
  | FTOI(x) -> FTOI(find x env)
  | ITOF(x) -> ITOF(find x env)
  | Cos(x) -> Cos(find x env)
  | Sin(x) -> Sin(find x env)
  | Tan(x) -> Tan(find x env)
  | ATan(x) -> ATan(find x env)

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =
  { name = l; args = xs; fargs = ys; body = g M.empty e; ret = t }

let f (Prog(fundefs, e)) =
  Prog(List.map h fundefs, g M.empty e)
