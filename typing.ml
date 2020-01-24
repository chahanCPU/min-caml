(* type inference/reconstruction *)
(* 多相に対応させたい *)
(* 最後unitでなくても良くしたい *)

(* 静的な型付け *)
(* 分割コンパイルとかは無理 *)

open Syntax

let extenv = ref M.empty

let rec subst_type sigma = function  (* 型に型代入を実行する *)
  | Type.Unit | Type.Bool | Type.Int | Type.Float as t -> t
  | Type.Fun(ts, t) -> Type.Fun(List.map (subst_type sigma) ts, subst_type sigma t)
  | Type.Tuple(ts) -> Type.Tuple(List.map (subst_type sigma) ts)
  | Type.Array(t) -> Type.Array(subst_type sigma t)
  | Type.Var(alpha) as t -> 
      (match M.find_opt alpha sigma with Some(beta) -> beta | None -> t)

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
  | Var(x) -> Var(x)
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

let rec occur alpha = function  (* occur check *)
  | Type.Unit | Type.Bool | Type.Int | Type.Float -> false
  | Type.Fun(ts, t) -> List.exists (occur alpha) ts || occur alpha t
  | Type.Tuple(ts) -> List.exists (occur alpha) ts
  | Type.Array(t) -> occur alpha t
  | Type.Var(beta) -> alpha = beta

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

let rec infer env = function (* 型推論ルーチン *)
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
  | Eq(e1, e2) -> (* ここでは、何でも通す *)
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (subst_env s1 env) e2 in
      let s' = unify (subst_type s2 t1) t2 in
      (Eq(subst_term (s' + s2) e1, subst_term s' e2), Type.Bool, s' + (s2 + s1))
  | LE(e1, e2) -> (* ここでは、何でも通す *)
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
  | Let((x, _), e1, e2) -> 
      let (e1, t1, s1) = infer env e1 in
      let (e2, t2, s2) = infer (M.add x t1 (subst_env s1 env)) e2 in
      (Let((x, subst_type s2 t1), subst_term s2 e1, e2), t2, s2 + s1)
  | Var(x) when M.mem x env -> (Var(x), M.find x env, M.empty)
  (* 外部関数は決まっているので、後でそう直したい *)
  | Var(x) when M.mem x !extenv -> (Var(x), M.find x !extenv, M.empty)
  | Var(x) -> failwith (Printf.sprintf "Unbound variable: %s" x)
  | LetRec({ name = (x, t); args = yts; body = e1 }, e2) -> 
      let (e1, t1, s1) = infer (M.add_list ((x, t) :: yts) env) e1 in
      let s1' = unify t (Type.Fun(List.map (fun (_, t) -> subst_type s1 t) yts, t1)) in
      let (e2, t2, s2) = infer (M.add x (subst_type (s1' + s1) t) (subst_env (s1' + s1) env)) e2 in
      (LetRec({ name = (x, subst_type (s2 + (s1' + s1)) t); args = List.map (fun (y, t) -> (y, subst_type (s2 + (s1' + s1)) t)) yts; body = subst_term (s2 + s1') e1 }, e2), t2, s2 + (s1' + s1))
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
      | _ -> failwith "Type inference error") 
  | Tuple(es) ->
      let (es, ts, sigma) = List.fold_left
        (fun (es, ts, sigma) e -> 
          let (e, t, s) = infer (subst_env sigma env) e in 
          (List.map (subst_term s) es @ [e], List.map (subst_type s) ts @ [t], s + sigma))
        ([], [], M.empty)
        es in
      (Tuple(es), Type.Tuple(ts), sigma)
  | LetTuple(xts, e1, e2) ->
      let (e1, t1, s1) = infer env e1 in
      let s1' = unify (Type.Tuple(List.map (fun (_, t) -> subst_type s1 t) xts)) t1 in
      let (e2, t2, s2) = infer (M.add_list (List.map (fun (x, t) -> (x, subst_type (s1' + s1) t)) xts) (subst_env (s1' + s1) env)) e2 in
      (LetTuple(List.map (fun (x, t) -> (x, subst_type (s2 + (s1' + s1)) t)) xts, subst_term (s2 + s1') e1, e2), t2, s2 + (s1' + s1))
  | Array(e1, e2) -> (* must be a primitive for "polymorphic" typing *)
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

let rec fv_type = function
  | Type.Unit | Type.Bool | Type.Int | Type.Float -> S.empty
  | Type.Fun(ts, t) -> List.fold_left (fun set t -> S.union set (fv_type t)) S.empty (ts @ [t])
  | Type.Tuple(ts) -> List.fold_left (fun set t -> S.union set (fv_type t)) S.empty ts
  | Type.Array(t) -> fv_type t
  | Type.Var(alpha) -> S.singleton alpha

let rec fv_term = function
  | Unit | Bool(_) | Int(_) | Float(_) -> S.empty
  | Not(e) | Neg(e) | FNeg(e) -> fv_term e
  | Add(e1, e2) | Sub(e1, e2) | Mul(e1, e2) | Div(e1, e2) | FAdd(e1, e2) | FSub(e1, e2) | FMul(e1, e2) | FDiv(e1, e2) | Eq(e1, e2) | LE(e1, e2) | Array(e1, e2) | Get(e1, e2) -> S.union (fv_term e1) (fv_term e2)
  | If(e1, e2, e3) | Put(e1, e2, e3) -> S.union (S.union (fv_term e1) (fv_term e2)) (fv_term e3)
  | Let((x, t), e1, e2) -> S.union (S.union (fv_type t) (fv_term e1)) (fv_term e2)
  | Var(x) -> S.empty  (* 多相型で変更?? *)
  | LetRec({ name = xt; args = yts; body = e1 }, e2) -> S.union (S.union (List.fold_left (fun set (_, t) -> S.union set (fv_type t)) S.empty (xt :: yts)) (fv_term e1)) (fv_term e2)
  | App(e, es) -> List.fold_left (fun set e -> S.union set (fv_term e)) S.empty (e :: es)
  | Tuple(es) -> List.fold_left (fun set e -> S.union set (fv_term e)) S.empty es
  | LetTuple(xts, e1, e2) -> S.union (S.union (List.fold_left (fun set (_, t) -> S.union set (fv_type t)) S.empty xts) (fv_term e1)) (fv_term e2)

let undefinedtype_to_int e = 
  let sigma = S.fold (fun alpha sigma -> M.add alpha Type.Int sigma) (fv_term e) M.empty in
  subst_term sigma e

(* EqとLEの型確認 *)

let f e =
  Format.eprintf "type inferring...@.";
  let (e, _, _) = infer M.empty e in
  undefinedtype_to_int e
