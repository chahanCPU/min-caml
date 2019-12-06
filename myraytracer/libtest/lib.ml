(* rec なくせないか *)
(* min-camlは関数定義はすべてlet recだったわ *)

(* アセンブリで書くやつと、min-camlで書くやつ *)
(* 前者はparser変える? asm.ml変える? Asm.exp変えなきゃダメそう とか ---> 後で考えよう *)
(* 前者はout関連とか基礎的なものに とか *)

(* miniMLRuntime.mlを参照 *)


(* float (1) *)
let rec fequal x y = (x = y) in
let rec fless x y = x < y in

let rec fispos x = x > 0.0 in
let rec fisneg x = x < 0.0 in
let rec fiszero x = (x = 0.0) in

(* int *)    (* lexerであるので略 *)
(* external (=) : int -> int -> bool = "%equal" *)
(* external (<>) : int -> int -> bool = "%notequal" *)
(* external (<) : int -> int -> bool = "%lessthan" *)
(* external (>) : int -> int -> bool = "%greaterthan" *)
(* external (<=) : int -> int -> bool = "%lessequal" *)
(* external (>=) : int -> int -> bool = "%greaterequal" *)

(* external (+) : int -> int -> int = "%addint" *)
(* external (-) : int -> int -> int = "%subint" *)
(* external ( * ) : int -> int -> int = "%mulint"    ない *)
(* external (/) : int -> int -> int = "%divint"    ない *)

(* logic *)
(* external xor : bool -> bool -> bool = "%notequal" *)
let rec xor x y = (x <> y) in
let rec not x = if x = true then false else true in

(* float (2) *)
let rec fhalf x = x *. 0.5 in
let rec fsqr x = x *. x in
(* external (+.) : float -> float -> float = "%addfloat"
external (-.) : float -> float -> float = "%subfloat"
external ( *. ) : float -> float -> float = "%mulfloat"
external (/.) : float -> float -> float = "%divfloat" *)

let rec fabs x = if x >= 0 then x else -x in
let rec fneg x = -x in    (* アセンブリのライブラリで書かなくても、fneg使ってくれるよな *)
(* let rec sqrt x = ライブラリ(アセンブリで書く) *)
(* let rec floor x = float_of_int (int_of_float (x -. 0.5)) in  小数部分が0.5ちょうどのとき怪しい 小数点以下切り捨て *)
let rec floor x = float_of_int (int_of_float x) in  (* 小数部分が0.5ちょうどのとき怪しい *) (* 小数点以下切り捨て *)
(* ocamlのint_of_floatは浮動小数点小数を切り捨て
   asemblyのftoiは? 切り捨てで行こう *)

(* 以下アセンブリのライブラリで書く　後にはasmのexpに登録すること *)
(* external int_of_float : float -> int = "%intoffloat" *)
(* external float_of_int : int -> float = "%floatofint" *)

(* external cos : float -> float = "cos_float" "cos" "float" *)
(* external sin : float -> float = "sin_float" "sin" "float" *)
(* external atan : float -> float = "atan_float" "atan" "float" *)

external int_of_float : float -> int = "%intoffloat"
external float_of_int : int -> float = "%floatofint"
		
external create_array : int -> 'a -> 'a array = "caml_make_vect"

(* I/O *)

let print_char x = Pervasives.print_char (char_of_int x)
let print_int = Pervasives.print_int

let buf = Buffer.create 16

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
    Failure _ -> failwith ((Buffer.contents buf) ^ ": int conversion failed.")


(* let rec fequal x y = in
let rec fless x y = in
let rec fisneg x = in
let rec fiszero x = x = 0.0 in
let rec fhalf x = x *. 0.5 in
let rec fsqr x = x *. x in
let rec  *)

let rec taylor_cos x =
	let x2 = x *. x in
		1.0 -. x2 *. (0.5 -. x2 *. (0.04166368 -. x2 *. 0.0013695068))
in
let rec taylor_sin x =
	let x2 = x *. x in
		x *. (1.0 -. x2 *. (0.16666668 -. x2 *. (0.008332824 -. x2 *. 0.00019587841)))
in
let rec mycos x =
	if x >= 0.0 then
		if x >  6.28318548202514 then
			mycos (x -.  6.28318548202514)
		else
			if x < 3.1415927410 then
				if x < 1.5707963705 then
					if x < 0.785398185 then
						taylor_cos x
					else
						taylor_sin (1.5707963705 -. x)
				else
					if x < 2.35619455 then
						0.0 -. taylor_sin (x -. 1.5707963705)
					else
						0.0 -. taylor_cos (3.1415927410 -. x)
			else
				let y = x -. 3.1415927410 in
					if y < 1.5707963705 then
						if y < 0.785398185 then
							(* 0.0 -. taylor_sin y *)
							0.0 -. taylor_cos y
						else
							(* 0.0 -. taylor_cos (1.5707963705 -. y) *)
							0.0 -. taylor_sin (1.5707963705 -. y)
					else
						if y < 2.35619455 then
							taylor_sin (y -. 1.5707963705)
						else
							taylor_cos (3.1415927410 -. y)
	else
		mycos (0.0 -. x)
in
let rec mysin x =
    if x >= 0.0 then
        if x >  6.28318548202514 then
            mysin (x -.  6.28318548202514)
        else
            if x < 3.1415927410 then
                if x < 1.5707963705 then
                    if x < 0.785398185 then
                        taylor_sin x
                    else
                        taylor_cos (1.5707963705 -. x)
                else
                    if x < 2.35619455 then
                        taylor_cos (x -. 1.5707963705)
                    else
                        taylor_sin (3.1415927410 -. x)
            else
                let y = x -. 3.1415927410 in
                    if y < 1.5707963705 then
                        if y < 0.785398185 then
                            0.0 -. taylor_sin y
                        else
                            0.0 -. taylor_cos (1.5707963705 -. y)
                    else
                        if y < 2.35619455 then
                            0.0 -. taylor_cos (y -. 1.5707963705)
                        else
                            0.0 -. taylor_sin (3.1415927410 -. y)
    else
        0.0 -. mysin (0.0 -. x)
in
let rec taylor_atan x =
    let x2 = x *. x in
        x *. (1.0 -. x2 *. (0.3333333 -. x2 *. (0.2 -. x2 *. (0.142857142 -. x2 *. (0.111111104 -. x2 *. (0.08976446 -. 0.060035485 *. x2))))))
in
let rec myatan x =
	if x >= 0.0 then
		if x < 0.4375 then
			taylor_atan x
		else
			(* if x < 2.4375 then *)
			if x < 2.35619455 then
				0.78539818 +. taylor_atan ((x -. 1.0) /. (x +. 1.0))
			else
				1.57079637 -. taylor_atan (1.0 /. x)
		else
			(* let y = 0.0 -. x in *)
				(* if y < 0.4375 then *)
					(* 0.0 -. (0.78539818 +. taylor_atan ((y -. 1.0) /. (y +. 1.0))) *)
				(* else *)
					(* 0.0 -. (1.57079637 -. taylor_atan (1.0 /. y)) *)
			let y = 0.0 -. x in
			0.0 -. (myatan y)
in 
	for i = -100000000 to 100000000 do
		let v = (float_of_int i) *. 0.0001 in
			assert (abs_float ((mycos v) -. (cos v)) < 0.00001);
			assert (abs_float ((mysin v) -. (sin v)) < 0.00001);
	done;
	for i = -10000000 to 10000000 do
		let v = (float_of_int i) *. 0.001 in
			(* assert (abs_float ((myatan v) -. (atan v)) < 0.0000001) *)
			(if abs_float ((myatan v) -. (atan v)) < 0.00001 then () else (Printf.printf "%f\t誤%f\t正%f\n" v (myatan v) (atan v)))
	done;
	() ;

  (* let v = -100.0 in *)
  (* print_float (mycos v); print_string " "; print_float (cos v); print_newline (); *)
  (* print_float (mysin v); print_string " "; print_float (sin v); print_newline (); *)
  (* print_float (myatan v); print_string " "; print_float (atan v); print_newline (); *)


