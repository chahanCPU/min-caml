open Syntax

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
    print_string (op ^ "\n");
    nTAB := !nTAB + 1;
    print_TABs !nTAB;
    print_t x;
    nTAB := !nTAB - 1 in
  let op2 op x y =
    print_string (op ^ "\n");    
    nTAB := !nTAB + 1;
    print_TABs !nTAB;
    print_t x;
    print_TABs !nTAB;
    print_t y;
    nTAB := !nTAB - 1 in
  let op3 op x y z =
    print_string (op ^ "\n");
    nTAB := !nTAB + 1;
    print_TABs !nTAB;
    print_t x;
    print_TABs !nTAB;
    print_t y;
    print_TABs !nTAB;
    print_t z;
    nTAB := !nTAB - 1 in
  match x with
  | Unit -> print_string "Unit\n"
  | Bool b -> Printf.fprintf oc "Bool %B\n" b
  | Int i -> Printf.fprintf oc "Int %d\n" i
  | Float f -> Printf.fprintf oc "Float %f\n" f
  | Not x -> op1 "Not" x
  | Neg x -> op1 "Neg" x
  | Add (x,y) -> op2 "Add" x y
  | Sub (x,y) -> op2 "Sub" x y
  | FNeg x -> op1 "FNeg" x
  | FAdd (x,y) -> op2 "FAdd" x y
  | FSub (x,y) -> op2 "FSub" x y
  | FMul (x,y) -> op2 "FMul" x y
  | FDiv (x,y) -> op2 "FDiv" x y
  | Eq (x,y) -> op2 "Eq" x y
  | LE (x,y) -> op2 "LE" x y
  | If (x,y,z) -> op3 "If" x y z
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
      print_fundef fundef;
      print_TABs !nTAB;
      print_t x;
      nTAB := !nTAB - 1
  | App (x,l) ->
      print_string "App\n";
      nTAB := !nTAB + 1;
      List.iter (fun x -> print_TABs !nTAB; print_t x) (x::l);
      nTAB := !nTAB - 1
  | Tuple l ->
      print_string "Tuple\n";
      nTAB := !nTAB + 1;
      List.iter (fun x -> print_TABs !nTAB; print_t x) l;
      nTAB := !nTAB - 1
  | LetTuple (l,x,y) ->
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
      print_t x;
      print_TABs !nTAB;
      print_t y;
      nTAB := !nTAB - 1
  | Array (x,y) -> op2 "Array" x y
  | Get (x,y) -> op2 "Get" x y
  | Put (x,y,z) -> op3 "Put" x y z

and output_fundef oc { name = (id,ty); args = l; body = x } = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  print_TABs !nTAB; 
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

let string_of_t = function
  | Unit -> "Unit"
  | Bool b -> "Bool"
  | Int i -> "Int"
  | Float f -> "Float"
  | Not x -> "Not"
  | Neg x -> "Neg"
  | Add (x,y) -> "Add"
  | Sub (x,y) -> "Sub"
  | FNeg x -> "FNeg"
  | FAdd _ -> "FAdd"
  | FSub _ -> "FSub"
  | FMul _ -> "FMul"
  | FDiv _ -> "FDiv"
  | Eq _ -> "Eq"
  | LE _ -> "LE"
  | If _ -> "If"
  | Let _ -> "Let"
  | Var _ -> "Var"
  | LetRec _ -> "LetRec"
  | App _ -> "App"
  | Tuple _ -> "Tuple"
  | LetTuple _ -> "LetTuple"
  | Array _ -> "Array"
  | Get _ -> "Get"
  | Put _ -> "Put"

let string_of_fundef fundef = "fundef"
