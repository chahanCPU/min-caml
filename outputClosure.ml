open Closure

let output_closure' oc depth { entry = Id.L(x); actual_fv = ys } = 
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "Closure\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<entry> ";
  OutputId.output_l oc (Id.L(x));
  Printf.fprintf oc "\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<actual_fv> ";
  let tmp = ref ys in
  while !tmp <> [] do
    match !tmp with
    | [y] -> OutputId.output_t oc y; tmp := []
    | y :: ys -> OutputId.output_t oc y; Printf.fprintf oc ", "; tmp := ys 
    | _ -> ()
  done;
  Printf.fprintf oc "\n"

let rec output_t' oc depth e =
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  match e with
  | Unit -> 
      Printf.fprintf oc "Unit\n"
  | Int(i) ->
      Printf.fprintf oc "Int %d\n" i
  | Float(f) ->
      Printf.fprintf oc "Float %f\n" f
  | Neg(x) ->
      Printf.fprintf oc "Neg ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Add(x, y) ->
      Printf.fprintf oc "Add ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | Sub(x, y) ->
      Printf.fprintf oc "Sub ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
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
  | FNeg(x) ->
      Printf.fprintf oc "FNeg ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | FAdd(x, y) ->
      Printf.fprintf oc "FAdd ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | FSub(x, y) ->
      Printf.fprintf oc "FSub ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | FMul(x, y) ->
      Printf.fprintf oc "FMul ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | FDiv(x, y) ->
      Printf.fprintf oc "FDiv ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | IfEq(x, y, e1, e2) ->
      Printf.fprintf oc "IfEq ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | IfLE(x, y, e1, e2) ->
      Printf.fprintf oc "IfLE ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Let((x, t), e1, e2) ->
      Printf.fprintf oc "Let\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      OutputId.output_t oc x;
      Printf.fprintf oc " : ";
      OutputType.output_t oc t;
      Printf.fprintf oc "\n";
      output_t' oc (depth + 1) e1;
      output_t' oc depth e2
  | Var(x) ->
      Printf.fprintf oc "Var ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | MakeCls((x, t), cls, e) ->
      Printf.fprintf oc "MakeCls\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      OutputId.output_t oc x;
      Printf.fprintf oc " : ";
      OutputType.output_t oc t;
      Printf.fprintf oc "\n";
      output_closure' oc (depth + 1) cls;
      output_t' oc depth e
  | AppCls(x, ys) ->
      Printf.fprintf oc "AppCls ";
      OutputId.output_t oc x;
      List.iter (fun y -> Printf.fprintf oc " "; OutputId.output_t oc y) ys;
      Printf.fprintf oc "\n"
  | AppDir(Id.L(x), ys) ->
      Printf.fprintf oc "AppDir ";
      OutputId.output_l oc (Id.L(x));
      List.iter (fun y -> Printf.fprintf oc " "; OutputId.output_t oc y) ys;
      Printf.fprintf oc "\n"
  | Tuple(xs) ->
      Printf.fprintf oc "Tuple(";
      let tmp = ref xs in
      while !tmp <> [] do
        match !tmp with
        | [x] -> OutputId.output_t oc x; tmp := []
        | x :: xs -> OutputId.output_t oc x; Printf.fprintf oc ", "; tmp := xs
        | _ -> ()
      done;
      Printf.fprintf oc ")\n"
  | LetTuple(xts, y, e) ->
      Printf.fprintf oc "LetTuple\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      Printf.fprintf oc "(";
      let tmp = ref xts in
      while !tmp <> [] do
        match !tmp with
        | [(x, t)] ->
            OutputId.output_t oc x;
            Printf.fprintf oc " : ";
            OutputType.output_t oc t;
            tmp := []
        | (x, t) :: xts ->
            OutputId.output_t oc x;
            Printf.fprintf oc " : ";
            OutputType.output_t oc t;
            Printf.fprintf oc ", ";
            tmp := xts 
        | _ -> ()
      done;
      Printf.fprintf oc ")\n";
      for i = 1 to depth + 1 do
        Printf.fprintf oc "\t"
      done;
      OutputId.output_t oc y;
      Printf.fprintf oc "\n";
      output_t' oc depth e
  | Get(x, y) ->
      Printf.fprintf oc "Get ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | Put(x, y, z) ->
      Printf.fprintf oc "Put ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc " ";
      OutputId.output_t oc z;
      Printf.fprintf oc "\n"
  | ExtArray(Id.L(x)) ->
      Printf.fprintf oc "ExtArray ";
      OutputId.output_l oc (Id.L(x));
      Printf.fprintf oc "\n"
  
let output_fundef' oc depth { name = (Id.L(x), t); args = yts; formal_fv = zts; body = e } =
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "FunDef\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<name> ";
  OutputId.output_l oc (Id.L(x));
  Printf.fprintf oc " : ";
  OutputType.output_t oc t;
  Printf.fprintf oc "\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<args> ";
  let tmp = ref yts in
  while !tmp <> [] do
    match !tmp with
    | [(y, t)] -> 
        OutputId.output_t oc y; 
        Printf.fprintf oc " : "; 
        OutputType.output_t oc t;
        tmp := []
    | (y, t) :: yts ->
        OutputId.output_t oc y; 
        Printf.fprintf oc " : "; 
        OutputType.output_t oc t;
        Printf.fprintf oc ", ";
        tmp := yts 
    | _ -> ()
  done;
  Printf.fprintf oc "\n";
  for i = 1 to depth + 1 do
    Printf.fprintf oc "\t"
  done;
  Printf.fprintf oc "<formal_fv> ";
  let tmp = ref zts in
  while !tmp <> [] do
    match !tmp with
    | [(z, t)] -> 
        OutputId.output_t oc z; 
        Printf.fprintf oc " : "; 
        OutputType.output_t oc t;
        tmp := []
    | (z, t) :: zts ->
        OutputId.output_t oc z; 
        Printf.fprintf oc " : "; 
        OutputType.output_t oc t;
        Printf.fprintf oc ", ";
        tmp := zts 
    | _ -> ()
  done;
  Printf.fprintf oc "\n";
  output_t' oc (depth + 1) e

let output_prog' oc depth (Prog(fundefs, e)) =
  List.iter (output_fundef' oc depth) fundefs;
  output_t' oc depth e

let output_closure oc cls = output_closure' oc 0 cls

let output_t oc e = output_t' oc 0 e

let output_fundef oc fundef = output_fundef' oc 0 fundef

let output_prog oc prog = output_prog' oc 0 prog
