open Asm

(* 副作用の有無 *)
let rec effect = function
  | Ans(exp) -> effect_exp exp
  | Let(_, exp, e) -> effect_exp exp || effect e
(* 要検証 *)
and effect_exp = function
  | IfEq(_, _, e1, e2) | IfLE(_, _, e1, e2) | IfFEq(_, _, e1, e2) | IfFLE(_, _, e1, e2) -> effect e1 || effect e2
  | St(_) | StDF(_) | CallCls(_) | CallDir(_) | Save(_) | In | Out(_) | OutInt(_) -> true
  | _ -> false
(* $gp = Add $gp 4 を考えて *)

let rec g = function  (* 命令列の不要定義削除 *)
  | Ans(exp) -> Ans(g' exp)
  | Let((x, t), exp, e) ->
      let exp' = g' exp in
      let e' = g e in
      if effect_exp exp' || List.mem x (fv e') 
        || x = reg_hp  (* is_reg????????  代替として、IncrHP命令を作るべき？ これには破壊的代入がされる *)
      then Let((x, t), exp', e') else
      e'
and g' = function  (* 各命令の不要定義削除 *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g e1, g e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g e1, g e2)
  | IfFEq(x, y, e1, e2) -> IfFEq(x, y, g e1, g e2)
  | IfFLE(x, y, e1, e2) -> IfFLE(x, y, g e1, g e2)
  | exp -> exp

let h { name = l; args = xs; fargs = ys; body = e; ret = t } =  (* トップレベル関数の不要定義削除 *)
  { name = l; args = xs; fargs = ys; body = g e; ret = t }

let f (Prog(fundefs, e)) =  (* プログラム全体の不要定義削除 *)
  Prog(List.map h fundefs, g e)
  (* match fundefs with
  | [] -> Prog([], g e)
  | fundef :: others -> 
      let (Prog(fundefs', e')) as prog' = f (Prog(others, e)) in
      if fundefがprog'中に出現 then
        Prog()
      else
        prog' *)
(* fundefsが順番に並んでいること前提、相互再帰とかはだめ *)
(* 確かにfundefsの先頭にcreate_array関連を持ってきた *)


(* let f (Prog(fundefs, e)) =  (* プログラム全体の不要定義削除 *)
  let fundefs = List.map h fundefs in
  let e = g e in
  let fundefs = List.filter (fun fundef -> 自分自身を除くfundefsにfundefが出現 || eにfundefが出現) fundefs in
  Prog() *)

(* virtual.mlで、create_(float_)array_flagを作り、
必要なときしかcreate_(float_)array_loop_fundefが作られないようにしたので、解決 *)
(* やっぱり、不要なfundefも削除させる必要があるか *)
