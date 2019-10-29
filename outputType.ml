open Type
open Printf

let rec output_t oc = function
  | Unit -> fprintf oc "unit"
  | Bool -> fprintf oc "bool"
  | Int -> fprintf oc "int"
  | Float -> fprintf oc "float"
  | Fun (l,t) ->
      fprintf oc "(";
      List.iter (fun t -> output_t oc t; fprintf oc " -> ") l;
      output_t oc t;
      fprintf oc ")"
  | Tuple l ->
      fprintf oc "(";
      let temp = ref l in
      while !temp <> [] do
        match !temp with
        | t::t'::ts -> output_t oc t; fprintf oc ", "; temp := t'::ts
        | t::ts -> output_t oc t; temp := ts
        | [] -> ()
      done;
      fprintf oc ")"
  | Array t ->
      fprintf oc "(";
      output_t oc t;
      fprintf oc " array)"
  | Var r ->
      (match !r with
       | Some t -> fprintf oc "(var (some "; output_t oc t; fprintf oc "))" 
       | None -> fprintf oc "(var none)")

let rec string_of_t = function
	| Unit -> "unit"
	| Bool -> "bool"
	| Int -> "int"
	| Float -> "float"
	| Fun (l,t) ->
			"(" ^ 
			(List.fold_right (fun t s -> (string_of_t t) ^ " -> " ^ s) l "") ^
			(string_of_t t) ^
			")"
	| Tuple l ->
			"(" ^
			(List.fold_right (fun t s -> match s with "" -> string_of_t t 
																							| _ -> (string_of_t t) ^ ", " ^ s) l "") ^
			")"
	| Array t -> "(" ^ (string_of_t t) ^ " array)"
	| Var r ->
			(match !r with
			 | Some t -> "(var (some " ^ (string_of_t t) ^ "))"
			 | None -> "(var none)")
