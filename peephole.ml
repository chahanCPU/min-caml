open Asm

(* for Asm.exp *)

let rec g = function
  | Ans(exp) -> Ans(g' exp)
  | Let((x1, t1), Add(y, C(i1)), Let((x2, t2), Add(x1', C(i2)), e)) when x1 = x1' ->
      g (Let((x2, t2), Add(y, C(i1 + i2)), e))
  | Let((x1, t1), Set(i1), Let((x2, t2), Add(x1', C(i2)), e)) when x1 = x1' ->  
      g (Let((x2, t2), Set(i1 + i2), e))
  | Let((y1, t1), Mov(x1), Let((z2, t2), Mov(y2), e)) when y1 = y2 ->
      g (Let((z2, t2), Mov(x1), e))
  | Let((y1, t1), FMovD(x1), Let((z2, t2), FMovD(y2), e)) when y1 = y2 ->
      g (Let((z2, t2), FMovD(x1), e))
  | Let((x, t), exp, e) -> Let((x, t), g' exp, g e)
and g' = function
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g e1, g e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g e1, g e2)
  | IfGE(x, y, e1, e2) -> IfGE(x, y, g e1, g e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g e1, g e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g e1, g e2)
  | exp -> exp

let h { name = l; args = xs; fargs = ys; body = e; ret = t } = 
  { name = l; args = xs; fargs = ys; body = g e; ret = t }

let f (Prog(fundefs, e)) = 
  Prog(List.map h fundefs, g e)
