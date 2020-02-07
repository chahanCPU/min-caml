(* open KNormal

let eq = ref []  (* let id:ty = x in y について、((id,ty),x)を集めたリスト *)
let kaeru = ref []  (* (id',id)のリストで、id'をidに変換 *)

(* let文を発見 *)
let rec find x eq = 
  match x with
  | Let ((id,ty),x,y) -> 
    eq := !eq @ [(id,ty),x];
    find y eq
  | _ -> ()

(* 削除できる共通部分式を発見 *)
let onaji eq kaeru =
  let temp = ref !eq in
  while !temp <> [] do
    match !temp with
    | [] -> ()
    | ((id,ty),x)::others -> 
      (List.iter (fun ((id',ty'),x') ->
        (if x = x' && ty = ty' then (match x with
         | Get _ | Put _ | ExtArray _ | ExtFunApp _ -> ()
         | _ -> kaeru := !kaeru @ [id',id]));
         ())
        others);
      temp := others
  done

(* 実際に共通部分式を変換 *)
let rec henkan x kaeru =
  match x with
  | Let ((id,ty),x,y) -> 
    (try let z = List.assoc id !kaeru in
       Let ((id,ty), Var z, henkan y kaeru)
     with _ -> Let ((id,ty),x,henkan y kaeru))
  | x -> x

(* 共通部分式削除の実装 *)
let f x =
  find x eq;
  onaji eq kaeru;
  henkan x kaeru *)
