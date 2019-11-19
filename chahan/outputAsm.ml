(* もっとわかりやすくして *)

open Asm

let nTAB = ref 0

let output_TABs oc n =
  for i = 1 to n do
    Printf.fprintf oc "\t"
  done

let rec output_id_or_imm oc id_or_imm = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  match id_or_imm with
  | V x -> 
      print_string "(V ";
      print_id x;
      print_string ")"
  | C i ->
      Printf.fprintf oc "(C %d)" i

and output_t oc x = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let print_exp = output_exp oc in
  match x with
  | Ans exp ->
      print_string "Ans\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_exp exp;
      nTAB := !nTAB - 1
  | Let ((id,ty),exp,x) ->
      print_string "Let\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_id id;
      print_string " : ";
      print_type ty;
      print_string "\n";
      print_TABs !nTAB;
      print_exp exp;
      print_TABs !nTAB;
      print_t x;
      nTAB := !nTAB - 1

and output_exp oc exp = 
  let print_string = Printf.fprintf oc "%s" in
  let print_int = Printf.fprintf oc "%d" in
  let print_id = OutputId.output_t oc in
  let print_idl = OutputId.output_l oc in
  let print_TABs = output_TABs oc in
  let print_id_or_imm = output_id_or_imm oc in
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
  let op2' op x y =
    print_string (op ^ " ");
    print_id x;
    print_string " ";
    print_id_or_imm y;
    print_string "\n" in
  let op3' op x y z =
    print_string (op ^ " ");
    print_id x;
    print_string " ";
    print_id y;
    print_string " ";
    print_id_or_imm z;
    print_string "\n" in
  let opIf op id1 id2 t1 t2 =
    print_string (op ^ " ");
    print_id id1;
    print_string " ";
    print_id_or_imm id2;
    print_string "\n";
    nTAB := !nTAB + 1;
    print_TABs !nTAB;
    print_t t1;
    print_TABs !nTAB;
    print_t t2;
    nTAB := !nTAB - 1 in
  let opIfF op id1 id2 t1 t2 =
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
  match exp with
  | Nop -> print_string "Nop\n"
  | Set i -> Printf.fprintf oc "Set %d\n" i
  | FSetD d -> Printf.fprintf oc "FSetD %f\n" d
  | SetL x ->
      print_string "SetL ";
      print_idl x;
      print_string "\n"
  | Mov x -> op1 "Mov" x
  | Neg x -> op1 "Neg" x
  | Add (x,y) -> op2' "Add" x y
  | Sub (x,y) -> op2' "Sub" x y
  | SLL (x,y) -> op2' "SLL" x y
  | Ld (x,y) -> op2' "Ld" x y
  | St (x,y,z) -> op3' "St" x y z
  | FMovD x -> op1 "FMovD" x
  | FNegD x -> op1 "FNegD" x
  | FAddD (x,y) -> op2 "FAddD" x y
  | FSubD (x,y) -> op2 "FSubD" x y
  | FMulD (x,y) -> op2 "FMulD" x y
  | FDivD (x,y) -> op2 "FDivD" x y
  | LdDF (x,y) -> op2' "LdDF" x y
  | StDF (x,y,z) -> op3' "StDF" x y z
  | Comment s -> 
      print_string "Comment ";
      print_string s;
      print_string "\n"
  | IfEq (x,y,x',y') -> opIf "IfEq" x y x' y'
  | IfLE (x,y,x',y') -> opIf "IfLE" x y x' y'
  | IfGE (x,y,x',y') -> opIf "IfGE" x y x' y'
  | IfFEq (x,y,x',y') -> opIfF "IfFEq" x y x' y'
  | IfFLE (x,y,x',y') -> opIfF "IfFLE" x y x' y'
  | CallCls (x,l1,l2) -> 
      print_string "CallCls\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_id x;
      print_string "\n";
      print_TABs !nTAB;
      List.iter (fun id -> print_id id; print_string " ") l1;
      print_string "\n";
      print_TABs !nTAB;
      List.iter (fun id -> print_id id; print_string " ") l2;
      print_string "\n";
      nTAB := !nTAB - 1
  | CallDir (x,l1,l2) -> 
      print_string "CallDir\n";
      nTAB := !nTAB + 1;
      print_TABs !nTAB;
      print_idl x;
      print_string "\n";
      print_TABs !nTAB;
      List.iter (fun id -> print_id id; print_string " ") l1;
      print_string "\n";
      print_TABs !nTAB;
      List.iter (fun id -> print_id id; print_string " ") l2;
      print_string "\n";
      nTAB := !nTAB - 1
  | Save (x,y) -> op2 "Save" x y
  | Restore x -> op1 "Restore" x

and output_fundef oc fundef = 
  let print_string = Printf.fprintf oc "%s" in
  let print_id = OutputId.output_t oc in
  let print_idl = OutputId.output_l oc in
  let print_type = OutputType.output_t oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let { name = id; args = l1; fargs = l2; body = x; ret = ty } = fundef in
  print_string "FunDef\n";
  nTAB := !nTAB + 1;
  print_TABs !nTAB;
  print_idl id;
  print_string "\n";
  print_TABs !nTAB;
  print_string "/* args */\n";
  List.iter 
    (fun id -> print_TABs !nTAB; print_id id; print_string "\n")
    l1;
  print_TABs !nTAB;
  print_string "/* fargs */\n";
  List.iter 
    (fun id -> print_TABs !nTAB; print_id id; print_string "\n")
    l2;
  print_TABs !nTAB;
  print_t x;
  print_TABs !nTAB;
  print_type ty;
  print_string "\n";
  nTAB := !nTAB - 1

and output_prog oc prog =
  let print_string = Printf.fprintf oc "%s" in
  let print_float = Printf.fprintf oc "%f" in
  let print_idl = OutputId.output_l oc in
  let print_TABs = output_TABs oc in
  let print_t = output_t oc in
  let print_fundef = output_fundef oc in
  let Prog (l2,x) = prog in
  print_string "Prog\n";
  nTAB := !nTAB + 1;
  List.iter 
    (fun fundef -> print_TABs !nTAB; 
                   print_fundef fundef)
    l2;
  print_TABs !nTAB;
  print_t x;
  nTAB := !nTAB - 1
