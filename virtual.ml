(* translation into chahan assembly with infinite number of virtual registers *)

(* align 4 に直さないとだめ *)
(* もともと倍精度になってるから、色々修正が必要 *)

open Asm

let create_array_appears = ref false
let create_float_array_appears = ref false

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
  | Closure.Neg(x) -> Ans(Sub(C(0), V(x)))
  | Closure.Add(x, y) -> Ans(Add(V(x), V(y)))
  | Closure.Sub(x, y) -> Ans(Sub(V(x), V(y)))
  | Closure.Mul(x, y) -> Ans(Mul(V(x), V(y)))
  | Closure.Div(x, y) -> Ans(Div(V(x), V(y)))
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
      | Type.Bool | Type.Int -> Ans(IfEq(V(x), V(y), g env e1, g env e2))
      | Type.Float -> Ans(IfFEq(x, y, g env e1, g env e2))
      | _ -> assert false)  (* equality supported only for bool, int, and float *)
  | Closure.IfLE(x, y, e1, e2) ->
      (match M.find x env with
      | Type.Bool | Type.Int -> Ans(IfLE(V(x), V(y), g env e1, g env e2))
      | Type.Float -> Ans(IfFLE(x, y, g env e1, g env e2))
      | _ -> assert false)  (* inequality supported only for bool, int, and float *)
  | Closure.Let((x, t1), e1, e2) ->
      let e1' = g env e1 in
      let e2' = g (M.add x t1 env) e2 in
      concat e1' (x, t1) e2'
  | Closure.Var(x) ->
      (match M.find x env with
      | Type.Unit -> Ans(Nop)
      | Type.Float -> Ans(FMovD(x))
      | _ -> Ans(Mov(V(x))))
  | Closure.MakeCls((x, t), { Closure.entry = l; Closure.actual_fv = ys }, e2) -> (* クロージャの生成 (caml2html: virtual_makecls) *)
      (* Closureのアドレスをセットしてから、自由変数の値をストア *)
      let e2' = g (M.add x t env) e2 in
      let offset, store_fv =
        expand
          (List.map (fun y -> (y, M.find y env)) ys)
          (4, e2')
          (fun y offset store_fv -> seq(StDF(y, x, offset), store_fv))
          (fun y _ offset store_fv -> seq(St(y, x, offset), store_fv)) in
      Let((x, t), Mov(V(reg_hp)),
        (* Let((reg_hp, Type.Int), Add(reg_hp, C(align offset)), *)
        (* offsetの大小評価 *)
        Let((reg_hp, Type.Int), Addi(V(reg_hp), offset),
          let z = Id.genid "l" in
          Let((z, Type.Int), SetL(l),
            seq(St(z, x, 0),
              store_fv))))
  | Closure.AppCls(x, ys) ->
      let (int, float) = separate (List.map (fun y -> (y, M.find y env)) ys) in
      Ans(CallCls(x, int, float))
  | Closure.AppDir(Id.L(x), ys) ->
      let (int, float) = separate (List.map (fun y -> (y, M.find y env)) ys) in
      Ans(CallDir(Id.L(x), int, float))
  | Closure.Tuple(xs) -> (* 組の生成 (caml2html: virtual_tuple) *)
      let y = Id.genid "t" in
      let (offset, store) =
        expand
          (List.map (fun x -> (x, M.find x env)) xs)
          (0, Ans(Mov(V(y))))
          (fun x offset store -> seq(StDF(x, y, offset), store))
          (fun x _ offset store -> seq(St(x, y, offset), store)) in
      Let((y, Type.Tuple(List.map (fun x -> M.find x env) xs)), Mov(V(reg_hp)),
        (* Let((reg_hp, Type.Int), Add(reg_hp, C(align offset)), *)
        (* offsetの大小評価 *)
        Let((reg_hp, Type.Int), Addi(V(reg_hp), offset),
          store))
  | Closure.LetTuple(xts, y, e2) ->
      let s = Closure.fv e2 in
      let (offset, load) =
        expand
          xts
          (0, g (M.add_list xts env) e2)
          (fun x offset load ->
            if not (S.mem x s) then load else (* [XX] a little ad hoc optimization *)
            fletd(x, LdDF(y, offset), load))
          (fun x t offset load ->
            if not (S.mem x s) then load else (* [XX] a little ad hoc optimization *)
            Let((x, t), Ld(y, offset), load)) in
      load
  | Closure.Array(x, y) ->
      let return_address = Id.genid "arr" in
      (match M.find y env with
      | Type.Unit -> Ans(Nop)
      | Type.Float -> 
          create_float_array_appears := true;
          Let((return_address, Type.Array(Type.Float)), Mov(V(reg_hp)),
            seq(CallDir(Id.L("create_float_array_loop"), [x], [y]),
              Ans(Mov(V(return_address)))))
      | t ->
          create_array_appears := true;
          Let((return_address, Type.Array(t)), Mov(V(reg_hp)),
            seq(CallDir(Id.L("create_array_loop"), [x; y], []),
              Ans(Mov(V(return_address))))))
  | Closure.Get(x, y) -> (* 配列の読み出し (caml2html: virtual_get) *)
      let offset = Id.genid "o" in
      let abs_address = Id.genid "abs_address" in
      (match M.find x env with
      | Type.Array(Type.Unit) -> Ans(Nop)
      | Type.Array(Type.Float) ->
          (* Let((offset, Type.Int), SLL(y, C(3)), *)
          (* Let((offset, Type.Int), SLL(y, C(2)),
              Ans(LdDF(x, V(offset)))) *)
          Let((offset, Type.Int), SLL(V(y), 2),
            Let((abs_address, Type.Int), Add(V(x), V(offset)),
              Ans(LdDF(abs_address, 0))))
      | Type.Array(_) ->
          (* Let((offset, Type.Int), SLL(y, C(2)),
              Ans(Ld(x, V(offset)))) *)
          Let((offset, Type.Int), SLL(V(y), 2),
            Let((abs_address, Type.Int), Add(V(x), V(offset)),
              Ans(Ld(abs_address, 0))))
      | _ -> assert false)
  | Closure.Put(x, y, z) ->
      let offset = Id.genid "o" in
      let abs_address = Id.genid "abs_address" in
      (match M.find x env with
      | Type.Array(Type.Unit) -> Ans(Nop)
      | Type.Array(Type.Float) ->
          (* Let((offset, Type.Int), SLL(y, C(3)), *)
          (* Let((offset, Type.Int), SLL(y, C(2)),
              Ans(StDF(z, x, V(offset)))) *)
          Let((offset, Type.Int), SLL(V(y), 2),
            Let((abs_address, Type.Int), Add(V(x), V(offset)),
              Ans(StDF(z, abs_address, 0))))
      | Type.Array(_) ->
          (* Let((offset, Type.Int), SLL(y, C(2)),
              Ans(St(z, x, V(offset)))) *)
          Let((offset, Type.Int), SLL(V(y), 2),
            Let((abs_address, Type.Int), Add(V(x), V(offset)),
              Ans(St(z, abs_address, 0))))
      | _ -> assert false)
  | Closure.FAbs(x) -> Ans(FAbs(x))
  | Closure.Sqrt(x) -> Ans(FSqrt(x))
  | Closure.FTOI(x) -> Ans(FTOI(x))
  | Closure.ITOF(x) -> Ans(ITOF(x))
  | Closure.Out(x) -> Ans(Out(x))
  | Closure.OutInt(x) -> Ans(OutInt(x))
  | Closure.In -> Ans(In)
  | Closure.BTOF(x) ->
      seq(St(x, "$zero", 16), Ans(LdDF("$zero", 16)))  (* 16???? *) (* 上手く行くのか。$zeroをregAlloc等でそのままにしてくれるか *)
      (* reg_zero *)

(* 関数の仮想マシンコード生成 (caml2html: virtual_h) *)
let h { Closure.name = (Id.L(x), t); Closure.args = yts; Closure.formal_fv = zts; Closure.body = e } =
  let (int, float) = separate yts in
  let (offset, load) =
    expand
      zts
      (4, g (M.add x t (M.add_list yts (M.add_list zts M.empty))) e)
      (fun z offset load -> fletd(z, LdDF(x, offset), load))
      (fun z t offset load -> Let((z, t), Ld(x, offset), load)) in
  match t with
  | Type.Fun(_, t2) ->
      { name = Id.L(x); args = int; fargs = float; body = load; ret = t2 }
  | _ -> assert false

(* Array用の関数 *)
let create_array_loop_fundef =
  let n = Id.genid "n" in
  let x = Id.genid "x" in
  let m = Id.genid "m" in
  { name = Id.L("create_array_loop");
    args = [n; x];
    fargs = [];
    body = Ans(IfEq(V(n), C(0), 
             Ans(Nop),
             seq(St(x, reg_hp, 0),
               Let((m, Type.Int), Addi(V(n), -1),
                 Let((reg_hp, Type.Int), Addi(V(reg_hp), 4),
                   Ans(CallDir(Id.L("create_array_loop"), [m; x], []))))))); 
    ret = Type.Unit }
let create_float_array_loop_fundef =
  let n = Id.genid "n" in
  let x = Id.genid "x" in
  let m = Id.genid "m" in
  { name = Id.L("create_float_array_loop");
    args = [n];
    fargs = [x];
    body = Ans(IfEq(V(n), C(0), 
             Ans(Nop),
             seq(StDF(x, reg_hp, 0),
               Let((m, Type.Int), Addi(V(n), -1),
                 Let((reg_hp, Type.Int), Addi(V(reg_hp), 4),
                   Ans(CallDir(Id.L("create_float_array_loop"), [m], [x]))))))); 
    ret = Type.Unit }

(* プログラム全体の仮想マシンコード生成 (caml2html: virtual_f) *)
let f (Closure.Prog(fundefs, e)) =
  let fundefs' = List.map h fundefs in
  let e' = g M.empty e in
  let fundefs'' = (if !create_array_appears then [create_array_loop_fundef] else []) @
                  (if !create_float_array_appears then [create_float_array_loop_fundef] else []) @
                  fundefs' in
  Prog(fundefs'', e')
