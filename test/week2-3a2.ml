let rec f x y =
  let z = y in
  if y = 0 then z + x else f z 0 in
f 1 1
