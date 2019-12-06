let i1 = read_int () in
let i2 = read_int () in
let f1 = read_float () in
let f2 = read_float () in
let i = i1 + i2 in
let f = f1 +. f2 in
print_int (i + (int_of_float f))
