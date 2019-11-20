let rec f x y z = x + y + z in
let f = f 1 in
let f = f 2 in
let f = f 3 in
print_int f
