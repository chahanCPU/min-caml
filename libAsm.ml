(* typing.ml参照 *)
(* 外部関数に自由に出現する型は単相かつ型変数を含まないとする *)

open Syntax

let var x = Var(x, [])

let fundefs = [
  { name = ("fequal", Type.Fun([Type.Float; Type.Float], Type.Bool));
    args = [("x", Type.Float); ("y", Type.Float)]; 
    body = Eq(var("x"), var("y")) };
  { name = ("fless", Type.Fun([Type.Float; Type.Float], Type.Bool));
    args = [("x", Type.Float); ("y", Type.Float)]; 
    body = Not(LE(var("y"), var("x"))) };

  { name = ("xor", Type.Fun([Type.Bool; Type.Bool], Type.Bool));
    args = [("x", Type.Bool); ("y", Type.Bool)]; 
    body = Not(Eq(var("x"), var("y"))) };
  { name = ("not", Type.Fun([Type.Bool], Type.Bool));
    args = [("x", Type.Bool)]; 
    body = Not(var("x")) };

  { name = ("fabs", Type.Fun([Type.Float], Type.Float));  (* abs_float *)
    args = [("x", Type.Float)]; 
    body = FAbs(var("x")) };
  { name = ("sqrt", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Sqrt(var("x")) };

  { name = ("int_of_float", Type.Fun([Type.Float], Type.Int));
    args = [("x", Type.Float)];  (* xがFloatであることの型検査はなし *)
    body = FTOI(var("x")) };
  { name = ("truncate", Type.Fun([Type.Float], Type.Int));
    args = [("x", Type.Float)];  (* xがFloatであることの型検査はなし *)
    body = FTOI(var("x")) };
  { name = ("float_of_int", Type.Fun([Type.Int], Type.Float));
    args = [("x", Type.Int)];  (* xがIntであることの型検査はなし *)
    body = ITOF(var("x")) };

  { name = ("print_newline", Type.Fun([Type.Unit], Type.Unit));
    args = [(Id.genid "Tunit", Type.Unit)]; 
    body = Out(Int(10)) };
  { name = ("print_char", Type.Fun([Type.Int], Type.Unit));
    args = [("x", Type.Int)]; 
    body = Out(var("x")) };
  { name = ("print_int", Type.Fun([Type.Int], Type.Unit));
    args = [("x", Type.Int)]; 
    body = OutInt(var("x")) };
  
  { name = ("read_int", Type.Fun([Type.Unit], Type.Int));
    args = [(Id.genid "Tunit", Type.Unit)];
    body = Let(("read0", Type.Int), In,
           Let(("sum0", Type.Int), Mul(var("read0"), Int(16777216)),
           Let(("read1", Type.Int), In,
           Let(("sum1", Type.Int), Add(Mul(var("read1"), Int(65536)), var("sum0")),
           Let(("read2", Type.Int), In,
           Let(("sum2", Type.Int), Add(Mul(var("read2"), Int(256)), var("sum1")),
           Let(("read3", Type.Int), In,
           Add(var("read3"), var("sum2"))))))))) };
  { name = ("read_float", Type.Fun([Type.Unit], Type.Float));
    args = [(Id.genid "Tunit", Type.Unit)];
    body = Let(("read0", Type.Int), In,
           Let(("sum0", Type.Int), Mul(var("read0"), Int(16777216)),
           Let(("read1", Type.Int), In,
           Let(("sum1", Type.Int), Add(Mul(var("read1"), Int(65536)), var("sum0")),
           Let(("read2", Type.Int), In,
           Let(("sum2", Type.Int), Add(Mul(var("read2"), Int(256)), var("sum1")),
           Let(("read3", Type.Int), In,
           Let(("sum3", Type.Int), Add(var("read3"), var("sum2")),
           BTOF(var("sum3")))))))))) }
]


(*
  { name = ("create_float_array_loop", Type.Fun([Type.Int; Type.Float], Type.Unit));
    args = [("n", Type.Int); ("x", Type.Float)];
    body = If(Eq(var("n"), Int(0)),
              Unit,
              Let((Id.genid "Tunit", Type.Unit), StHP(var("x")),
              Let((Id.genid "Tunit", Type.Unit), IncrHP,
              App(var("create_float_array_loop"), [Sub(var("n"), Int(1)), var("x")])))) }  (* Asm.reg_hp *)

  { name = ("create_float_array", Type.Fun([Type.Int; Type.Float], Type.Unit));
    args = [("n", Type.Int); ("x", Type.Float)];
    body = Let(("ret", Type.Array(Type.Float)), HP,  (* retの型は? Intじゃない? *)
           Let((Id.genid "Tunit", Type.Unit), App(var("create_float_array_loop"), [var("n"); var("x")]),
           var("ret"))) }  (* Asm.reg_hp *)
*)

(* 
let rec create_array_loop n x =
  if n = 0 then Unit else (
    Let(Tunit, Asm(Asm.St("x", "$gp", 0)),
    Let("$gp", Add($gp, Int(4)),
    create_array_loop (n - 1) x
  )

let rec create_array n x =
  let ret = "$gp" in
  let () = create_array_loop n x in
  ret

let rec create_float_array_loop n x =
  if n = 0 then Unit else (
    Let(Tunit, Asm(Asm.StDF("x", "$gp", 0)),
    Let("$gp", Add($gp, Int(4)),
    create_array_loop (n - 1) x
  )

let rec create_float_array n x =
  let ret = "$gp" in
  let () = create_float_array_loop n x in
  ret

let rec create_unit_array n =
  "$gp"
  or
  Nop


Mov("x")の型って不明
$gp って、Tuple型のときもある。Array型のときもあり 
*)
