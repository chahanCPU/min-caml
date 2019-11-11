open Closure
open Printf

let nTAB = ref 0

let output_TABs oc n =
  for i = 1 to n do
    Printf.fprintf oc "\t"
  done

let rec output_closure oc closure = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_idl = OutputId.output_l oc in
  let print_TABs = output_TABs oc in
  let { entry = id; actual_fv = l } = closure in
  print_string "Closure\n";
  nTAB := !nTAB + 1;
  print_TABs !nTAB;
  print_idl id;
  print_string "\n";
  List.iter 
    (fun id -> print_TABs !nTAB; print_id id ; print_string "\n")
    l;
  nTAB := !nTAB - 1

and output_t oc x = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_idl = OutputId.output_l oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_closure = output_closure oc in
  let print_t = output_t oc in
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
  | MakeCls ((id,ty),closure,x) ->
      print_string "MakeCls\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_id id;
      print_string " : ";
      print_type ty;
      print_string "\n";
      print_TABs !nTAB;
      print_closure closure;
      print_TABs !nTAB;
      print_t x;
      nTAB := !nTAB - 1
  | AppCls (id,l) ->
      print_string "AppCls ";
      List.iter (fun id -> print_id id; print_string " ") (id::l);
      print_string "\n"
  | AppDir (id,l) ->
      print_string "AppDir ";
      print_idl id;
      print_string " ";
      List.iter (fun id -> print_id id; print_string " ") l;
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
  | ExtArray x ->
      print_string "ExtArray ";
      print_idl x;
      print_string "\n";

and output_fundef oc fundef = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_idl = OutputId.output_l oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let { name = (id,ty); args = l1; formal_fv = l2; body = x } = fundef in
  print_string "FunDef\n";
  nTAB := !nTAB + 1;
  print_TABs !nTAB;
  print_string "/* name */\n";
  print_TABs !nTAB;
  print_idl id;
  print_string " : ";
  print_type ty;
  print_string "\n";
  print_TABs !nTAB;
  print_string "/* args */\n";
  List.iter 
    (fun (id,ty) -> print_TABs !nTAB;
                    print_id id;
                    print_string " : ";
                    print_type ty;
                    print_string "\n")
    l1;
  print_TABs !nTAB;
  print_string "/* formal_fv */\n";
  List.iter 
    (fun (id,ty) -> print_TABs !nTAB;
                    print_id id;
                    print_string " : ";
                    print_type ty;
                    print_string "\n")
    l2;
  print_TABs !nTAB;
  print_string "/* body */\n";
  print_TABs !nTAB;
  print_t x;
  nTAB := !nTAB - 1

and output_prog oc prog = 
  let print_string = Printf.fprintf oc "%s" in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let print_fundef = output_fundef oc in
  let Prog (l,x) = prog in
  print_string "Prog\n";
  nTAB := !nTAB + 1;
  List.iter 
    (fun fundef -> print_TABs !nTAB; print_fundef fundef)
    l;
  print_TABs !nTAB;
  print_t x;
  nTAB := !nTAB - 1
