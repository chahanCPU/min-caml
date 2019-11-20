let rec app f x = f x in
let rec app2 f x = f x in
let appapp = app2 app in
let rec f x = x + 3 in
print_int (appapp f 2)
