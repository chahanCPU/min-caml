open Id
open Printf

let output_t oc (x : t) =
  fprintf oc "%s" x

let output_l oc (x : l) =
  let L x = x in
  fprintf oc "L%s" x

let string_of_t x = x

let string_of_l x =
  let L x = x in
  "L " ^ x
