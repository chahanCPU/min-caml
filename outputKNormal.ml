open KNormal

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
  | LetRec(fundef, e) ->
      Printf.fprintf oc "LetRec\n";
      output_fundef' oc (depth + 1) fundef;
      output_t' oc depth e
  | App(x, ys) ->
      Printf.fprintf oc "App ";
      OutputId.output_t oc x;
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
  | GlobalTuple(xs) ->
      Printf.fprintf oc "GlobalTuple(";
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
  | Array(x, y) ->
      Printf.fprintf oc "Array ";
      OutputId.output_t oc x;
      Printf.fprintf oc " ";
      OutputId.output_t oc y;
      Printf.fprintf oc "\n"
  | GlobalArray(i, x) ->
      Printf.fprintf oc "GlobalArray %d " i;
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
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
  | FAbs(x) ->
      Printf.fprintf oc "FAbs ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | Sqrt(x) ->
      Printf.fprintf oc "Sqrt ";
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
  | Out(x) ->
      Printf.fprintf oc "Out ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | OutInt(x) ->
      Printf.fprintf oc "OutInt ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  | In -> 
      Printf.fprintf oc "In\n"
  | BTOF(x) ->
      Printf.fprintf oc "BTOF ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\n"
  (* | ExtFunApp(x, ys) ->
      Printf.fprintf oc "ExtFunApp ";
      OutputId.output_t oc x;
      List.iter (fun y -> Printf.fprintf oc " "; OutputId.output_t oc y) ys;
      Printf.fprintf oc "\n" *)

and output_fundef' oc depth { name = (x, t); args = yts; body = e } =
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  OutputId.output_t oc x;
  Printf.fprintf oc " : ";
  OutputType.output_t oc t;
  Printf.fprintf oc "\n";
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
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
  output_t' oc depth e

let output_t oc e = output_t' oc 0 e

let output_fundef oc fundef = output_fundef' oc 0 fundef
