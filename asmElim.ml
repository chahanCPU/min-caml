open Asm

let rec effect = function
  (* | IfEq(_, _, e1, e2) | IfLE(_, _, e1, e2) | IfGE(_, _, e1, e2) | IfFEq(_, _, e1, e2) | IfFLE(_, _, e1, e2) -> effect e1 || effect e2 *)
  | IfEq(_) | IfLE(_) | IfGE(_) | IfFEq(_) | IfFLE(_) -> true
  | St(_) | StDF(_) | CallCls(_) | CallDir(_) | Save(_) | Restore(_) | Out(_) | OutInt(_) -> true
  | _ -> false
(* trueを見極めること *)

let rec g = function
  | Ans(exp) -> Ans(g' exp)
  | Let((x, t), exp, e) ->
      let exp' = g' exp in
      let e' = g e in
      if effect exp' || List.mem x (fv e') then Let((x, t), exp', e') else
      ((* perror *)
      e')
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
