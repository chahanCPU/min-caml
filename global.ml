open KNormal
 
let rec rename x x' e = 
  let re y = if y = x then x' else y in
  match e with
  | Unit -> Unit
  | Int(i) -> Int(i)
  | Float(f) -> Float(f)
  | Neg(y) -> Neg(re y)
  | Add(y, z) -> Add(re y, re z)
  | Sub(y, z) -> Sub(re y, re z)
  | Mul(y, z) -> Mul(re y, re z)
  | Div(y, z) -> Div(re y, re z)
  | FNeg(y) -> FNeg(re y)
  | FAdd(y, z) -> FAdd(re y, re z)
  | FSub(y, z) -> FSub(re y, re z)
  | FMul(y, z) -> FMul(re y, re z)
  | FDiv(y, z) -> FDiv(re y, re z)
  | IfEq(y, z, e1, e2) -> IfEq(re y, re z, rename x x' e1, rename x x' e2)
  | IfLE(y, z, e1, e2) -> IfLE(re y, re z, rename x x' e1, rename x x' e2)
  | Let((y, t), e1, e2) ->  (* alpha-conversionの後なので、y <> x *)
      Let((y, t), rename x x' e1, rename x x' e2)
  | Var(y) -> Var(re y)
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) ->  (* alpha-conversionの後なので、 *)
      LetRec({ name = (y, t); args = zts; body = rename x x' e1 }, rename x x' e2)
  | App(y, zs) -> App(re y, List.map re zs)
  | Tuple(ys) -> Tuple(List.map re ys)
  | GlobalTuple(ys) -> GlobalTuple(List.map re ys)
  | LetTuple(yts, z, e) -> (* alpha-conversionの後なので、 *)
      LetTuple(yts, re z, rename x x' e)
  | Array(y, z) -> Array(re y, re z)
  | GlobalArray(i, y) -> GlobalArray(i, re y)
  | Get(y, z) -> Get(re y, re z)
  | Put(y, z, w) -> Put(re y, re z, re w)
  | FAbs(y) -> FAbs(re y)
  | Sqrt(y) -> Sqrt(re y)
  | FTOI(y) -> FTOI(re y)
  | ITOF(y) -> ITOF(re y)
  | Out(y) -> Out(re y)
  | OutInt(y) -> OutInt(re y)
  | In -> In
  | BTOF(y) -> BTOF(re y)

let memi x env = match M.find_opt x env with Some(Int(_)) -> true | _ -> false
let findi x env = match M.find_opt x env with Some(Int(i)) -> i | _ -> raise Not_found

let rec g env = function
  | Let((x, t), Tuple(ys), e) ->
      let x' = Id.global_of x in
      Let((x', t), GlobalTuple(ys), g env (rename x x' e))
  | Let((x, t), Array(y, z), e) when memi y env ->
      let x' = Id.global_of x in
      Let((x', t), GlobalArray(findi y env, z), g env (rename x x' e))
  | Let((x, t), e1, e2) ->
      (* let e1 = g env e1 in *)  (* assoc.mlでネストしたletの簡約をしたので *)
      let e1' = g env e1 in  (* やっぱり問題ないでしょう。let "GLOBAL..." = Global... という形さえ崩れなければ *)
      Let((x, t), e1', g (M.add x e1' env) e2)
  | LetRec(fundef, e) -> LetRec(fundef, g env e)
  | LetTuple(xts, y, e) -> LetTuple(xts, y, g env e)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g env e1, g env e2)  
  | e -> e

let f e = g M.empty e
