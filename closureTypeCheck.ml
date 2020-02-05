(* Closure.progの型検査 *)

open Closure

(* let extenv = ref M.empty *)
let extenv = ref Libtype.extenv  (* mainに合わせて書くべき?? ライブラリ実装をどうしようか *)
let toplevel = ref []

let rec g env = function  (* Closure.tの型検査 *)
  | Unit -> Type.Unit
  | Int(_) -> Type.Int
  | Float(_) -> Type.Float
  | Neg(x) -> 
      assert (M.find x env = Type.Int);
      Type.Int
  | Add(x, y) | Sub(x, y) | Mul(x, y) | Div(x, y) ->
      assert (M.find x env = Type.Int);
      assert (M.find y env = Type.Int);
      Type.Int
  | FNeg(x) ->
      assert (M.find x env = Type.Float);
      Type.Float
  | FAdd(x, y) | FSub(x, y) | FMul(x, y) | FDiv(x, y) ->
      assert (M.find x env = Type.Float);
      assert (M.find y env = Type.Float);
      Type.Float
  | IfEq(x, y, e1, e2) | IfLE(x, y, e1, e2) ->
      let tx, ty = M.find x env, M.find y env in
      assert (tx = ty);
      (match tx with Type.Int | Type.Float -> 
        let t1, t2 = g env e1, g env e2 in
        assert (t1 = t2);
        t1
      | _ -> assert false)
  | Let((x, t1), e1, e2) ->
      assert (g env e1 = t1);
      g (M.add x t1 env) e2
  | Var(x) when M.mem x env -> M.find x env
  (* | Var(x) when M.mem x !extenv -> M.find x env *)
  (* KNormal.mlとか見ると、ライブラリ関数のVarって作られないのか。Applyのときだけ *)
  (* KNormal.ExtArrayとか消したいので *)
  | Var(_) -> assert false
  | MakeCls((x, t1), { entry = l; actual_fv = ys }, e2) when List.exists (fun fundef -> fst fundef.name = l) !toplevel -> 
      let fundef = List.find (fun fundef -> fst fundef.name = l) !toplevel in
      assert (List.map (fun y -> M.find y env) ys = List.map (fun (z, t) -> t) fundef.formal_fv);
      assert (t1 = snd fundef.name);
      g (M.add x t1 env) e2
      (* ライブラリ関数はclosureを作らない（もとの実装は） *)
      (* print_intと書いただけのプログラムはコンパイルできない（もとの実装は） *)
  | MakeCls(_) -> assert false
  | AppCls(x, ys) ->
      (match M.find x env with Type.Fun(ts, t) ->
        assert (List.map (fun y -> M.find y env) ys = ts);
        t
      | _ -> assert false)
  | AppDir(l, ys) when List.exists (fun fundef -> fst fundef.name = l) !toplevel -> 
      (match snd (List.find (fun fundef -> fst fundef.name = l) !toplevel).name with Type.Fun(ts, t) ->
        assert (List.map (fun y -> M.find y env) ys = ts);
        t
      | _ -> assert false)
  | AppDir(Id.L("min_caml_create_array"), ys) ->
      (match List.map (fun y -> M.find y env) ys with [Type.Int; t] when t <> Type.Float ->
        Type.Array(t)
      | _ -> assert false)
  | AppDir(Id.L("min_caml_create_float_array"), ys) ->
      assert (List.map (fun y -> M.find y env) ys = [Type.Int; Type.Float]);
      Type.Array(Type.Float)
  | AppDir(Id.L(x), ys) when String.sub x 0 9 = "min_caml_" ->  (* ライブラリ *)
      (match M.find (String.sub x 9 ((String.length x) - 9)) !extenv with Type.Fun(ts, t) ->
        assert (List.map (fun y -> M.find y env) ys = ts);
        t
      | _ -> assert false)
  | AppDir(_) -> assert false
  | Tuple(xs) -> Type.Tuple(List.map (fun x -> M.find x env) xs)
  | LetTuple(xts, y, e2) ->
      assert (M.find y env = Type.Tuple(List.map (fun (x, t) -> t) xts));
      g (M.add_list xts env) e2
  | Get(x, y) -> 
      (match M.find x env with Type.Array(t) ->
        assert (M.find y env = Type.Int);
        t
      | _ -> assert false)
  | Put(x, y, z) -> 
      (match M.find x env with Type.Array(t) ->
        assert (M.find y env = Type.Int);
        assert (M.find z env = t);
        Type.Unit
      | _ -> assert false)
  | FTOI(x) ->
      assert (M.find x env = Type.Float);
      Type.Int
  | ITOF(x) ->
      assert (M.find x env = Type.Int);
      Type.Float

let h { name = (Id.L(x), t); args = yts; formal_fv = zts; body = e } =  (* Closure.fundefの型検査 *)
  (* assert (Type.Fun(List.map (fun (y, t) -> t) yts, g (M.add_list (zts @ yts) M.empty) e) = t) *)
  (* test/cls-bug2.ml参照 *)
  (* 最初から型環境に {x : t} を加えておく *)
  assert (Type.Fun(List.map (fun (y, t) -> t) yts, g (M.add_list (zts @ yts) (M.singleton x t)) e) = t)

let f (Prog(fundefs, e)) =  (* Closure.progの型検査 *)
  (* extenv := Libtype.extenv;  mainに合わせて書くべき?? ライブラリ実装をどうしようか *)
  toplevel := fundefs;
  List.iter h fundefs;
  ignore (g M.empty e);
  Prog(fundefs, e)
