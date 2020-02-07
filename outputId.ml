open Id

let output_t oc x = Printf.fprintf oc "%s" x

let output_l oc (L(x)) = Printf.fprintf oc "L%s" x
