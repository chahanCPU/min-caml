open Asm

let find x env = try M.find x env with Not_found -> x
let findi x env = try 

let rec g env = function
  | Ans(exp) -> Ans(g' env exp)
  | Let((x, t), exp, e) ->
      (match g' env exp with
      | Mov(y) ->
          ;
          g (M.add )
      | FMovD(y) ->
          
      | exp' ->
          let e' = g env e in
          Let((x, t), exp', e'))

and g' env = function
  | Nop | Set(_) | FSetD(_) | SetL(_) as exp -> exp
  | Mov(x) -> Mov(find x env)
  | Add(x, y) -> Add(find x env, find y env)
  | Sub(x, y) -> Sub(find x env, find y env)
  | Mul(x, y) -> Mul(find x env, find y env)
  | Div(x, y) -> Div(find x env, find y env)
  | SLL(x, i) -> SLL(find x env, i)
  | SRA(x, i) -> SRA(find x env, i)
  | Ld(x, i) -> Ld(find x env, i)
  | St(x, i) -> St(find x env, find y env, i)
  | FMovD(x) -> FMovD(find x env)
  | FNegD(x) -> FNegD(find y env)
  | FAddD(x, y) -> FAddD(find x env, find y env)
  | FSubD(x, y) -> FSubD(find x env, find y env)
  | FMulD(x, y) -> FMulD(find x env, find y env)
  | FInv(x, y) -> FInv(find x env, find y env)
  | LdDF(x, i) -> LdDF(find x env, i)
  | StDF(x, i) -> StDF(find x env, find y env, i)
  
