let rec app f x = f x in
let rec f x y = x + y in
let rec g x =
  let rec h y = x + y in h in
let f = app f 1 in
let g = app g 3 in
print_int ((f 2) + (g 4))
