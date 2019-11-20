(* float (1) *)
let rec fequal x y = (x = y) in
let rec fless x y = (x < y) in

let rec fispos x = (x > 0.) in
let rec fisneg x = (x < 0.) in
let rec fiszero x = (x = 0.) in

(* int *)
(* external (=) : int -> int -> bool = "%equal" *)
(* external (<>) : int -> int -> bool = "%notequal" *)
(* external (<) : int -> int -> bool = "%lessthan" *)
(* external (>) : int -> int -> bool = "%greaterthan" *)
(* external (<=) : int -> int -> bool = "%lessequal" *)
(* external (>=) : int -> int -> bool = "%greaterequal" *)

(* external (+) : int -> int -> int = "%addint" *)
(* external (-) : int -> int -> int = "%subint" *)
(* external ( * ) : int -> int -> int = "%mulint" *)
(* external (/) : int -> int -> int = "%divint" *)

(* logic *)
let rec xor x y = (x <> y) in
let rec not x = if x then false else true in

(* float (2) *)
let rec fhalf x = x *. 0.5 in
let rec fsqr x = x *. x in
(* external (+.) : float -> float -> float = "%addfloat" *)
(* external (-.) : float -> float -> float = "%subfloat" *)
(* external ( *. ) : float -> float -> float = "%mulfloat" *)
(* external (/.) : float -> float -> float = "%divfloat" *)

let rec fabs x = if x >= 0. then x else -x in
let rec fneg x = -x in
(* external sqrt : float -> float = "sqrt_float" "sqrt" "float" *)
let rec floor x = 
  let y = float_of_int (int_of_float x) in
  if x >= 0. then y else if x = y then x else y -. 1.    (* 怪しいかも。x=yは整数であることを意図 *)

(* external int_of_float : float -> int = "%intoffloat" *)
(* external float_of_int : int -> float = "%floatofint" *)

external cos : float -> float = "cos_float" "cos" "float"
external sin : float -> float = "sin_float" "sin" "float"
external atan : float -> float = "atan_float" "atan" "float"

(* external int_of_float : float -> int = "%intoffloat" *)
(* external float_of_int : int -> float = "%floatofint" *)

(* external create_array : int -> 'a -> 'a array = "caml_make_vect" *)

(* I/O *)

let rec print_char x = print_byte x in
(* let print_int = Pervasives.print_int *)

(* let buf = Buffer.create 16

let rec read_token in_token =
  try
    let c = input_char stdin in
    match c with
      ' ' | '\t' | '\r' | '\n' ->
	if in_token then ()
	else read_token false
    | _ ->
	Buffer.add_char buf c;
	read_token true
  with
    End_of_file ->
      if in_token then () else raise End_of_file

let read_float () = 
  Buffer.clear buf;
  read_token false;
  try
    float_of_string (Buffer.contents buf)
  with
    Failure _ -> failwith ((Buffer.contents buf) ^ ": float conversion failed.")

let read_int () = 
  Buffer.clear buf;
  read_token false;
  try
    int_of_string (Buffer.contents buf)
  with
    Failure _ -> failwith ((Buffer.contents buf) ^ ": int conversion failed.") *)

();
