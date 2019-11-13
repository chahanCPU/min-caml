let rec f a = a + 15 in
let rec g b = b - 7 in
let x = -9 in
let y = (if x <= 0 then f 1 else 2) in
let z = (if x <= 3 then x - 4 else g 5) in
x - y - z
