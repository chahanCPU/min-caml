open Syntax

let var x = Var(x, [])

let lib = [
  { name = ("print_newline", Type.Fun([Type.Unit], Type.Unit));
    args = [(Id.genid "Tunit", Type.Unit)]; 
    body = Let(("x", Type.Int), Int(10), Asm(Asm.Out("x"), Type.Unit)) };
  { name = ("print_char", Type.Fun([Type.Int], Type.Unit));
    args = [("x", Type.Int)]; 
    body = Asm(Asm.Out("x"), Type.Unit) };
  { name = ("print_int", Type.Fun([Type.Int], Type.Unit));
    args = [("x", Type.Int)]; 
    body = Asm(Asm.OutInt("x"), Type.Unit) };

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
  
  { name = ("read_int", Type.Fun([Type.Unit], Type.Int));
    args = [(Id.genid "Tunit", Type.Unit)];
    body = Let(("read0", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum0", Type.Int), Mul(Var("read0"), Int(16777216)),
           Let(("read1", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum1", Type.Int), Add(Mul(Var("read1"), Int(65536)), Var("sum0")),
           Let(("read2", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum2", Type.Int), Add(Mul(Var("read2"), Int(256)), Var("sum1")),
           Let(("read3", Type.Int), Asm(Asm.In, Type.Int),
           Add(Var("read3"), Var("sum2"))))))))) };
  { name = ("read_float", Type.Fun([Type.Unit], Type.Float));
    args = [(Id.genid "Tunit", Type.Unit)];
    body = Let(("read0", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum0", Type.Int), Mul(Var("read0"), Int(16777216)),
           Let(("read1", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum1", Type.Int), Add(Mul(Var("read1"), Int(65536)), Var("sum0")),
           Let(("read2", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum2", Type.Int), Add(Mul(Var("read2"), Int(256)), Var("sum1")),
           Let(("read3", Type.Int), Asm(Asm.In, Type.Int),
           Let(("sum3", Type.Int), Add(Var("read3"), Var("sum2")),
           Let((Id.genid "Tunit", Type.Unit), Asm(Asm.St(________________________), Type.Unit),
           Asm(Asm.LdDF(___________________________, 0), Type.Float)))))))))) }
]

let f e =
  List.fold_left
    (fun e' fundef -> LetRec(fundef, e))
    e
    lib
