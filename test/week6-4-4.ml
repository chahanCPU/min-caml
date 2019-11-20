let rec app f x = f x in
let rec f x y = x + y in
let f = app f 1 in
print_int (f 2)
