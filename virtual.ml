(* translation into chahan assembly with infinite number of virtual registers *)

(* align 4 に直さないとだめ *)
(* もともと倍精度になってるから、色々修正が必要 *)

open Asm

let classify xts ini addf addi =
  List.fold_left
    (fun acc (x, t) ->
      match t with
      | Type.Unit -> acc
      | Type.Float -> addf acc x
      | _ -> addi acc x t)
    ini
    xts

let separate xts =
  classify
    xts
    ([], [])
    (fun (int, float) x -> (int, float @ [x]))
    (fun (int, float) x _ -> (int @ [x], float))

let expand xts ini addf addi =
  classify
    xts
    ini
    (fun (offset, acc) x ->
      (* let offset = align offset in *)
      (* (offset + 8, addf x offset acc)) *)
      (offset + 4, addf x offset acc))
    (fun (offset, acc) x t ->
      (offset + 4, addi x t offset acc))

let rec g env = function (* 式の仮想マシンコード生成 (caml2html: virtual_g) *)
  | Closure.Unit -> Ans(Nop)
  | Closure.Int(i) -> Ans(Set(i))
  | Closure.Float(d) -> Ans(FSetD(d))
      (* let l =
        try
          (* すでに定数テーブルにあったら再利用 *)
          let (l, _) = List.find (fun (_, d') -> d = d') !data in
          l
        with Not_found ->
          let l = Id.L(Id.genid "l") in
          data := (l, d) :: !data;
          l in
      let x = Id.genid "l" in
      Let((x, Type.Int), SetL(l), Ans(LdDF(x, C(0)))) *)
  | Closure.Neg(x) -> Ans(Neg(x))
  | Closure.Add(x, y) -> Ans(Add(x, V(y)))
  | Closure.Sub(x, y) -> Ans(Sub(x, V(y)))
  | Closure.Mul(x, y) -> Ans(Mul(x, y))
  | Closure.Div(x, y) -> Ans(Div(x, y))
  | Closure.FNeg(x) -> Ans(FNegD(x))
  | Closure.FAdd(x, y) -> Ans(FAddD(x, y))
  | Closure.FSub(x, y) -> Ans(FSubD(x, y))
  | Closure.FMul(x, y) -> Ans(FMulD(x, y))
  (* | Closure.FDiv(x, y) -> Ans(FDivD(x, y)) *)
  | Closure.FDiv(x, y) ->
      (* let z = Id.gentmp Type.Float in *)
      let z = Id.genid "Tfloat" in
      Let((z, Type.Float), FInv(y), Ans(FMulD(x, z)))
  | Closure.IfEq(x, y, e1, e2) ->
      (match M.find x env with
      | Type.Bool | Type.Int -> Ans(IfEq(x, V(y), g env e1, g env e2))
      | Type.Float -> Ans(IfFEq(x, y, g env e1, g env e2))
      | _ -> failwith "equality supported only for bool, int, and float")
  | Closure.IfLE(x, y, e1, e2) ->
      (match M.find x env with
      | Type.Bool | Type.Int -> Ans(IfLE(x, V(y), g env e1, g env e2))
      | Type.Float -> Ans(IfFLE(x, y, g env e1, g env e2))
      | _ -> failwith "inequality supported only for bool, int, and float")
  | Closure.Let((x, t1), e1, e2) ->
      let e1' = g env e1 in
      let e2' = g (M.add x t1 env) e2 in
      concat e1' (x, t1) e2'
  | Closure.Var(x) ->
      (match M.find x env with
      | Type.Unit -> Ans(Nop)
      | Type.Float -> Ans(FMovD(x))
      | _ -> Ans(Mov(x)))
  | Closure.MakeCls((x, t), { Closure.entry = l; Closure.actual_fv = ys }, e2) -> (* クロージャの生成 (caml2html: virtual_makecls) *)
      (* Closureのアドレスをセットしてから、自由変数の値をストア *)
      let e2' = g (M.add x t env) e2 in
      let offset, store_fv =
        expand
          (List.map (fun y -> (y, M.find y env)) ys)
          (4, e2')
          (fun y offset store_fv -> seq(StDF(y, x, C(offset)), store_fv))
          (fun y _ offset store_fv -> seq(St(y, x, C(offset)), store_fv)) in
      Let((x, t), Mov(reg_hp),
          (* Let((reg_hp, Type.Int), Add(reg_hp, C(align offset)), *)
          Let((reg_hp, Type.Int), Add(reg_hp, C(offset)),
              let z = Id.genid "l" in
              Let((z, Type.Int), SetL(l),
                  seq(St(z, x, C(0)),
                      store_fv))))
  | Closure.AppCls(x, ys) ->
      let (int, float) = separate (List.map (fun y -> (y, M.find y env)) ys) in
      Ans(CallCls(x, int, float))
  | Closure.AppDir(Id.L(x), ys) ->
  (* int_of_float等、ライブラリ関数の型が正しいか確かめないといけない *)
  (* int_of_floatの引数がintかもしれない *)
      (match x with
      | "min_caml_print_newline" ->
          (* (match ys with [y] -> let z = Id.gentmp Type.Int in Let((z, Type.Int), Set(10), Ans(Out(z)))  yの型がunitだと確かめてない *)
          (match ys with [y] -> let z = Id.genid "Tint" in Let((z, Type.Int), Set(10), Ans(Out(z)))  (* yの型がunitだと確かめてない *)
          | _ -> failwith "print_newline has invalid arguments")
      | "min_caml_print_char" ->
          (match ys with [y] -> Ans(Out(y)) 
          | _ -> failwith "print_char has invalid arguments")
      | "min_caml_print_int" ->
          (match ys with [y] -> Ans(OutInt(y)) 
          | _ -> failwith "print_int has invalid arguments")
      | "min_caml_abs_float" ->
          (match ys with [y] -> Ans(FAbs(y)) 
          | _ -> failwith "abs_float has invalid arguments")
      | "min_caml_sqrt" ->
          (match ys with [y] -> Ans(FSqrt(y)) 
          | _ -> failwith "sqrt has invalid arguments")
      | "min_caml_int_of_float" ->
          (match ys with [y] -> Ans(FTOI(y)) 
          | _ -> failwith "int_of_float has invalid arguments")
      | "min_caml_truncate" ->
          (match ys with [y] -> Ans(FTOI(y)) 
          | _ -> failwith "truncate has invalid arguments")
      | "min_caml_float_of_int" ->
          (match ys with [y] -> Ans(ITOF(y)) 
          | _ -> failwith "float_of_int has invalid arguments")
      | "min_caml_cos" ->
          (match ys with [y] -> Ans(Cos(y)) 
          | _ -> failwith "cos has invalid arguments")
      | "min_caml_sin" ->
          (match ys with [y] -> Ans(Sin(y)) 
          | _ -> failwith "sin has invalid arguments")
      | "min_caml_tan" ->
          (match ys with [y] -> Ans(Tan(y)) 
          | _ -> failwith "tan has invalid arguments")
      | "min_caml_atan" ->
          (match ys with [y] -> Ans(ATan(y)) 
          | _ -> failwith "atan has invalid arguments")
      | x ->
          let (int, float) = separate (List.map (fun y -> (y, M.find y env)) ys) in
          Ans(CallDir(Id.L(x), int, float)))
  | Closure.Tuple(xs) -> (* 組の生成 (caml2html: virtual_tuple) *)
      let y = Id.genid "t" in
      let (offset, store) =
        expand
          (List.map (fun x -> (x, M.find x env)) xs)
          (0, Ans(Mov(y)))
          (fun x offset store -> seq(StDF(x, y, C(offset)), store))
          (fun x _ offset store -> seq(St(x, y, C(offset)), store)) in
      Let((y, Type.Tuple(List.map (fun x -> M.find x env) xs)), Mov(reg_hp),
          (* Let((reg_hp, Type.Int), Add(reg_hp, C(align offset)), *)
          Let((reg_hp, Type.Int), Add(reg_hp, C(offset)),
              store))
  | Closure.LetTuple(xts, y, e2) ->
      let s = Closure.fv e2 in
      let (offset, load) =
        expand
          xts
          (0, g (M.add_list xts env) e2)
          (fun x offset load ->
            if not (S.mem x s) then load else (* [XX] a little ad hoc optimization *)
            fletd(x, LdDF(y, C(offset)), load))
          (fun x t offset load ->
            if not (S.mem x s) then load else (* [XX] a little ad hoc optimization *)
            Let((x, t), Ld(y, C(offset)), load)) in
      load
  | Closure.Get(x, y) -> (* 配列の読み出し (caml2html: virtual_get) *)
      let offset = Id.genid "o" in
      (match M.find x env with
      | Type.Array(Type.Unit) -> Ans(Nop)
      | Type.Array(Type.Float) ->
          (* Let((offset, Type.Int), SLL(y, C(3)), *)
          Let((offset, Type.Int), SLL(y, C(2)),
              Ans(LdDF(x, V(offset))))
      | Type.Array(_) ->
          Let((offset, Type.Int), SLL(y, C(2)),
              Ans(Ld(x, V(offset))))
      | _ -> assert false)
  | Closure.Put(x, y, z) ->
      let offset = Id.genid "o" in
      (match M.find x env with
      | Type.Array(Type.Unit) -> Ans(Nop)
      | Type.Array(Type.Float) ->
          (* Let((offset, Type.Int), SLL(y, C(3)), *)
          Let((offset, Type.Int), SLL(y, C(2)),
              Ans(StDF(z, x, V(offset))))
      | Type.Array(_) ->
          Let((offset, Type.Int), SLL(y, C(2)),
              Ans(St(z, x, V(offset))))
      | _ -> assert false)
  | Closure.ExtArray(Id.L(x)) -> Ans(SetL(Id.L("min_caml_" ^ x)))

(* 関数の仮想マシンコード生成 (caml2html: virtual_h) *)
let h { Closure.name = (Id.L(x), t); Closure.args = yts; Closure.formal_fv = zts; Closure.body = e } =
  let (int, float) = separate yts in
  let (offset, load) =
    expand
      zts
      (4, g (M.add x t (M.add_list yts (M.add_list zts M.empty))) e)
      (fun z offset load -> fletd(z, LdDF(x, C(offset)), load))
      (fun z t offset load -> Let((z, t), Ld(x, C(offset)), load)) in
  match t with
  | Type.Fun(_, t2) ->
      { name = Id.L(x); args = int; fargs = float; body = load; ret = t2 }
  | _ -> assert false

(* プログラム全体の仮想マシンコード生成 (caml2html: virtual_f) *)
let f (Closure.Prog(fundefs, e)) =
  let fundefs = List.map h fundefs in
  let e = g M.empty e in
  (* let e = concat e (Id.genid "main", Type.Unit) (Ans(Nop)) in *)    (* コア係より末尾にNopが欲しい *)
  Prog(fundefs, e)