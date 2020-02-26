open KNormal

(* let rec f = function
  (* 無駄なジャンプを消去 *)
  | Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(x, y, f e1, f e2)))
  | Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfLE(x, y, f e1, f e2)))
  | Let((boo, Type.Int), IfEq(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfEq(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), IfEq(x, y, f e2, f e1)))
  | Let((boo, Type.Int), IfLE(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfLE(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), IfLE(x, y, f e2, f e1)))
  | Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(boo', fal', e1, e2), e3))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(x, y, f e1, f e2), f e3)))
  | Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(boo', fal', e1, e2), e3))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), Let((z, tz), IfLE(x, y, f e1, f e2), f e3)))
  | Let((boo, Type.Int), IfEq(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(boo', fal', e1, e2), e3))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfEq(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(x, y, f e2, f e1), f e3)))
  | Let((boo, Type.Int), IfLE(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), Let((z, tz), IfEq(boo', fal', e1, e2), e3))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfLE(x, y, Int(1), Int(0)), Let((fal, Type.Int), Int(0), Let((z, tz), IfLE(x, y, f e2, f e1), f e3)))
  (* その他 *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, f e1, f e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, f e1, f e2)
  | Let(xt, e1, e2) -> Let(xt, f e1, f e2)
  | LetRec({ name = xt; args = yts; body = e1 }, e2) -> LetRec({ name = xt; args = yts; body = f e1 }, f e2)
  | LetTuple(xts, y, e) -> LetTuple(xts, y, f e)
  | e -> e *)

(* comment *)
(* 共通部分式削除すると、こんな連続にデータが並ぶことはありえないか *)
(* falのゼロとか消えそうなので、 *)
(* 変にKNormalで(Closure変換の前に)共通部分式削除をやってしまうと、 *)
(* let a = 1 in let rec f x = let b = 1 in x + b in f a が *)
(* let a = 1 in let rec f x = x + a in f a とクロージャが必要になりそう *)

let rec g env = function
  | IfEq(x, y, e1, e2) when M.mem x env && M.mem y env -> 
      (match M.find x env, M.find y env with
      | IfEq(z, w, Int(0), Int(1)), Int(0) -> IfEq(z, w, g env e1, g env e2)
      | IfLE(z, w, Int(0), Int(1)), Int(0) -> IfLE(z, w, g env e1, g env e2)
      | IfEq(z, w, Int(1), Int(0)), Int(0) -> IfEq(z, w, g env e2, g env e1)
      | IfLE(z, w, Int(1), Int(0)), Int(0) -> IfLE(z, w, g env e2, g env e1)
      | IfEq(z, w, Int(0), Int(1)), Int(1) -> IfEq(z, w, g env e2, g env e1)
      | IfLE(z, w, Int(0), Int(1)), Int(1) -> IfLE(z, w, g env e2, g env e1)
      | IfEq(z, w, Int(1), Int(0)), Int(1) -> IfEq(z, w, g env e1, g env e2)
      | IfLE(z, w, Int(1), Int(0)), Int(1) -> IfLE(z, w, g env e1, g env e2)
      | Int(0), IfEq(z, w, Int(0), Int(1)) -> IfEq(z, w, g env e1, g env e2)
      | Int(0), IfLE(z, w, Int(0), Int(1)) -> IfLE(z, w, g env e1, g env e2)
      | Int(0), IfEq(z, w, Int(1), Int(0)) -> IfEq(z, w, g env e2, g env e1)
      | Int(0), IfLE(z, w, Int(1), Int(0)) -> IfLE(z, w, g env e2, g env e1)
      | Int(1), IfEq(z, w, Int(0), Int(1)) -> IfEq(z, w, g env e2, g env e1)
      | Int(1), IfLE(z, w, Int(0), Int(1)) -> IfLE(z, w, g env e2, g env e1)
      | Int(1), IfEq(z, w, Int(1), Int(0)) -> IfEq(z, w, g env e1, g env e2)
      | Int(1), IfLE(z, w, Int(1), Int(0)) -> IfLE(z, w, g env e1, g env e2)
      | _ -> IfEq(x, y, g env e1, g env e2))
  | IfEq(x, y, e1, e2) -> IfEq(x, y, g env e1, g env e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, g env e1, g env e2)
  | Let((x, t), e1, e2) -> 
      let e1' = g env e1 in
      Let((x, t), e1', g (M.add x e1' env) e2)
  | LetRec({ name = xt; args = yts; body = e1 }, e2) -> 
      LetRec({ name = xt; args = yts; body = g env e1 }, g env e2)
  | LetTuple(xts, y, e) -> 
      LetTuple(xts, y, g env e)
  | e -> e

let f e = g M.empty e
