open Asm

external getfloat : float -> int32 = "getfloat"
(* external gethi : float -> int32 = "gethi" *)
(* external getlo : float -> int32 = "getlo" *)

let stackset = ref S.empty (* すでにSaveされた変数の集合 (caml2html: emit_stackset) *)
let stackmap = ref [] (* Saveされた変数の、スタックにおける位置 (caml2html: emit_stackmap) *)
let save x =
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    stackmap := !stackmap @ [x]
let savef x =    (* double型に必要？ *)
  stackset := S.add x !stackset;
  if not (List.mem x !stackmap) then
    (* (let pad =
      if List.length !stackmap mod 2 = 0 then [] else [Id.gentmp Type.Int] in
    stackmap := !stackmap @ pad @ [x; x]) *)
    stackmap := !stackmap @ [x]
let locate x =
  let rec loc = function
    | [] -> []
    | y :: zs when x = y -> 0 :: List.map succ (loc zs)
    | y :: zs -> List.map succ (loc zs) in
  loc !stackmap
let offset x = 4 * List.hd (locate x)
let stacksize () = align ((List.length !stackmap + 1) * 4)

(* let pp_id_or_imm = function
  | V(x) -> x
  | C(i) -> string_of_int i *)

(* 関数呼び出しのために引数を並べ替える(register shuffling) (caml2html: emit_shuffle) *)
let rec shuffle sw xys =
  (* remove identical moves *)
  let _, xys = List.partition (fun (x, y) -> x = y) xys in
  (* find acyclic moves *)
  match List.partition (fun (_, y) -> List.mem_assoc y xys) xys with
  | [], [] -> []
  | (x, y) :: xys, [] -> (* no acyclic moves; resolve a cyclic move *)
      (y, sw) :: (x, y) :: shuffle sw (List.map
                                         (function
                                           | (y', z) when y = y' -> (sw, z)
                                           | yz -> yz)
                                         xys)
  | xys, acyc -> acyc @ shuffle sw xys

type dest = Tail | NonTail of Id.t (* 末尾かどうかを表すデータ型 (caml2html: emit_dest) *)
let rec g oc = function (* 命令列のアセンブリ生成 (caml2html: emit_g) *)
  | dest, Ans(exp) -> g' oc (dest, exp)
  | dest, Let((x, t), exp, e) ->
      g' oc (NonTail(x), exp);
      g oc (dest, e)
and g' oc = function (* 各命令のアセンブリ生成 (caml2html: emit_gprime) *)
  (* 末尾でなかったら計算結果をdestにセット (caml2html: emit_nontail) *)
  | NonTail(_), Nop -> ()
  (* 全般的に即値の値が大きい場合を考えていないよね *)
  | NonTail(x), Set(i) -> Printf.fprintf oc "\tori\t%s, $zero, %d\n" x i
  (* 要注意 *)
  | NonTail(x), SetL(Id.L(y)) -> Printf.fprintf oc "\tor\t%s, $zero, %s\n" x y
  | NonTail(x), Mov(y) when x = y -> ()
  | NonTail(x), Mov(y) -> Printf.fprintf oc "\tor\t%s, $zero, %s\n" x y
  | NonTail(x), Neg(y) -> Printf.fprintf oc "\tsub\t%s, $zero, %s\n" x y
  (* | NonTail(x), Add(y, z') -> Printf.fprintf oc "\tadd\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), Sub(y, z') -> Printf.fprintf oc "\tsub\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), SLL(y, z') -> Printf.fprintf oc "\tsll\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), Ld(y, z') -> Printf.fprintf oc "\tld\t[%s + %s], %s\n" y (pp_id_or_imm z') x
  | NonTail(_), St(x, y, z') -> Printf.fprintf oc "\tst\t%s, [%s + %s]\n" x y (pp_id_or_imm z') *)
  | NonTail(x), Add(y, V(z)) -> Printf.fprintf oc "\tadd\t%s, %s, %s\n" x y z
  | NonTail(x), Add(y, C(z)) -> Printf.fprintf oc "\taddi\t%s, %s, %d\n" x y z
  | NonTail(x), Sub(y, V(z)) -> Printf.fprintf oc "\tsub\t%s, %s, %s\n" x y z
  | NonTail(x), Sub(y, C(z)) -> Printf.fprintf oc "\tsubi\t%s, %s, %d\n" x y z
  | NonTail(x), SLL(y, V(z)) -> Printf.fprintf oc "\tsllv\t%s, %s, %s\n" x y z
  | NonTail(x), SLL(y, C(z)) -> Printf.fprintf oc "\tsll\t%s, %s, %d\n" x y z
  | NonTail(x), Ld(y, V(z)) -> 
      Printf.fprintf oc "\tadd\t$at, %s, %s\n" z y;
      Printf.fprintf oc "\tlw\t%s, 0($at)\n" x
  | NonTail(x), Ld(y, C(z)) -> Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x z y 
  | NonTail(_), St(x, y, V(z)) ->
      Printf.fprintf oc "\tadd\t$at, %s, %s\n" z y;       
      Printf.fprintf oc "\tsw\t%s, 0($at)\n" x
  | NonTail(_), St(x, y, C(z)) -> Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x z y
  (* | NonTail(x), FMovD(y) when x = y -> ()
  | NonTail(x), FMovD(y) ->
      Printf.fprintf oc "\tfmovs\t%s, %s\n" y x;
      Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x)
  | NonTail(x), FNegD(y) ->
      Printf.fprintf oc "\tfnegs\t%s, %s\n" y x;
      if x <> y then Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x)
  | NonTail(x), FAddD(y, z) -> Printf.fprintf oc "\tfaddd\t%s, %s, %s\n" y z x
  | NonTail(x), FSubD(y, z) -> Printf.fprintf oc "\tfsubd\t%s, %s, %s\n" y z x
  | NonTail(x), FMulD(y, z) -> Printf.fprintf oc "\tfmuld\t%s, %s, %s\n" y z x
  | NonTail(x), FDivD(y, z) -> Printf.fprintf oc "\tfdivd\t%s, %s, %s\n" y z x
  | NonTail(x), LdDF(y, z') -> Printf.fprintf oc "\tldd\t[%s + %s], %s\n" y (pp_id_or_imm z') x
  | NonTail(_), StDF(x, y, z') -> Printf.fprintf oc "\tstd\t%s, [%s + %s]\n" x y (pp_id_or_imm z') *)
  | NonTail(x), FMovD(y) when x = y -> ()
  | NonTail(x), FMovD(y) ->
      Printf.fprintf oc "\tor\t%s, $zero, %s\n" x y     
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" y x; *)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x) *)
  | NonTail(x), FNegD(y) ->
      Printf.fprintf oc "\tsub.s\t%s, $zero, %s\n" x y    (* (float)0は、bit列でも全0 *)
      (* Printf.fprintf oc "\tfnegs\t%s, %s\n" y x; *)
      (* if x <> y then Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x) *)
  | NonTail(x), FAddD(y, z) -> Printf.fprintf oc "\tadd.s\t%s, %s, %s\n" x y z
  | NonTail(x), FSubD(y, z) -> Printf.fprintf oc "\tsub.s\t%s, %s, %s\n" x y z
  | NonTail(x), FMulD(y, z) -> Printf.fprintf oc "\tmul.s\t%s, %s, %s\n" x y z
  | NonTail(x), FDivD(y, z) -> 
      Printf.fprintf oc "\tinv.s\t$at, %s\n" z;    (* $atを浮動小数点数用に使うのはあり!? *)
      Printf.fprintf oc "\tmul.s\t%s, %s, $at\n" x y
  | NonTail(x), LdDF(y, V(z)) ->
      Printf.fprintf oc "\tadd\t$at, %s, %s\n" z y;
      Printf.fprintf oc "\tlw\t%s, 0($at)\n" x
  | NonTail(x), LdDF(y, C(z)) -> Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x z y 
  | NonTail(_), StDF(x, y, V(z)) -> 
      Printf.fprintf oc "\tadd\t$at, %s, %s\n" z y;       
      Printf.fprintf oc "\tsw\t%s, 0($at)\n" x
  | NonTail(_), StDF(x, y, C(z)) -> Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x z y

  | NonTail(_), Comment(s) -> Printf.fprintf oc "\t! %s\n" s

  (* 要確認　もとのsparcと *)
  (* 退避の仮想命令の実装 (caml2html: emit_save) *)
  | NonTail(_), Save(x, y) when List.mem x allregs && not (S.mem y !stackset) ->
      save y;
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(_), Save(x, y) when List.mem x allfregs && not (S.mem y !stackset) ->
      savef y;
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(_), Save(x, y) -> assert (S.mem y !stackset); ()

  (* 要確認　もとのsparcと *)
  (* 復帰の仮想命令の実装 (caml2html: emit_restore) *)
  | NonTail(x), Restore(y) when List.mem x allregs ->
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(x), Restore(y) ->
      assert (List.mem x allfregs);
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x (offset y) reg_sp

  (* 末尾だったら計算結果を第一レジスタにセットしてリターン (caml2html: emit_tailret) *)
  | Tail, (Nop | St _ | StDF _ | Comment _ | Save _ as exp) ->
      g' oc (NonTail(Id.gentmp Type.Unit), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (Set _ | SetL _ | Mov _ | Neg _ | Add _ | Sub _ | SLL _ | Ld _ as exp) ->
      g' oc (NonTail(regs.(0)), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (FMovD _ | FNegD _ | FAddD _ | FSubD _ | FMulD _ | FDivD _ | LdDF _ as exp) ->
      g' oc (NonTail(fregs.(0)), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (Restore(x) as exp) ->
      (match locate x with
      | [i] -> g' oc (NonTail(regs.(0)), exp)
      | [i; j] when i + 1 = j -> g' oc (NonTail(fregs.(0)), exp)
      | _ -> assert false);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra

  (* | Tail, IfEq(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_tail_if oc e1 e2 "be" "bne"
  | Tail, IfLE(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_tail_if oc e1 e2 "ble" "bg"
  | Tail, IfGE(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_tail_if oc e1 e2 "bge" "bl" *)
  | Tail, IfEq(x, V(y), e1, e2) ->
      (* Printf.fprintf oc "\tseq\t$at, %s, %s\n" x y; *)
      g'_tail_ifeq oc e1 e2 x y
  | Tail, IfEq(x, C(y), e1, e2) ->
      (* Printf.fprintf oc "\tseqi\t$at, %s, %d\n" x y; *)
      Printf.fprintf oc "\tori\t$at, $zero, %d\n" y;
      g'_tail_ifeq oc e1 e2 x "$at"
  | Tail, IfLE(x, V(y), e1, e2) ->
      Printf.fprintf oc "\taddi\t$at, %s, 1\n" y;
      Printf.fprintf oc "\tslt\t$at, %s, $at\n" x;
      g'_tail_iflt oc e1 e2 "bgtz" "blez"
  | Tail, IfLE(x, C(y), e1, e2) ->
      Printf.fprintf oc "\tslti\t$at, %s, %d\n" x (y+1);
      g'_tail_iflt oc e1 e2 "bgtz" "blez"
  | Tail, IfGE(x, V(y), e1, e2) ->
      Printf.fprintf oc "\tslt\t$at, %s, %s\n" x y;
      g'_tail_iflt oc e1 e2 "blez" "bgtz"
  | Tail, IfGE(x, C(y), e1, e2) ->
      Printf.fprintf oc "\tslti\t$at, %s, %d\n" x y;
      g'_tail_iflt oc e1 e2 "blez" "bgtz"
  (* | Tail, IfFEq(x, y, e1, e2) ->
      Printf.fprintf oc "\tfcmpd\t%s, %s\n" x y;
      Printf.fprintf oc "\tnop\n";
      g'_tail_if oc e1 e2 "fbe" "fbne"
  | Tail, IfFLE(x, y, e1, e2) ->
      Printf.fprintf oc "\tfcmpd\t%s, %s\n" x y;
      Printf.fprintf oc "\tnop\n";
      g'_tail_if oc e1 e2 "fble" "fbg" *)
  | Tail, IfFEq(x, y, e1, e2) ->
      Printf.fprintf oc "\tc.eq.s\t$at, %s, %s\n" x y;    (* 普通のequalでよくないか? *)
      g'_tail_iflt oc e1 e2 "bgtz" "blez"
  | Tail, IfFLE(x, y, e1, e2) ->
      Printf.fprintf oc "\tc.le.s\t$at, %s, %s\n" x y;
      g'_tail_iflt oc e1 e2 "bgtz" "blez"
  
  (* | NonTail(z), IfEq(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_non_tail_if oc (NonTail(z)) e1 e2 "be" "bne"
  | NonTail(z), IfLE(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_non_tail_if oc (NonTail(z)) e1 e2 "ble" "bg"
  | NonTail(z), IfGE(x, y', e1, e2) ->
      Printf.fprintf oc "\tcmp\t%s, %s\n" x (pp_id_or_imm y');
      g'_non_tail_if oc (NonTail(z)) e1 e2 "bge" "bl" *)
  | NonTail(z), IfEq(x, V(y), e1, e2) ->
      (* Printf.fprintf oc "\tseq\t$at, %s, %s\n" x y; *)
      g'_non_tail_ifeq oc (NonTail(z)) e1 e2 x y
  | NonTail(z), IfEq(x, C(y), e1, e2) ->
      (* Printf.fprintf oc "\tseqi\t$at, %s, %d\n" x y; *)
      Printf.fprintf oc "\tori\t$at, $zero, %d\n" y;
      g'_non_tail_ifeq oc (NonTail(z)) e1 e2 x "$at"
  | NonTail(z), IfLE(x, V(y), e1, e2) ->
      Printf.fprintf oc "\taddi\t$at, %s, 1\n" y;
      Printf.fprintf oc "\tslt\t$at, %s, $at\n" x;
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "bgtz" "blez"
  | NonTail(z), IfLE(x, C(y), e1, e2) ->
      Printf.fprintf oc "\tslti\t$at, %s, %d\n" x (y+1);
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "bgtz" "blez"
  | NonTail(z), IfGE(x, V(y), e1, e2) ->
      Printf.fprintf oc "\tslt\t$at, %s, %s\n" x y;
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "blez" "bgtz"
  | NonTail(z), IfGE(x, C(y), e1, e2) ->
      Printf.fprintf oc "\tslti\t$at, %s, %d\n" x y;
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "blez" "bgtz"
  (* | NonTail(z), IfFEq(x, y, e1, e2) ->
      Printf.fprintf oc "\tfcmpd\t%s, %s\n" x y;
      Printf.fprintf oc "\tnop\n";
      g'_non_tail_if oc (NonTail(z)) e1 e2 "fbe" "fbne"
  | NonTail(z), IfFLE(x, y, e1, e2) ->
      Printf.fprintf oc "\tfcmpd\t%s, %s\n" x y;
      Printf.fprintf oc "\tnop\n";
      g'_non_tail_if oc (NonTail(z)) e1 e2 "fble" "fbg" *)
  | NonTail(z), IfFEq(x, y, e1, e2) ->
      Printf.fprintf oc "\tc.eq.s\t$at, %s, %s\n" x y;
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "bgtz" "blez"
  | NonTail(z), IfFLE(x, y, e1, e2) ->
      Printf.fprintf oc "\tc.le.s\t$at, %s, %s\n" x y;
      g'_non_tail_iflt oc (NonTail(z)) e1 e2 "bgtz" "blez"

  (* もとのsparcと要確認 *)
  (* 関数呼び出しの仮想命令の実装 (caml2html: emit_call) *)
  | Tail, CallCls(x, ys, zs) -> (* 末尾呼び出し (caml2html: emit_tailcall) *)
      g'_args oc [(x, reg_cl)] ys zs;
      Printf.fprintf oc "\tlw\t%s, 0(%s)\n" reg_sw reg_cl;
      Printf.fprintf oc "\tjr\t%s\n" reg_sw;
  | Tail, CallDir(Id.L(x), ys, zs) -> (* 末尾呼び出し *)
      g'_args oc [] ys zs;
      Printf.fprintf oc "\tj\t%s\n" x;
  | NonTail(a), CallCls(x, ys, zs) ->
      g'_args oc [(x, reg_cl)] ys zs;
      let ss = stacksize () in
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      Printf.fprintf oc "\tlw\t%s, 0(%s)\n" reg_sw reg_cl;
      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp ss;
      Printf.fprintf oc "\tjal\t%s\n" reg_sw;
      Printf.fprintf oc "\tsubi\t%s, %s, %d\n" reg_sp reg_sp ss;
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      if List.mem a allregs && a <> regs.(0) then
        Printf.fprintf oc "\tor\t%s, $zero, %s\n" a regs.(0)
      else if List.mem a allfregs && a <> fregs.(0) then
        Printf.fprintf oc "\tor\t%s, $zero, %s\n" a fregs.(0)
      (* else if List.mem a allfregs && a <> fregs.(0) then
        (Printf.fprintf oc "\tfmovs\t%s, %s\n" fregs.(0) a;
         Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg fregs.(0)) (co_freg a)) *)
  | NonTail(a), CallDir(Id.L(x), ys, zs) ->
      g'_args oc [] ys zs;
      let ss = stacksize () in
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp ss;
      Printf.fprintf oc "\tjal\t%s\n" x;
      Printf.fprintf oc "\tsubi\t%s, %s, %d\n" reg_sp reg_sp ss;
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      if List.mem a allregs && a <> regs.(0) then
        Printf.fprintf oc "\tor\t%s, $zero, %s\n" a regs.(0)
      else if List.mem a allfregs && a <> fregs.(0) then
        Printf.fprintf oc "\tor\t%s, $zero, %s\n" a fregs.(0)
      (* else if List.mem a allfregs && a <> fregs.(0) then
        (Printf.fprintf oc "\tfmovs\t%s, %s\n" fregs.(0) a;
         Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg fregs.(0)) (co_freg a)) *)

and g'_tail_ifeq oc e1 e2 x y =
  let b_else = Id.genid "beq_else" in
  Printf.fprintf oc "\tbne\t%s, %s, %s\n" x y b_else;
  let stackset_back = !stackset in
  g oc (Tail, e1);
  Printf.fprintf oc "%s:\n" b_else;
  stackset := stackset_back;
  g oc (Tail, e2)

and g'_tail_iflt oc e1 e2 b bn =
  let b_else = Id.genid (b ^ "_else") in
  Printf.fprintf oc "\t%s\t$at, %s\n" bn b_else;
  let stackset_back = !stackset in
  g oc (Tail, e1);
  Printf.fprintf oc "%s:\n" b_else;
  stackset := stackset_back;
  g oc (Tail, e2)

and g'_non_tail_ifeq oc dest e1 e2 x y =
  let b_else = Id.genid "beq_else" in
  let b_cont = Id.genid "beq_cont" in
  Printf.fprintf oc "\tbne\t%s, %s, %s\n" x y b_else;
  let stackset_back = !stackset in
  g oc (dest, e1);
  let stackset1 = !stackset in
  Printf.fprintf oc "\tj\t%s\n" b_cont;
  Printf.fprintf oc "%s:\n" b_else;
  stackset := stackset_back;
  g oc (dest, e2);
  Printf.fprintf oc "%s:\n" b_cont;
  let stackset2 = !stackset in
  stackset := S.inter stackset1 stackset2

and g'_non_tail_iflt oc dest e1 e2 b bn =
  let b_else = Id.genid (b ^ "_else") in
  let b_cont = Id.genid (b ^ "_cont") in
  Printf.fprintf oc "\t%s\t$at, %s\n" bn b_else;
  let stackset_back = !stackset in
  g oc (dest, e1);
  let stackset1 = !stackset in
  Printf.fprintf oc "\tj\t%s\n" b_cont;
  Printf.fprintf oc "%s:\n" b_else;
  stackset := stackset_back;
  g oc (dest, e2);
  Printf.fprintf oc "%s:\n" b_cont;
  let stackset2 = !stackset in
  stackset := S.inter stackset1 stackset2

and g'_args oc x_reg_cl ys zs =
  let (i, yrs) =
    List.fold_left
      (fun (i, yrs) y -> (i + 1, (y, regs.(i)) :: yrs))
      (0, x_reg_cl)
      ys in
  List.iter
    (fun (y, r) -> Printf.fprintf oc "\tor\t%s, $zero, %s\n" r y)
    (shuffle reg_sw yrs);
  let (d, zfrs) =
    List.fold_left
      (fun (d, zfrs) z -> (d + 1, (z, fregs.(d)) :: zfrs))
      (0, [])
      zs in
  List.iter
    (fun (z, fr) ->
      Printf.fprintf oc "\tor\t%s, $zero, %s\n" fr z)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" z fr; *)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg z) (co_freg fr)) *)
    (shuffle reg_fsw zfrs)

let h oc { name = Id.L(x); args = _; fargs = _; body = e; ret = _ } =
  Printf.fprintf oc "%s:\n" x;
  stackset := S.empty;
  stackmap := [];
  g oc (Tail, e)

let f oc (Prog(data, fundefs, e)) =
  Format.eprintf "generating assembly...@.";
  Printf.fprintf oc ".section \".rodata\"\n";
  (* Printf.fprintf oc ".align\t8\n"; *)
  (* Printf.fprintf oc ".align\t4\n"; *)
  List.iter
    (fun (Id.L(x), d) ->
      Printf.fprintf oc "%s:\t! %f\n" x d;
      Printf.fprintf oc "\t0x%lx\n" (getfloat d))
      (* Printf.fprintf oc "\t.long\t0x%lx\n" (gethi d);
      Printf.fprintf oc "\t.long\t0x%lx\n" (getlo d)) *)
    data;

  Printf.fprintf oc ".section \".text\"\n";

  (* outの付け足し  後でインライン化してね *)
  Printf.fprintf oc "min_caml_print_int:\n";
  Printf.fprintf oc "\tout\t$2\n";
  Printf.fprintf oc "\tjr\t%s\n" reg_ra;

  (* float_of_intは関数呼び出しで対応  後でインライン化すること *)
  Printf.fprintf oc "min_caml_float_of_int:\n";
  Printf.fprintf oc "\titof\t$f0, $2\n";
  Printf.fprintf oc "\tjr\t%s\n" reg_ra;

  List.iter (fun fundef -> h oc fundef) fundefs;

  Printf.fprintf oc ".global min_caml_start\n";
  Printf.fprintf oc "min_caml_start:\n";
  (* Printf.fprintf oc "\tsave\t$sp, -112, $sp\n"; (* from gcc; why 112? *) *)
  (* Printf.fprintf oc "\tsave\t$sp, -120, $sp\n"; *)
  stackset := S.empty;
  stackmap := [];
  g oc (NonTail("%g0"), e)    (* why? *)

  (* 要確認 終了動作 *)
  (* Printf.fprintf oc "\tret\n"; *)
  (* Printf.fprintf oc "\trestore\n" *)