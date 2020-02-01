(* Lambda Lifting *)
(* クロージャを削除するため *)
(* α変換（異なる変数には異なる名前をつける）の後に実施すること *)

open KNormal 

let rec g env tyenv = function  (* envは関数定義からその本体中の自由変数たちへの写像、tyenvは型環境 *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g env tyenv e1, g env tyenv e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g env tyenv e1, g env tyenv e2)
  | Let((x, t), e1, e2) -> 
      Let((x, t), g env tyenv e1, g (M.add x [] env) (M.add x t tyenv) e2)
  | LetRec({ name = (x, Type.Fun(ts, t)); args = yts; body = e1 }, e2) -> 
      let zs = S.elements (S.diff (fv e1) (S.of_list (x :: List.map fst yts))) in
      let zts = List.map (fun z -> (z, M.find z tyenv)) zs in
      let t' = Type.Fun(List.map snd zts @ ts, t) in
      LetRec({ name = (x, t');
               args = zts @ yts;
               body = g (M.add_list ((x, zs) :: List.map (fun (y, t) -> (y, [])) yts) env) (M.add_list ((x, t') :: yts) tyenv) e1 },
             g (M.add x zs env) (M.add x t' tyenv) e2)
  | LetRec(_) -> assert false
  | App(x, ys) -> App(x, M.find x env @ ys)
  | LetTuple(xts, y, e) -> 
      LetTuple(xts, y, g (List.fold_left (fun env (x, t) -> M.add x [] env) env xts) (M.add_list xts tyenv) e)
  | e -> e

(* let f e = g M.empty M.empty e *)
let f e = g M.empty Libtype.extenv e


(* 定数畳み込みの後にしたほうがいいのかも *)
(* ladder.mlとか畳み込めそう *)


(* バグあり *)
(* adder.txt *)
(* 
<****** LambdaLifting ******>
LetRec
	make_adder..44 : (int -> (int -> int))    ここと fun([int], fun([int], int))
	x.45 : int
	LetRec
		adder..50 : (int -> int -> int)
		x.45 : int, y.51 : int
		Add x.45 y.51
	Var adder..50                             ここと fun([int; int], int)
Let
	Tint.43.46 : int
	Let
		Tfun.41.47 : (int -> int)
		Let
			Tint.40.49 : int
			Int 3
		App make_adder..44 Tint.40.49
	Let
		Tint.42.48 : int
		Int 7
	App Tfun.41.47 Tint.42.48
ExtFunApp print_int Tint.43.46               の型が異なる。カリー化されていないため。
*)
(* funをflat化すれば、良いのかなぁ *)
