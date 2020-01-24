type t = (* MinCamlの型を表現するデータ型 (caml2html: type_t) *)
  | Unit
  | Bool
  | Int
  | Float
  | Fun of t list * t (* arguments are uncurried *)
  | Tuple of t list
  | Array of t
  | Var of Id.t

let gentyp () = (* 新しい型変数を作る *)
  incr Id.counter;
  Var(Printf.sprintf "'a%d" !Id.counter)
