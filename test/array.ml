let rec f a b i j = a.(i) + (int_of_float b.(j)) in
let a = Array.make 100 22 in
let b = Array.make 1000 17.0 in
let z = f a b 13 16 in
print_int z
