let f = (fun x y z -> x - y + z) 22 in
let g = f 2 in
let z = g 10 in
print_int z
