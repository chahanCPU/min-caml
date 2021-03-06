open Type

let rec output_t oc = function
  | Unit -> Printf.fprintf oc "unit"
  | Bool -> Printf.fprintf oc "bool"
  | Int -> Printf.fprintf oc "int"
  | Float -> Printf.fprintf oc "float"
  | Fun(ts, t) -> 
      Printf.fprintf oc "(";
      List.iter (fun t -> output_t oc t; Printf.fprintf oc " -> ") ts;
      output_t oc t;
      Printf.fprintf oc ")"
  | Tuple(ts) ->
      Printf.fprintf oc "(";
      let tmp = ref ts in
      while !tmp <> [] do
        match !tmp with
        | [t] -> output_t oc t; tmp := []
        | t :: ts -> output_t oc t; Printf.fprintf oc " * "; tmp := ts
        | _ -> ()
      done;
      Printf.fprintf oc ")"
  | Array(t) ->
      output_t oc t;
      Printf.fprintf oc " array"
  | Var(alpha) ->
      OutputId.output_t oc alpha
  | Scheme(vars, t) ->
      Printf.fprintf oc "∀";
      let tmp = ref vars in
      while !tmp <> [] do
        match !tmp with
        | [alpha] -> OutputId.output_t oc alpha; tmp := []
        | alpha :: vars -> OutputId.output_t oc alpha; Printf.fprintf oc ", "; tmp := vars
        | _ -> ()
      done;
      Printf.fprintf oc ". ";
      output_t oc t
