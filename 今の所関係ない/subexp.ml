open Asm

let rec rename x x' = function
  | Ans(exp) -> Ans(rename' x x' exp)
  | Let((y, t), exp, e) -> 
      Let((y, t))
let rec rename' x x' exp =
  let re y = if y = x then x' else y in
  let ri = function V(y) -> V(re y) | C(i) -> C(i) in
  let rf = function W(y) -> W(re y) | D(f) -> D(f) in
  match exp with
  | Nop -> Nop
  | Set(i) -> Set(i)
  | FSetD(f) -> FSetD(f)
  | SetL(l) -> SetL(l)
  | Mov(y) -> Mov(re y)
  | Add(y, z) -> Add(ri y, ri z)
  | Addi(y, i) -> Addi(ri y, i)
  | Sub(y, z) -> Sub(ri y, ri z)
  | Mul(y, z) -> Mul(ri y, ri z)
  | Div(y, z) -> Div(ri y, ri z)
  | SLL(y, i) -> SLL(ri y, i)
  | SRA(y, i) -> SRA(ri y, i)
  | Ld(y, i) -> Ld(ri y, i)
  | St(y, z, i) -> St(ri y, ri z, i)
  | FMovD(y) -> FMovD(rf y)
  | FNegD(y) -> FNegD(rf y)
  | FAddD(y, z) -> FAddD(rf y, rf z)
  | FSubD(y, z) -> FSubD(rf y, rf z)
  | FMulD(y, z) -> FMulD(rf y, rf z)
  | FInv(y) -> FInv(rf y)
  | LdDF(y, i) -> LdDF(ri y, i)
  | StDF(y, z, i) -> StDF(rf y, ri z, i)
  | IfEq(y, z, e1, e2) -> 
  | IfLE(y, z, e1, e2) -> 
  | IfFEq(y, z, e1, e2) ->
  | IfFLE(y, z, e1, e2) -> 

let rec g env =
  | Let((x, t), exp, e) ->
      let exp' = g' env exp in
      if then

      else
        Let((x, t), exp', g (M.add .... env) e)
  | Let((x, t), Add(y, z), e) -> 
      if M.mem (Add(y, z)) env then
        Let((x, t), Mov(find (Add(y, z) env)), g env e)
      else
        let env' = M.add (Add(z, y)) 

and g' = function
  | Add()

let rec g env =
  | Let((x, t), exp, e) ->
      let exp' = g' env exp in
      try 
        let y = List.assoc exp' env in
        (comment;
        )
      with Not_Found -> 
        Let((x, t), exp', g  e)

and g' env = function
  | Add(x, y) as exp -> exp, [Add(x, y); Add(y, x)]
  | Addi(x, i) as exp -> exp, [Addi(x, i)]
  | Sub(x, y) as exp -> exp, [Sub(x, y)]
  | Mul(x, y) as exp -> exp, [Mul(x, y); Mul(y, x)]
  | Div(x, y) as exp -> exp, [Div(x, y)]
  | SLL(x, i) as exp -> exp, [SLL(x, i)]
  | SRA(x, i) as exp -> exp, [SRA(x, i)]
  | Ld(x, i) as exp -> exp, [Ld(x, i)]
  