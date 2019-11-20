let x = 1 in
let y = 2 in
let z = (fun x y -> x - y + 10) (x + 21) (y - 32) in
print_int z
