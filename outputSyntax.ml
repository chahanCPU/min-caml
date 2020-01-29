open Syntax

let rec output_t' oc depth e =
  for i = 1 to depth do
    Printf.fprintf oc "\t"
  done;
  match e with
  | Unit -> 
      Printf.fprintf oc "Unit\n"
  | Bool(b) -> 
      Printf.fprintf oc "Bool %B\n" b
  | Int(i) -> 
      Printf.fprintf oc "Int %d\n" i
  | Float(f) -> 
      Printf.fprintf oc "Float %f\n" f
  | Not(e) ->
      Printf.fprintf oc "Not\n";
      output_t' oc (depth + 1) e
  | Neg(e) -> 
      Printf.fprintf oc "Neg\n";
      output_t' oc (depth + 1) e
  | Add(e1, e2) ->
      Printf.fprintf oc "Add\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Sub(e1, e2) ->
      Printf.fprintf oc "Sub\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Mul(e1, e2) ->
      Printf.fprintf oc "Mul\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Div(e1, e2) -> 
      Printf.fprintf oc "Div\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | FNeg(e) ->
      Printf.fprintf oc "FNeg\n";
      output_t' oc (depth + 1) e
  | FAdd(e1, e2) ->
      Printf.fprintf oc "FAdd\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | FSub(e1, e2) ->
      Printf.fprintf oc "FSub\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | FMul(e1, e2) ->
      Printf.fprintf oc "FMul\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | FDiv(e1, e2) -> 
      Printf.fprintf oc "FDiv\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Eq(e1, e2) -> 
      Printf.fprintf oc "Eq\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | LE(e1, e2) -> 
      Printf.fprintf oc "LE\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | If(e1, e2, e3) -> 
      Printf.fprintf oc "If\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2;
      output_t' oc (depth + 1) e3
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
  | Var(x, bindings) -> 
      Printf.fprintf oc "Var ";
      OutputId.output_t oc x;
      Printf.fprintf oc "\t[";
      let tmp = ref bindings in
      while !tmp <> [] do
        match !tmp with
        | [(alpha, t)] -> 
            OutputType.output_t oc t;
            Printf.fprintf oc " / ";
            OutputId.output_t oc alpha;
            tmp := []
        | (alpha, t) :: rest ->
            OutputType.output_t oc t;
            Printf.fprintf oc " / ";
            OutputId.output_t oc alpha;
            Printf.fprintf oc ", ";
            tmp := rest
        | _ -> ()
      done;
      Printf.fprintf oc "]\n"
  | LetRec(fundef, e) ->
      Printf.fprintf oc "LetRec\n";
      output_fundef' oc (depth + 1) fundef;
      output_t' oc depth e
  | App(e, es) -> 
      Printf.fprintf oc "App\n";
      output_t' oc (depth + 1) e;
      List.iter (fun e -> output_t' oc (depth + 1) e) es
  | Tuple(es) -> 
      Printf.fprintf oc "Tuple\n";
      List.iter (fun e -> output_t' oc (depth + 1) e) es
  | LetTuple(xts, e1, e2) ->
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
      output_t' oc (depth + 1) e1;
      output_t' oc depth e2
  | Array(e1, e2) -> 
      Printf.fprintf oc "Array\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Get(e1, e2) -> 
      Printf.fprintf oc "Get\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2
  | Put(e1, e2, e3) -> 
      Printf.fprintf oc "Put\n";
      output_t' oc (depth + 1) e1;
      output_t' oc (depth + 1) e2;
      output_t' oc (depth + 1) e3

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
