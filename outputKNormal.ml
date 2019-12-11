open KNormal

let nTAB = ref 0

let output_TABs oc n =
  for i = 1 to n do
    Printf.fprintf oc "\t"
  done

let rec output_t oc x =
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let print_fundef = output_fundef oc in
  let op1 op x = 
    print_string (op ^ " ");
    print_id x;
    print_string "\n" in
  let op2 op x y =
    print_string (op ^ " ");
    print_id x;
    print_string " ";
    print_id y;
    print_string "\n" in
  let op3 op x y z =
    print_string (op ^ " "); 
    print_id x;
    print_string " ";
    print_id y;
    print_string " ";
    print_id z;
    print_string "\n" in
  let opIf op id1 id2 t1 t2 =
    print_string (op ^ " ");
    print_id id1;
    print_string " ";
    print_id id2;
    print_string "\n";
    nTAB := !nTAB + 1;
    print_TABs !nTAB;
    print_t t1;
    print_TABs !nTAB;
    print_t t2;
    nTAB := !nTAB - 1 in
  match x with
  | Unit -> print_string "Unit\n"
  | Int i -> Printf.fprintf oc "Int %d\n" i
  | Float f -> Printf.fprintf oc "Float %f\n" f
  | Neg x -> op1 "Neg" x
  | Add (x,y) -> op2 "Add" x y
  | Sub (x,y) -> op2 "Sub" x y
  | Mul (x,y) -> op2 "Mul" x y
  | Div (x,y) -> op2 "Div" x y
  | FNeg x -> op1 "FNeg" x
  | FAdd (x,y) -> op2 "FAdd" x y
  | FSub (x,y) -> op2 "FSub" x y
  | FMul (x,y) -> op2 "FMul" x y
  | FDiv (x,y) -> op2 "FDiv" x y
  | IfEq (x,y,x',y') -> opIf "IfEq" x y x' y'
  | IfLE (x,y,x',y') -> opIf "IfLE" x y x' y'
  | Let ((id,ty),x,y) ->
      print_string "Let\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_id id;
      print_string " : ";
      print_type ty;
      print_string "\n";
      print_TABs !nTAB;
      print_t x;
      print_TABs !nTAB;
      print_t y;
      nTAB := !nTAB - 1
  | Var id -> 
      print_string "Var "; 
      print_id id; 
      print_string "\n"
  | LetRec (fundef,x) ->
      print_string "LetRec\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_fundef fundef;
      print_TABs !nTAB;
      print_t x;
      nTAB := !nTAB - 1
  | App (x,l) ->
      print_string "App ";
      List.iter (fun x -> print_id x; print_string " ") (x::l);
      print_string "\n"
  | Tuple l ->
      print_string "Tuple (";
      let temp = ref l in
      while !temp <> [] do
        match !temp with
        | x::z::rest ->
            print_id x;
            print_string ", ";
            temp := z::rest
        | x::rest ->
            print_id x;
            temp := rest
        | [] -> ()
      done;
      print_string ")\n"
  | LetTuple (l,id,x) ->
      print_string "LetTuple\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_string "(";
      let temp = ref l in
      while !temp <> [] do
        match !temp with
        | (id,ty)::z::rest ->
            print_id id;
            print_string " : ";
            print_type ty;
            print_string ", ";
            temp := z::rest
        | (id,ty)::rest ->
            print_id id;
            print_string " : ";
            print_type ty;
            temp := rest
        | [] -> ()
      done;
      print_string ")\n";
      print_TABs !nTAB;
      print_id id;
      print_string "\n";
      print_TABs !nTAB;
      print_t x;
      nTAB := !nTAB - 1
  | Get (x,y) -> op2 "Get" x y
  | Put (x,y,z) -> op3 "Put" x y z
  | ExtArray x -> op1 "ExtArray" x
  | ExtFunApp (x,l) ->
      print_string "ExtFunApp ";
      List.iter (fun x -> print_id x; print_string " ") (x::l);
      print_string "\n" 

and output_fundef oc { name = (id,ty); args = l; body = x } =
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  print_string "FunDef\n";
  nTAB := !nTAB + 1;
  print_TABs !nTAB;
  print_id id;
  print_string " : ";
  print_type ty;
  print_string "\n";
  List.iter 
    (fun (id,ty) -> print_TABs !nTAB;
                    print_id id;
                    print_string " : ";
                    print_type ty;
                    print_string "\n")
    l;
  print_TABs !nTAB;
  print_t x;
  nTAB := !nTAB - 1


let hitoshii x y =
  match x, y with
  | Add(x1,x2), Add(y1,y2) -> x1 = y1 && x2 = y2
  | _ -> false
