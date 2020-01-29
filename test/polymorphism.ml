let rec f x = let x = x in let rec f x = x in let x = x in (f f) x in
let rec g x = let x = x in f x in
let x = if f true then g 100 else int_of_float (f 0.0) in
print_int x;
print_int (f 100)
