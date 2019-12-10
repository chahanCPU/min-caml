open Syntax

let rec f e lib = 
  match lib with
  | Unit -> e
  | Let(xt, e1, e2) -> Let(xt, e1, f e e2)
  | LetRec(fundef, e2) -> LetRec(fundef, f e e2)
  | LetTuple(xts, e1, e2) -> LetTuple(xts, e1, f e e2)
  | _ -> failwith("libmincaml.mlの型をUnitにしてください")
