let rec f a b i j = a.(i) + (int_of_float b.(j)) in
let a = Array.make 4 22 in
let b = Array.make 3 17.0 in
let z = f a b 1 2 in
print_int z
