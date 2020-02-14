open Syntax

let var x = Var(x, [])

let lib = [
  { name = ("fequal", Type.Fun([Type.Float; Type.Float], Type.Float));
    args = [("x", Type.Float); ("y", Type.Float)]; 
    body = Eq(Var("x"), Var("y")) };
  { name = ("fless", Type.Fun([Type.Float; Type.Float], Type.Float));
    args = [("x", Type.Float); ("y", Type.Float)]; 
    body = Not(LE(Var("y"), Var("x"))) };
  { name = ("fispos", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Not(LE(Var("x"), Float(0.))) };
  { name = ("fisneg", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Not(LE(Float(0.), Var("x"))) };
  { name = ("fiszero", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Eq(Var("x"), Float(0.)) };
  
  { name = ("not", Type.Fun([Type.Bool], Type.Bool));
    args = [("x", Type.Bool)]; 
    body = If(Var("x"), Bool(false), Bool(true)) };
    (* body = Not(Var("x")) }; *)

  { name = ("xor", Type.Fun([Type.Bool; Type.Bool], Type.Bool));
    args = [("x", Type.Bool); ("y", Type.Bool)]; 
    body = If(Var("x"), App(Var("not"), [Var("y")]), Var("y")) };


  { name = ("fhalf", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = FMul(Var("x"), Float(0.5)) };
  { name = ("fsqr", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = FMul(Var("x"), Var("x")) };
  
  (* { name = ("fabs", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = FMul(Var("x"), Var("x")) }; *)
  { name = ("fneg", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = FNeg(Var("x")) };


  { name = ("atan", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Let(("x2", Type.Float), FMul(Var("x"), Var("x")),
             FMul(Var("x"), FSub(Float(1.0), )) ) };

  { name = ("fabs", Type.Fun([Type.Float], Type.Float));  (* abs_float *)
    args = [("x", Type.Float)]; 
    body = Asm(Asm.FAbs("x"), Type.Float) };
  { name = ("sqrt", Type.Fun([Type.Float], Type.Float));
    args = [("x", Type.Float)]; 
    body = Asm(Asm.FSqrt("x"), Type.Float) };
  { name = ("int_of_float", Type.Fun([Type.Float], Type.Int));
    args = [("x", Type.Float)];  (* xがFloatであることの型検査はなし *)
    body = Asm(Asm.FTOI("x"), Type.Int) };
  { name = ("truncate", Type.Fun([Type.Float], Type.Int));
    args = [("x", Type.Float)];  (* xがFloatであることの型検査はなし *)
    body = Asm(Asm.FTOI("x"), Type.Int) };
  { name = ("float_of_int", Type.Fun([Type.Int], Type.Float));
    args = [("x", Type.Int)];  (* xがIntであることの型検査はなし *)
    body = Asm(Asm.ITOF("x"), Type.Float) };
]