open Asm

let output_id_or_imm oc = function 
  | V(x) -> OutputId.output_t oc x
  | C(i) -> Printf.fprintf oc "%d" i

let rec output_t' oc depth e =
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  match e with
  | Ans(exp) ->
      Printf.fprintf oc "Ans\n";
      output_exp' oc (depth + 1) exp
  | Let((x, t), exp, e) ->
      Printf.fprintf oc "Let\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      OutputId.output_t oc x;
      Printf.fprintf oc " : ";
      OutputType.output_t oc t;
      Printf.fprintf oc "\n";
      output_exp' oc (depth + 1) exp;
      output_t' oc depth e

and output_exp' oc depth exp = 
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  match exp with
  | Nop -> 
      Printf.fprintf oc "Nop\n"
  | Set(i) -> 
      Printf.fprintf oc "Set %d\n" i
  | FSetD(f) -> 
      Printf.fprintf oc "FSetD %f\n" f
  | SetL(Id.L(x)) ->
      Printf.fprintf oc "SetL ";
      OutputId.output_l oc (Id.L(x));
      Printf.fprintf oc "\n"
  | Mov(x) -> 
      Printf.fprintf oc "Mov ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Neg(x) ->
      Printf.fprintf oc "Neg ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Add(x, y') -> 
      Printf.fprintf oc "Add ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n"
  | Sub(x, y') -> 
      Printf.fprintf oc "Sub ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n"
  | Mul(x, y) ->
      Printf.fprintf oc "Mul ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | Div(x, y) -> 
      Printf.fprintf oc "Div ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | SLL(x, y') -> 
      Printf.fprintf oc "SLL ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n"
  | SRA(x, i) ->
      Printf.fprintf oc "SRA ";
      OutputId.output_t oc x;
      Printf.fprintf oc " %d\n" i
  | Ld(x, y') -> 
      Printf.fprintf oc "Ld ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n"
  | St(x, y, z') -> 
      Printf.fprintf oc "St ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc " ";
      output_id_or_imm oc z';
      Printf.fprintf oc "\n"
  | FMovD(x) ->
      Printf.fprintf oc "FMovD ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FNegD(x) ->
      Printf.fprintf oc "FNegD ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FAddD(x, y) -> 
      Printf.fprintf oc "FAddD ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | FSubD (x,y) -> 
      Printf.fprintf oc "FSubD ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | FMulD (x,y) -> 
      Printf.fprintf oc "FMulD ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  (* | FDivD (x,y) -> op2 "FDivD" x y *)
  | FInv(x) -> 
      Printf.fprintf oc "FInv ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | LdDF(x, y') -> 
      Printf.fprintf oc "LdDF ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n"
  | StDF(x, y, z') -> 
      Printf.fprintf oc "StDF ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc " ";
      output_id_or_imm oc z';
      Printf.fprintf oc "\n"
  | Comment(s) -> 
      Printf.fprintf oc "Comment %s\n" s
  | IfEq(x, y', e1, e2) -> 
      Printf.fprintf oc "IfEq ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | IfLE(x, y', e1, e2) -> 
      Printf.fprintf oc "IfLE ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | IfGE(x, y', e1, e2) ->
      Printf.fprintf oc "IfGE ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      output_id_or_imm oc y';
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | IfFEq (x, y, e1, e2) -> 
      Printf.fprintf oc "IfFEq ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | IfFLE(x, y, e1, e2) -> 
      Printf.fprintf oc "IfFLE ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | CallCls(x, ys, zs) -> 
      Printf.fprintf oc "CallCls\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<closure address> ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<integer arguments> ";
      let tmp = ref ys in
      while !tmp <> [] do
        match !tmp with
        | [y] -> OutputId.output_t oc y; tmp := []
        | y :: ys -> OutputId.output_t oc y; Printf.fprintf oc ", "; tmp := ys 
        | _ -> ()
      done;
      Printf.fprintf oc "\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<float arguments> ";
      let tmp = ref zs in
      while !tmp <> [] do
        match !tmp with
        | [z] -> OutputId.output_t oc z; tmp := []
        | z :: zs -> OutputId.output_t oc z; Printf.fprintf oc ", "; tmp := zs 
        | _ -> ()
      done;
      Printf.fprintf oc "\n"
  | CallDir(Id.L(x), ys, zs) -> 
      Printf.fprintf oc "CallDir\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<closure address> ";
      OutputId.output_l oc (Id.L(x));
      Printf.fprintf oc "\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<integer arguments> ";
      let tmp = ref ys in
      while !tmp <> [] do
        match !tmp with
        | [y] -> OutputId.output_t oc y; tmp := []
        | y :: ys -> OutputId.output_t oc y; Printf.fprintf oc ", "; tmp := ys 
        | _ -> ()
      done;
      Printf.fprintf oc "\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "<float arguments> ";
      let tmp = ref zs in
      while !tmp <> [] do
        match !tmp with
        | [z] -> OutputId.output_t oc z; tmp := []
        | z :: zs -> OutputId.output_t oc z; Printf.fprintf oc ", "; tmp := zs 
        | _ -> ()
      done;
      Printf.fprintf oc "\n"
  | Save(x, y) ->
      Printf.fprintf oc "Save ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | Restore(x) ->
      Printf.fprintf oc "Restore ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Out(x) -> 
      Printf.fprintf oc "Out ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | OutInt(x) ->
      Printf.fprintf oc "OutInt ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FAbs(x) -> 
      Printf.fprintf oc "FAbs ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FSqrt(x) ->
      Printf.fprintf oc "FSqrt ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FTOI(x) -> 
      Printf.fprintf oc "FTOI ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | ITOF(x) ->
      Printf.fprintf oc "ITOF ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Cos(x) ->
      Printf.fprintf oc "Cos ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Sin(x) -> 
      Printf.fprintf oc "Sin ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Tan(x) -> 
      Printf.fprintf oc "Tan ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | ATan(x) -> 
      Printf.fprintf oc "ATan ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"

let output_fundef' oc depth { name = Id.L(x); args = ys; fargs = zs; body = e; ret = t } = 
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "FunDef\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<name> ";
  OutputId.output_l oc (Id.L(x));
  Printf.fprintf oc "\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<args> ";
  let tmp = ref ys in
  while !tmp <> [] do
    match !tmp with
    | [y] -> OutputId.output_t oc y; tmp := []
    | y :: ys -> OutputId.output_t oc y; Printf.fprintf oc ", "; tmp := ys 
    | _ -> ()
  done;
  Printf.fprintf oc "\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<fargs> ";
  let tmp = ref zs in
  while !tmp <> [] do
    match !tmp with
    | [z] -> OutputId.output_t oc z; tmp := []
    | z :: zs -> OutputId.output_t oc z; Printf.fprintf oc ", "; tmp := zs 
    | _ -> ()
  done;
  Printf.fprintf oc "\n";
  output_t' oc (depth + 1) e;
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<ret> ";
  OutputType.output_t oc t;
  Printf.fprintf oc "\n"

let output_prog' oc depth (Prog(fundefs, e)) =
  List.iter (output_fundef' oc depth) fundefs;
  output_t' oc depth e

let output_t oc e = output_t' oc 0 e

let output_exp oc exp = output_exp' oc 0 exp

let output_fundef oc fundef = output_fundef' oc 0 fundef

let output_prog oc prog = output_prog' oc 0 prog
