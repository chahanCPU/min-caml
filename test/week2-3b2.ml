let x = 100 in
let rec f x =
if x > 0 then 0 else f (x + 1) in f x
