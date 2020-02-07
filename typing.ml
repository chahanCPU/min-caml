(* type inference/reconstruction *)
(* 多相に対応させたい *)
(* 最後unitでなくても良くしたい *)

(* 静的な型付け *)
(* 分割コンパイルとかは無理 *)

(* 値制限は？ *)
(* let rec f x = x in let rec g y = Array.make 1 f in ((g 0).(0) 1, (g 0).(0) true)  型ついた *)

(* LetRecにより定義した関数は多相型を持つ *)
(* LetやLetTupleでは不可 *)

open Syntax

let extenv = ref M.empty  (* どうする？mainで指定しなくても *)

let rec subst_type sigma = function  (* 型に型代入を実行する *)
  | Type.Unit | Type.Bool | Type.Int | Type.Float as t -> t
  | Type.Fun(ts, t) -> Type.Fun(List.map (subst_type sigma) ts, subst_type sigma t)
  | Type.Tuple(ts) -> Type.Tuple(List.map (subst_type sigma) ts)
  | Type.Array(t) -> Type.Array(subst_type sigma t)
  | Type.Var(alpha) as t -> 
      (match M.find_opt alpha sigma with Some(beta) -> beta | None -> t)
  | Type.Scheme(vars, t) ->  (* 要確認: [a/b](∀a.(a->b))みたいな場合はない *)
      let sigma = List.fold_left (fun sigma alpha -> M.remove alpha sigma) sigma vars in
      Type.Scheme(vars, subst_type sigma t)

let (+) sigma1 sigma2 =  (* 型代入を合成する *)
  M.fold 
    (fun alpha t sigma -> if M.mem alpha sigma then sigma else M.add alpha t sigma)
    sigma1
    (M.map (subst_type sigma1) sigma2)

let subst_env sigma env =  (* 型環境に型代入を実行する *)
  M.map (subst_type sigma) env

let rec subst_term sigma = function  (* termに型代入を実行する *)
  | Unit | Bool(_) | Int(_) | Float(_) as e -> e
  | Not(e) -> Not(subst_term sigma e)
  | Neg(e) -> Neg(subst_term sigma e)
  | Add(e1, e2) -> Add(subst_term sigma e1, subst_term sigma e2)
  | Sub(e1, e2) -> Sub(subst_term sigma e1, subst_term sigma e2)
  | Mul(e1, e2) -> Mul(subst_term sigma e1, subst_term sigma e2)
  | Div(e1, e2) -> Div(subst_term sigma e1, subst_term sigma e2) 
  | FNeg(e) -> FNeg(subst_term sigma e)
  | FAdd(e1, e2) -> FAdd(subst_term sigma e1, subst_term sigma e2)
  | FSub(e1, e2) -> FSub(subst_term sigma e1, subst_term sigma e2)
  | FMul(e1, e2) -> FMul(subst_term sigma e1, subst_term sigma e2) 
  | FDiv(e1, e2) -> FDiv(subst_term sigma e1, subst_term sigma e2) 
  | Eq(e1, e2) -> Eq(subst_term sigma e1, subst_term sigma e2)
  | LE(e1, e2) -> LE(subst_term sigma e1, subst_term sigma e2)
  | If(e1, e2, e3) -> If(subst_term sigma e1, subst_term sigma e2, subst_term sigma e3)
  | Let((x, t), e1, e2) -> 
      Let((x, subst_type sigma t), subst_term sigma e1, subst_term sigma e2)
  | Var(x, bindings) -> Var(x, List.map (fun (alpha, t) -> (alpha, subst_type sigma t)) bindings)
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) ->
      LetRec({ name = (x, subst_type sigma t);
               args = List.map (fun (y, t) -> (y, subst_type sigma t)) yts;
               body = subst_term sigma e1 },
             subst_term sigma e2)
  | App(e, es) -> App(subst_term sigma e, List.map (subst_term sigma) es)
  | Tuple(es) -> Tuple(List.map (subst_term sigma) es)
  | LetTuple(xts, e1, e2) -> 
      LetTuple(List.map (fun (x, t) -> (x, subst_type sigma t)) xts, 
               subst_term sigma e1, 
               subst_term sigma e2)
  | Array(e1, e2) -> Array(subst_term sigma e1, subst_term sigma e2)
  | Get(e1, e2) -> Get(subst_term sigma e1, subst_term sigma e2)
  | Put(e1, e2, e3) -> Put(subst_term sigma e1, subst_term sigma e2, subst_term sigma e3)
  | FTOI(e) -> FTOI(subst_term sigma e)
  | ITOF(e) -> ITOF(subst_term sigma e)

let rec occur alpha = function  (* occur check *)
  | Type.Unit | Type.Bool | Type.Int | Type.Float -> false
  | Type.Fun(ts, t) -> List.exists (occur alpha) ts || occur alpha t
  | Type.Tuple(ts) -> List.exists (occur alpha) ts
  | Type.Array(t) -> occur alpha t
  | Type.Var(beta) -> alpha = beta
  | Type.Scheme(vars, t) -> not (List.mem alpha vars) && occur alpha t

let rec unify t1 t2 =  (* 型が合うように型代入を求める *)
  match t1, t2 with
  | t1, t2 when t1 = t2 -> M.empty
  | Type.Fun(ts1, t1), Type.Fun(ts2, t2) ->
      (try List.fold_left2 
        (fun sigma t1 t2 -> (unify (subst_type sigma t1) (subst_type sigma t2)) + sigma) 
        M.empty
        (ts1 @ [t1])
        (ts2 @ [t2])
      with Invalid_argument(_) -> failwith "Type inference error")
  | Type.Tuple(ts1), Type.Tuple(ts2) -> 
      (try List.fold_left2 
        (fun sigma t1 t2 -> (unify (subst_type sigma t1) (subst_type sigma t2)) + sigma) 
        M.empty 
        ts1 
        ts2
      with Invalid_argument(_) -> failwith "Type inference error")
  | Type.Array(t1), Type.Array(t2) -> unify t1 t2
  | Type.Var(alpha), t when not (occur alpha t) -> M.singleton alpha t
  | t, Type.Var(alpha) when not (occur alpha t) -> M.singleton alpha t
  | _ -> failwith "Type inference error"

let rec fv_type = function  (* 型において自由に出現する型変数の集合を求める *)
  | Type.Unit | Type.Bool | Type.Int | Type.Float -> S.empty
  | Type.Fun(ts, t) -> List.fold_left (fun set t -> S.union set (fv_type t)) S.empty (ts @ [t])
  | Type.Tuple(ts) -> List.fold_left (fun set t -> S.union set (fv_type t)) S.empty ts
  | Type.Array(t) -> fv_type t
  | Type.Var(alpha) -> S.singleton alpha
  | Type.Scheme(vars, t) -> S.diff (fv_type t) (S.of_list vars)

let fv_env env =  (* 型環境において自由に出現する型変数の集合を求める *)
  M.fold (fun x t set -> S.union set (fv_type t)) env S.empty

let generalize env t =  (* 型を型スキームに一般化 *)
  let vars = S.elements (S.diff (fv_type t) (fv_env env)) in
  Type.Scheme(vars, t)

let instantiate t =  (* 型スキームを型に実体化 *)
  match t with Type.Scheme(vars, t) ->
    let sigma = List.fold_left (fun sigma alpha -> M.add alpha (Type.gentyp ()) sigma) M.empty vars in
    (subst_type sigma t, sigma)
  | _ -> assert false

let rec infer env = function  (* 型推論ルーチン *)
(* 型環境Γと(型注釈のない)項Mを受け取って、 *)
(* most general (e, t, σ) s.t. eの型注釈を削除した項がM, σΓ |- e : t を返す *)
  | Unit -> (Unit, Type.Unit, M.empty)
  | Bool(b) -> (Bool(b), Type.Bool, M.empty)
  | Int(i) -> (Int(i), Type.Int, M.empty)
  | Float(f) -> (Float(f), Type.Float, M.empty)
  | Not(e) ->
      let (e, t, s) = infer env e in
      let s' = unify t Type.Bool in
      (Not(subst_term s' e), Type.Bool, s' + s)
  | Neg(e) ->
      let (e, t, s) = infer env e in
      let s' = unify t Type.Int in
      (Neg(subst_term s' e), Type.Int, s' + s)
  | Add(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Int in
      let s2' = unify (subst_type s1' t2) Type.Int in
      (Add(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Int, s2' + (s1' + (s2 + s1)))
  | Sub(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Int in
      let s2' = unify (subst_type s1' t2) Type.Int in
      (Sub(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Int, s2' + (s1' + (s2 + s1)))
  | Mul(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Int in
      let s2' = unify (subst_type s1' t2) Type.Int in
      (Mul(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Int, s2' + (s1' + (s2 + s1)))
  | Div(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Int in
      let s2' = unify (subst_type s1' t2) Type.Int in
      (Div(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Int, s2' + (s1' + (s2 + s1)))
  | FNeg(e) ->
      let (e, t, s) = infer env e in
      let s' = unify t Type.Float in
      (FNeg(subst_term s' e), Type.Float, s' + s)
  | FAdd(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Float in
      let s2' = unify (subst_type s1' t2) Type.Float in
      (FAdd(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Float, s2' + (s1' + (s2 + s1)))
  | FSub(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Float in
      let s2' = unify (subst_type s1' t2) Type.Float in
      (FSub(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Float, s2' + (s1' + (s2 + s1)))
  | FMul(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Float in
      let s2' = unify (subst_type s1' t2) Type.Float in
      (FMul(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Float, s2' + (s1' + (s2 + s1)))
  | FDiv(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Float in
      let s2' = unify (subst_type s1' t2) Type.Float in
      (FDiv(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), Type.Float, s2' + (s1' + (s2 + s1)))
  | Eq(e1, e2) -> (* ここでは左右の型が等しければ良いとする。後は型検査で。 *)
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s' = unify (subst_type s2 t1) t2 in
      (Eq(subst_term (s' + s2) e1, subst_term s' e2), Type.Bool, s' + (s2 + s1))
  | LE(e1, e2) -> (* ここでは左右の型が等しければ良いとする。後は型検査で。 *)
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s' = unify (subst_type s2 t1) t2 in
      (LE(subst_term (s' + s2) e1, subst_term s' e2), Type.Bool, s' + (s2 + s1))
  | If(e1, e2, e3) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let (e3, t3, s3) = infer (subst_env (s2 + s1) env) e3 in
      let s1' = unify (subst_type (s3 + s2) t1) Type.Bool in
      let s2' = unify (subst_type (s1' + s3) t2) (subst_type s1' t3) in
      (If(subst_term (s2' + (s1' + (s3 + s2))) e1, subst_term (s2' + (s1' + s3)) e2, subst_term (s2' + s1') e3), subst_type (s2' + s1') t3, s2' + (s1' + (s3 + (s2 + s1))))
  | Let((x, t), e1, e2) ->  (* 単相型 *)
      let (e1, t1, s1) = infer env e1 in
      let s1' = unify (subst_type s1 t) t1 in
      let (e2, t2, s2) = infer (M.add x (Type.Scheme([], subst_type s1' t1)) (subst_env (s1' + s1) env)) e2 in
      (Let((x, subst_type (s2 + s1') t1), subst_term (s2 + s1') e1, e2), t2, s2 + (s1' + s1))
  | Var(x, []) when M.mem x env -> 
      let (t, sigma) = instantiate (M.find x env) in
      (Var(x, M.bindings sigma), t, M.empty)
  (* 外部関数は決まっているので、後でそう直したい *)
  (* envはenv->tysc, !extenvはenv->typeになってる *)
  (* 今は外部変数は単相型のみ *)
  | Var(x, []) when M.mem x !extenv -> (Var(x, []), M.find x !extenv, M.empty)
  | Var(x, []) -> failwith (Printf.sprintf "Unbound variable: %s" x)
  | Var(_) -> assert false
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) ->  (* 多相関数 *)
      let (e1, t1, s1) = infer (M.add_list (List.map (fun (x, t) -> (x, Type.Scheme([], t))) ((x, t) :: yts)) env) e1 in
      let s1' = unify (subst_type s1 t) (Type.Fun(List.map (fun (_, t) -> subst_type s1 t) yts, t1)) in
      let t' = generalize (subst_env (s1' + s1) env) (subst_type (s1' + s1) t) in
      let (e2, t2, s2) = infer (M.add x t' (subst_env (s1' + s1) env)) e2 in
      (LetRec({ name = (x, subst_type s2 t'); args = List.map (fun (y, t) -> (y, subst_type (s2 + (s1' + s1)) t)) yts; body = subst_term (s2 + s1') e1 }, e2), t2, s2 + (s1' + s1))
  | App(e, es) ->
      let (es, ts, sigma) = List.fold_left
        (fun (es, ts, sigma) e -> 
          let (e, t, s) = infer (subst_env sigma env) e in 
          (List.map (subst_term s) es @ [e], List.map (subst_type s) ts @ [t], s + sigma))
        ([], [], M.empty)
        (e :: es) in
      (match es, ts with e :: es, t :: ts ->
        let t' = Type.gentyp () in
        let s' = unify t (Type.Fun(ts, t')) in
        (App(subst_term s' e, List.map (subst_term s') es), subst_type s' t', s' + sigma)
      | _ -> assert false) 
  | Tuple(es) ->
      let (es, ts, sigma) = List.fold_left
        (fun (es, ts, sigma) e -> 
          let (e, t, s) = infer (subst_env sigma env) e in 
          (List.map (subst_term s) es @ [e], List.map (subst_type s) ts @ [t], s + sigma))
        ([], [], M.empty)
        es in
      (Tuple(es), Type.Tuple(ts), sigma)
  | LetTuple(xts, e1, e2) ->  (* 単相型 *)
      let (e1, t1, s1) = infer env e1 in
      let s1' = unify (Type.Tuple(List.map (fun (_, t) -> subst_type s1 t) xts)) t1 in
      let (e2, t2, s2) = infer (M.add_list (List.map (fun (x, t) -> (x, Type.Scheme([], subst_type (s1' + s1) t))) xts) (subst_env (s1' + s1) env)) e2 in
      (LetTuple(List.map (fun (x, t) -> (x, subst_type (s2 + (s1' + s1)) t)) xts, subst_term (s2 + s1') e1, e2), t2, s2 + (s1' + s1))
  | Array(e1, e2) ->  (* must be a primitive for "polymorphic" typing *)
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s1' = unify (subst_type s2 t1) Type.Int in
      (Array(subst_term (s1' + s2) e1, subst_term s1' e2), Type.Array(subst_type s1' t2), s1' + (s2 + s1))
  | Get(e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let t' = Type.gentyp () in
      let s1' = unify t1 (Type.Array(t')) in
      let s2' = unify t2 Type.Int in
      (Get(subst_term (s2' + (s1' + s2)) e1, subst_term (s2' + s1') e2), subst_type (s2' + s1') t', s2' + (s1' + (s2 + s1)))
  | Put(e1, e2, e3) ->
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let (e3, t3, s3) = infer (subst_env (s2 + s1) env) e3 in
      let s1' = unify (subst_type (s3 + s2) t1) (Type.Array(t3)) in
      let s2' = unify (subst_type (s1' + s3) t2) Type.Int in
      (Put(subst_term (s2' + (s1' + (s3 + s2))) e1, subst_term (s2' + (s1' + s3)) e2, subst_term (s2' + s1') e3), Type.Unit, s2' + (s1' + (s3 + (s2 + s1))))
  | FTOI(e) ->
      let (e, t, s) = infer env e in
      let s' = unify t Type.Float in
      (FTOI(subst_term s' e), Type.Int, s' + s)
  | ITOF(e) ->
      let (e, t, s) = infer env e in
      let s' = unify t Type.Int in
      (ITOF(subst_term s' e), Type.Float, s' + s)

let rec fv_term = function  (* termにおいて自由に出現する型変数の集合を求める *)
  | Unit | Bool(_) | Int(_) | Float(_) -> S.empty
  | Not(e) | Neg(e) | FNeg(e) | FTOI(e) | ITOF(e) -> fv_term e
  | Add(e1, e2) | Sub(e1, e2) | Mul(e1, e2) | Div(e1, e2) | FAdd(e1, e2) | FSub(e1, e2) | FMul(e1, e2) | FDiv(e1, e2) | Eq(e1, e2) | LE(e1, e2) | Array(e1, e2) | Get(e1, e2) -> S.union (fv_term e1) (fv_term e2)
  | If(e1, e2, e3) | Put(e1, e2, e3) -> S.union (S.union (fv_term e1) (fv_term e2)) (fv_term e3)
  | Let((x, t), e1, e2) -> S.union (fv_term e1) (fv_term e2)
  | Var(x, bindings) -> List.fold_left (fun set (alpha, t) -> S.union set (fv_type t)) S.empty bindings 
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) -> S.union (fv_type t) (fv_term e2)
  | App(e, es) -> List.fold_left (fun set e -> S.union set (fv_term e)) S.empty (e :: es)
  | Tuple(es) -> List.fold_left (fun set e -> S.union set (fv_term e)) S.empty es
  | LetTuple(xts, e1, e2) -> S.union (fv_term e1) (fv_term e2)

let undefinedtype_to_int e =  (* 自由に出現している型変数をすべてIntに置換 *)
  let sigma = S.fold (fun alpha sigma -> M.add alpha Type.Int sigma) (fv_term e) M.empty in
  subst_term sigma e

let rec id_of_type = function
  | Type.Unit -> "u"
  | Type.Bool -> "b"
  | Type.Int -> "i"
  | Type.Float -> "f"
  | Type.Fun(ts, t) -> "F(" ^ (List.fold_left (fun id t -> id ^ (id_of_type t)) "" (ts @ [t])) ^ ")"
  | Type.Tuple(ts) -> "T(" ^ (List.fold_left (fun id t -> id ^ (id_of_type t)) "" ts) ^ ")"
  | Type.Array(t) -> "A(" ^ (id_of_type t) ^ ")"
  | Type.Var(_) | Type.Scheme(_) -> assert false

let rename_var (x, bindings) =  (* 多相関数xをinstantiateごとに書き換える *)
  List.fold_left (fun x (_, t) -> x ^ (id_of_type t)) (x ^ ".") bindings

let rec rename_term (x, bindings) x' = function  (* termにおける変数Var(x, bindings)をVar(x', [])に置換する *)
  | Unit | Bool(_) | Int(_) | Float(_) as e -> e
  | Not(e) -> Not(rename_term (x, bindings) x' e)
  | Neg(e) -> Neg(rename_term (x, bindings) x' e)
  | Add(e1, e2) -> Add(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Sub(e1, e2) -> Sub(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Mul(e1, e2) -> Mul(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Div(e1, e2) -> Div(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | FNeg(e) -> FNeg(rename_term (x, bindings) x' e)
  | FAdd(e1, e2) -> FAdd(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | FSub(e1, e2) -> FSub(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | FMul(e1, e2) -> FMul(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | FDiv(e1, e2) -> FDiv(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Eq(e1, e2) -> Eq(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | LE(e1, e2) -> LE(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | If(e1, e2, e3) -> If(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2, rename_term (x, bindings) x' e3)
  | Let((y, t), e1, e2) when x = y -> Let((y, t), rename_term (x, bindings) x' e1, e2)
  | Let((y, t), e1, e2) -> Let((y, t), rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Var(y, b) when (x, bindings) = (y, b) -> Var(x', [])
  | Var(_) as e -> e
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) as e when x = y -> e
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) when List.exists (fun (z, t) -> x = z) zts -> 
      LetRec({ name = (y, t); args = zts; body = e1 }, rename_term (x, bindings) x' e2)
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) -> 
      LetRec({ name = (y, t); args = zts; body = rename_term (x, bindings) x' e1 }, rename_term (x, bindings) x' e2)
  | App(e, es) -> App(rename_term (x, bindings) x' e, List.map (rename_term (x, bindings) x') es)
  | Tuple(es) -> Tuple(List.map (rename_term (x, bindings) x') es)
  | LetTuple(yts, e1, e2) when List.exists (fun (y, t) -> x = y) yts -> LetTuple(yts, rename_term (x, bindings) x' e1, e2)
  | LetTuple(yts, e1, e2) -> LetTuple(yts, rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Array(e1, e2) -> Array(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Get(e1, e2) -> Get(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2)
  | Put(e1, e2, e3) -> Put(rename_term (x, bindings) x' e1, rename_term (x, bindings) x' e2, rename_term (x, bindings) x' e3)
  | FTOI(e) -> FTOI(rename_term (x, bindings) x' e)
  | ITOF(e) -> ITOF(rename_term (x, bindings) x' e)

module S' =
  Set.Make
    (struct
      type t = (Id.t * Type.t) list
      let compare = compare
    end)
  
let rec get_all_bindings x = function  (* 多相関数xがどのようにinstantiateされたかを調べる *)
  | Unit | Bool(_) | Int(_) | Float(_) -> S'.empty
  | Not(e) | Neg(e) | FNeg(e) | FTOI(e) | ITOF(e) -> get_all_bindings x e
  | Add(e1, e2) | Sub(e1, e2) | Mul(e1, e2) | Div(e1, e2) | FAdd(e1, e2) | FSub(e1, e2) | FMul(e1, e2) | FDiv(e1, e2) | Eq(e1, e2) | LE(e1, e2) | Array(e1, e2) | Get(e1, e2) -> S'.union (get_all_bindings x e1) (get_all_bindings x e2)
  | If(e1, e2, e3) | Put(e1, e2, e3) -> S'.union (S'.union (get_all_bindings x e1) (get_all_bindings x e2)) (get_all_bindings x e3)
  | Let((y, t), e1, e2) when x = y -> get_all_bindings x e1
  | Let((y, t), e1, e2) -> S'.union (get_all_bindings x e1) (get_all_bindings x e2)
  | Var(y, bindings) when x = y -> S'.singleton bindings
  | Var(y, bindings) -> S'.empty
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) when x = y -> S'.empty
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) when List.exists (fun (z, t) -> x = z) zts -> get_all_bindings x e2
  | LetRec({ name = (y, t); args = zts; body = e1 }, e2) -> S'.union (get_all_bindings x e1) (get_all_bindings x e2)
  | App(e, es) -> List.fold_left (fun set e -> S'.union set (get_all_bindings x e)) S'.empty (e :: es)
  | Tuple(es) -> List.fold_left (fun set e -> S'.union set (get_all_bindings x e)) S'.empty es
  | LetTuple(yts, e1, e2) when List.exists (fun (y, t) -> x = y) yts -> get_all_bindings x e1
  | LetTuple(yts, e1, e2) -> S'.union (get_all_bindings x e1) (get_all_bindings x e2)

let rec expand = function  (* 関数の複製(expansion)により、多相関数を単相にする *)
  | Unit | Bool(_) | Int(_) | Float(_) as e -> e
  | Not(e) -> Not(expand e)
  | Neg(e) -> Neg(expand e)
  | Add(e1, e2) -> Add(expand e1, expand e2)
  | Sub(e1, e2) -> Sub(expand e1, expand e2)
  | Mul(e1, e2) -> Mul(expand e1, expand e2)
  | Div(e1, e2) -> Div(expand e1, expand e2)
  | FNeg(e) -> FNeg(expand e)
  | FAdd(e1, e2) -> FAdd(expand e1, expand e2)
  | FSub(e1, e2) -> FSub(expand e1, expand e2)
  | FMul(e1, e2) -> FMul(expand e1, expand e2)
  | FDiv(e1, e2) -> FDiv(expand e1, expand e2)
  | Eq(e1, e2) -> Eq(expand e1, expand e2)
  | LE(e1, e2) -> LE(expand e1, expand e2)
  | If(e1, e2, e3) -> If(expand e1, expand e2, expand e3)
  | Let((x, t), e1, e2) -> Let((x, t), expand e1, expand e2)
  | Var(_) as e -> e
  | LetRec({ name = (x, Type.Scheme(vars, t)); args = yts; body = e1 }, e2) -> 
      let e2' = expand e2 in
      S'.fold
        (fun bindings e ->
          let x' = rename_var (x, bindings) in
          let sigma = M.add_list bindings M.empty in
          LetRec({ name = (x', subst_type sigma t);
                   args = List.map (fun (y, t) -> (y, subst_type sigma t)) yts;
                   body = expand (subst_term sigma (rename_term (x, []) x' e1)) },
                 rename_term (x, bindings) x' e))
        (get_all_bindings x e2')  (* 単相再帰なので、e1は含めない *)
        e2'
  | LetRec(_) -> assert false
  | App(e, es) -> App(expand e, List.map expand es)
  | Tuple(es) -> Tuple(List.map expand es)
  | LetTuple(xts, e1, e2) -> LetTuple(xts, expand e1, expand e2)
  | Array(e1, e2) -> Array(expand e1, expand e2)
  | Get(e1, e2) -> Get(expand e1, expand e2)
  | Put(e1, e2, e3) -> Put(expand e1, expand e2, expand e3)
  | FTOI(e) -> FTOI(expand e)
  | ITOF(e) -> ITOF(expand e)

let rec check env = function  (* 型検査 *)
  | Unit -> Type.Unit
  | Bool(_) -> Type.Bool
  | Int(_) -> Type.Int
  | Float(_) -> Type.Float
  | Not(e) -> 
      assert (check env e = Type.Bool); 
      Type.Bool
  | Neg(e) ->
      assert (check env e = Type.Int); 
      Type.Int
  | Add(e1, e2) | Sub(e1, e2) | Mul(e1, e2) | Div(e1, e2) ->
      assert (check env e1 = Type.Int);
      assert (check env e2 = Type.Int);
      Type.Int
  | FNeg(e) ->
      assert (check env e = Type.Float); 
      Type.Float
  | FAdd(e1, e2) | FSub(e1, e2) | FMul(e1, e2) | FDiv(e1, e2) ->
      assert (check env e1 = Type.Float);
      assert (check env e2 = Type.Float);
      Type.Float
  | Eq(e1, e2) | LE(e1, e2) ->  (* Bool, Int, Float型どうしの比較しか行わないようにする *)
      let t1, t2 = check env e1, check env e2 in
      assert (t1 = t2);
      (match t1 with Type.Bool | Type.Int | Type.Float -> Type.Bool
      | _ -> failwith "equality supported only for bool, int, and float")
  | If(e1, e2, e3) ->
      assert (check env e1 = Type.Bool);
      let t2, t3 = check env e2, check env e3 in
      assert (t2 = t3);
      t2
  | Let((x, t), e1, e2) ->
      assert (check env e1 = t);
      check (M.add x t env) e2
  | Var(x, []) when M.mem x env -> M.find x env
  | Var(x, []) when M.mem x !extenv -> M.find x !extenv
  | Var(_) -> assert false
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) -> 
      assert (Type.Fun(List.map (fun (y, t) -> t) yts, check (M.add_list ((x, t) :: yts) env) e1) = t);
      check (M.add x t env) e2
  | App(e, es) ->
      (match check env e with Type.Fun(ts', t') -> 
        assert (ts' = List.map (check env) es);
        t'
      | _ -> assert false)
  | Tuple(es) -> Type.Tuple(List.map (check env) es)
  | LetTuple(xts, e1, e2) ->
      assert (check env e1 = Type.Tuple(List.map (fun (x, t) -> t) xts));
      check (M.add_list xts env) e2
  | Array(e1, e2) ->
      assert (check env e1 = Type.Int);
      Type.Array(check env e2)
  | Get(e1, e2) -> 
      (match check env e1 with Type.Array(t') -> 
        assert (check env e2 = Type.Int); 
        t'
      | _ -> assert false)
  | Put(e1, e2, e3) ->
      (match check env e1 with Type.Array(t') ->
        assert (check env e2 = Type.Int);
        assert (check env e3 = t');
        Type.Unit
      | _ -> assert false)
  | FTOI(e) ->
      assert (check env e = Type.Float); 
      Type.Int
  | ITOF(e) ->
      assert (check env e = Type.Int); 
      Type.Float

let f e =
  Format.eprintf "type inferring...@.";
  let (e, _, _) = infer M.empty e in
  let e = undefinedtype_to_int e in
  let e = expand e in
  ignore (check M.empty e);
  e

(* 関数の説明 *)
(* 型スキーム代入。型スキームを別の型にしたほうが良さそう *)
(* expand。Letのバグ、LetTuple未実装 *) (* このときは単相にした。LetRecのみ多相型に対応 *)
(* RenameSyntaxが必要か。不要そう *)

(* eにも代入したい *)
(* そうしなくて良いように *)
(* 入力の項に自由に出現する型は単相かつ型変数を含まないとする *)
(* 特にライブラリ *)
