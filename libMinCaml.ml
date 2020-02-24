(* MinCamlのライブラリ *)

(* 予約語は他の意味で使えないルールで *)
(* いや、型情報をtyping.mlではなく、ここで与えれば上手くいくのでは？？ *)

(* notとかint_of_floatとかをlexerで消すこと *)

(* typing.ml参照 *)
(* 外部関数に自由に出現する型は単相かつ型変数を含まないとする *)


(* float (1) *)
(* let rec fequal x y = (x +. 0. = y) in    (* +0.0はx,y がfloatだと教えるため。最適化で消したい *) *)
(* let rec fless x y = (x +. 0. < y) in *)

let rec fispos x = (x > 0.) in
let rec fisneg x = (x < 0.) in
let rec fiszero x = (x = 0.) in

(* let rec not x = if x then false else true in *)
(* let rec xor x y = if x then not y else y in *)

(* float (2) *)
let rec fhalf x = x *. 0.5 in
let rec fsqr x = x *. x in

let rec fneg x = -. x in
let rec floor x = 
  let y = float_of_int (int_of_float x) in
  if x >= 0. then y else if x = y then x else y -. 1.0 in   (* 怪しいかも。x=yは整数であることを意図 *)

let rec cos x = 
  let pi = 3.141592654 in
  if x >= 0.0 then
    if x <= pi then
      let x2 = x *. x in
      1.0 -. x2 *. (0.5 -. x2 *. (0.04166666667 -. x2 *. (0.001388888889 -. x2 *. 0.00002480158730)))
    else
      if x <= 2.0 *. pi then
        -. cos(x -. pi)
      else
        cos(x -. 2.0 *. pi)
  else
    cos(-. x)
in
let rec sin x = 
  let pi = 3.141592654 in
  if x >= 0.0 then
    if x <= pi then
      let x2 = x *. x in
      x *. (1.0 -. x2 *. (0.1666666667 -. x2 *. (0.008333333333 -. x2 *. 0.0001984126984)))
    else
      if x <= 2.0 *. pi then 
        -. sin(x -. pi)
      else
        sin(x -. 2.0 *. pi)
  else
    -. sin(-. x)
in
let rec tan x = 
  let pi = 3.141592654 in
  if x >= 0.0 then
    if x <= 0.5 *. pi then
      let x2 = x *. x in
      x *. (1.0 +. x2 *. (0.333333333 +. x2 *. (0.133333333 +. x2 *. 0.053968254)))
    else
      tan(x -. pi)
  else
    -. tan(-. x)
in
let rec atan x =
  let x2 = x *. x in
  x *. (1.0 -. x2 *. (0.3333333333 -. x2 *. (0.2 -. x2 *. 0.1428571429)))
in

(* 3桁以内の非負整数のみに対応 *)
let rec print_int x =
  if x < 10 then print_char (x + 48) else
  if x < 100 then (let y = x / 10 in print_char (y + 48); print_char (x - y * 10 + 48)) else 
  (let y = x / 100 in let z = x - y * 100 in let w = z / 10 in let u = z - w * 10 in print_char (y + 48); print_char (w + 48); print_char (u + 48))
in

()
