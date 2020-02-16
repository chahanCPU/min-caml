open Syntax

let rec g e = function
  | Unit -> e
  | Let(xt, e1, e2) -> Let(xt, e1, g e e2)
  | LetRec(fundef, e2) -> LetRec(fundef, g e e2)
  | LetTuple(xts, e1, e2) -> LetTuple(xts, e1, g e e2)
  | _ -> failwith("The type of libMinCaml.ml must be unit")
let catLibMinCaml e = 
  let libchan = open_in "libMinCaml.ml" in
  g e (Parser.exp Lexer.token (Lexing.from_channel libchan))

let catLibAsm e = 
  List.fold_left (fun e' fundef -> LetRec(fundef, e')) e LibAsm.fundefs

let f e = catLibAsm (catLibMinCaml e)
