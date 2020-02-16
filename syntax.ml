type t =  (* MinCamlの構文を表現するデータ型 (caml2html: syntax_t) *)
  | Unit
  | Bool of bool
  | Int of int
  | Float of float
  | Not of t
  | Neg of t
  | Add of t * t
  | Sub of t * t
  | Mul of t * t
  | Div of t * t
  | FNeg of t
  | FAdd of t * t
  | FSub of t * t
  | FMul of t * t
  | FDiv of t * t
  | Eq of t * t
  | LE of t * t
  | If of t * t * t
  | Let of (Id.t * Type.t) * t * t  (* Type.tは型スキーム *)
  | Var of Id.t * (Id.t * Type.t) list  (* listは型変数をどのようにinstantiateしたかを表す *)
  | LetRec of fundef * t
  | App of t * t list
  | Tuple of t list
  | LetTuple of (Id.t * Type.t) list * t * t  (* Type.tは型スキーム *)
  | Array of t * t
  | Get of t * t
  | Put of t * t * t
  | FAbs of t
  | Sqrt of t
  | FTOI of t
  | ITOF of t
  | Out of t
  | OutInt of t
  | In
  | BTOF of t  (* Bits (Binary) to Float *)
and fundef = { name : Id.t * Type.t; args : (Id.t * Type.t) list; body : t }  (* nameのType.tは型スキーム *)
