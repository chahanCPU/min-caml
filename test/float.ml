(* このテストを実行する場合は、Main.file等を呼び出す前に
   Typing.extenvを:=等で書き換えて、あらかじめsinやcosなど
   外部関数の型を陽に指定する必要があります（そうしないと
   MinCamlでは勝手にint -> intと推論されるため）。 *)
(* 型推論のため　ここから *)
let a = int_of_float 21.0 in
let a = sin 1.0 in
let a = cos 1.0 in
let a = sqrt 1.0 in
let a = abs_float 1.0 in
let a = float_of_int 1 in
(* 型推論のため　ここまで *)
print_int
  (int_of_float
     ((sin (cos (sqrt (abs_float (-12.3))))
         +. 4.5 -. 6.7 *. 8.9 /. 1.23456789)
        *. float_of_int 1000000))
