open KNormal

let rec f = function
  (* Syntax.Notにより生じた無駄なジャンプを消去 *)
  | Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfEq(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(x, y, f e1, f e2)))
  | Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfEq(boo', fal', e1, e2))) when boo = boo' && fal = fal' ->
      Let((boo, Type.Int), IfLE(x, y, Int(0), Int(1)), Let((fal, Type.Int), Int(0), IfLE(x, y, f e1, f e2)))
  (* その他 *)
  | IfEq(x, y, e1, e2) -> IfEq(x, y, f e1, f e2)
  | IfLE(x, y, e1, e2) -> IfLE(x, y, f e1, f e2)
  | Let(xt, e1, e2) -> Let(xt, f e1, f e2)
  | LetRec({ name = xt; args = yts; body = e1 }, e2) -> LetRec({ name = xt; args = yts; body = f e1 }, f e2)
  | LetTuple(xts, y, e) -> LetTuple(xts, y, f e)
  | e -> e

(* comment *)
(* 共通部分式削除すると、こんな連続にデータが並ぶことはありえないか *)
(* falのゼロとか消えそうなので、 *)
(* 変にKNormalで(Closure変換の前に)共通部分式削除をやってしまうと、 *)
(* let a = 1 in let rec f x = let b = 1 in x + b in f a が *)
(* let a = 1 in let rec f x = x + a in f a とクロージャが必要になりそう *)
