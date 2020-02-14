open Asm

(* 64-bit platform を前提 *)
(* Ocaml   int 63bits, float 64bits *)
(* chahan  int 32bits, float 64bits *)
(* C       int 64bits, float 64bits *)
(* external binary32_of_float : float -> int32 = "double_to_binary32"  (* float.cを参照 *) *)

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
(* let stacksize () = align ((List.length !stackmap + 1) * 4) *)
let stacksize () = (List.length !stackmap + 1) * 4

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
  (* 命令長 32bit *)
  (* 16bitで扱えるsigned数 : -2^15 から 2^15-1   -32678 32767 *)
  | NonTail(x), Set(i) when -32678 <= i && i < 32678 -> 
      Printf.fprintf oc "\taddi\t%s, $zero, %d\n" x i  (* oriかaddi, addiが重そう *)
      (* Printf.fprintf oc "\tori\t%s, $zero, %d\n" x i  (* oriかaddi *) *)
      (* ori, $2, $zero, -1 って、$2 <- 0xFFFFFFFF になるよな *)
      (* 即値16ビットやから、0x0000FFFF とはならんよな====願望 *)
	(* 32bitで扱えるsigned数 : -2^31 から 2^31-1 *)
  | NonTail(x), Set(i) when -2147483648 <= i && i < 2147483648 -> 
      (* let i = Int32.to_int i in *)    (* 64-bit platform を前提 *)
      let hi = (i land 0xFFFF0000) lsr 16 in
      let lo = i land 0xFFFF in
      Printf.fprintf oc "\tlui\t%s, 0x%x\t\t# %dの上位16ビット\n" x hi i;
      if lo <> 0 then Printf.fprintf oc "\tlli\t%s, 0x%x\t\t# %dの下位16ビット\n" x lo i  (* oriかaddi *)
      (* 
      Printf.fprintf oc "\tlui\t%s, 0x%x\t\t# %dの上位16bits\n" x hi i;
      (* 要注意：下は正しくないです。loの最上位ビットが1のとき、レジスタの上位16ビットがすべて1になってしまうので。 *)
      if lo <> 0 then Printf.fprintf oc "\tori\t%s, %s, 0x%x\t\t# %dの下位16bits\n" x x lo i  (* oriかaddi *) 
      *)
  | NonTail(x), Set(i) -> failwith("数が大きすぎ")
  (* 即値を取る命令について、上のような感じで確認すること！！！！！！！！！！！！ *)
  (* 整数用命令と浮動小数点用命令で使えるレジスタを区別しなきゃいけない？ 
     --> そうしなきゃいけないことが判明 。
         命令をバイナリにしたときにレジスタを指定できるビット数に制限があることを考えると *)
(* $f0はゼロ、$f1は$atのノリで使ってる *)
  (* | NonTail(x), FSetD(0.) -> *)   (* もっと効率化したい、ほんとそう *)
      (* Printf.fprintf oc "\tlui.s\t%s, 0x0\n" x *)
  | NonTail(x), FSetD(d) ->    (* もっと効率化したい *)
      (* Printf.fprintf oc "\tori\t%s, $zero, 0x%lx\t\t# %f\n" x (binary32_of_float d) d *)
      (* let i = binary32_of_float d in *)
      (* let i = Int32.to_int i in *)   (* 64-bit platform を前提 *)
      let i = Int32.bits_of_float d in
      let d = Int32.float_of_bits i in    (* 倍精度と、倍精度->単精度->倍精度とは異なるので *)
      let i = Int32.to_int i in
      let hi = (i land 0xFFFF0000) lsr 16 in
      let lo = i land 0xFFFF in

      Printf.fprintf oc "\tlui.s\t%s, 0x%x\t\t# %fの上位16ビット\n" x hi d;
      if lo <> 0 then Printf.fprintf oc "\tlli.s\t%s, 0x%x\t\t# %fの下位16ビット\n" x lo d

      (* 臨時のFSetD *)
      (*
      Printf.fprintf oc "\tlui\t$at, 0x%x\t\t# %fの上位16bits\n" hi d;
      Printf.fprintf oc "\tlui\t$0, 0x%x\t\t# %fの下位16bits\n" lo d;
      Printf.fprintf oc "\tsrl\t$0, $0, 16\n";
      Printf.fprintf oc "\tor\t$at, $at, $0\n";
      Printf.fprintf oc "\tlui\t$0, 0x0\n";
      Printf.fprintf oc "\tsw\t$at, 4($zero)\n";     (* 4じゃなくて0だとバグりました *)
      Printf.fprintf oc "\tlw.s\t%s, 4($zero)\n" x
      *)

      (* if lo = 0 then    (* 無駄が多い *)
        (* Printf.fprintf oc "\tlui.s\t%s, 0x%x\t\t# %fの上位16bits\n" x hi d *)
        (Printf.fprintf oc "\tlui\t$at, 0x%x\t\t# %fの上位16bits\n" hi d;
         (* Printf.fprintf oc "\tori\t$at, $at, 0x%x\t\t# %fの下位16bits\n" lo d; *)
         (* Printf.fprintf oc "\tsw\t$at, 16(%s)\t\t# why 16?\n" reg_sp;   (* 16ってとりすぎ? 0でも構わないのか。メモリの中身を見たい *) *)
         (* Printf.fprintf oc "\tlw.s\t%s, 16(%s)\t\t# why 16?\n" x reg_sp *)
         Printf.fprintf oc "\tsw\t$at, 4($zero)\n";     (* 4じゃなくて0だとバグりました、まだ上も選択肢としてあり *)
         Printf.fprintf oc "\tlw.s\t%s, 4($zero)\n" x
         )
      else    (* 無駄が多い *)
        (Printf.fprintf oc "\tlui\t$at, 0x%x\t\t# %fの上位16bits\n" hi d;
         Printf.fprintf oc "\tori\t$at, $at, 0x%x\t\t# %fの下位16bits\n" lo d;    (* ori, addiのどちら *)
         (* Printf.fprintf oc "\tsw\t$at, 16(%s)\t\t# why 16?\n" reg_sp;    (* 16ってとりすぎ? 0でも構わないのか。メモリの中身を見たい *) *)
         (* Printf.fprintf oc "\tlw.s\t%s, 16(%s)\t\t# why 16?\n" x reg_sp *)
         Printf.fprintf oc "\tsw\t$at, 4($zero)\n";     (* 4じゃなくて0だとバグりました、まだ上も選択肢としてあり *)
         Printf.fprintf oc "\tlw.s\t%s, 4($zero)\n" x
         ) *)
        (* Printf.fprintf oc "頑張って実装して\n" *)

(*
        (* if hi <> 0 then *) 
        Printf.fprintf oc "\tlui.s\t%s, 0x%x\t\t# %fの上位16bits\n" x hi d;
        if lo <> 0 then Printf.fprintf oc "\tadd.s\t%s, $f0, 0x%x\t\t# %fの下位16bits\n" x lo d
*)
  (* 要注意 *)
  (* SetLは浮動小数点即値以外にもClosure.ExtArray(Id.L(x))で使われるので、区別のために新しい命令FSetDを追加しました *)
  | NonTail(x), SetL(Id.L(y)) -> 
      (* アセンブラ担当と話して、擬似命令を追加 *)
      Printf.fprintf oc "\tla\t%s, %s\n" x y
      (* Printf.fprintf oc "\tli\t%s, %s\n" x y *)
      (* Printf.fprintf oc "\tor\t%s, $zero, %s\t\t# 実機で引数にラベルが取れるか注意\n" x y *)
      (* failwith("外部配列ExtArrayはchahanで対応してません。ソースコードで配列" ^ y ^ "をしてしてください")  *)
      (* 関数呼び出しでもこれを用いることが判明。至急要修正 *)
    (* もともと外部配列だけだと思っていたが、関数のラベル(関数が返り値になることもあるじゃん)をスタックに保存したいときに使う *)
    (* そもそもラベル32bitだからだめじゃん、外部配列を使わないようにお願いします(raytracerで普通使ってるけど) *)
  | NonTail(x), Mov(y) when x = y -> ()
  | NonTail(x), Mov(y) -> Printf.fprintf oc "\tmv\t%s, %s\n" x y
  (* | NonTail(x), Mov(y) -> Printf.fprintf oc "\tor\t%s, $zero, %s\n" x y *)
  (* | NonTail(x), Add(y, z') -> Printf.fprintf oc "\tadd\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), Sub(y, z') -> Printf.fprintf oc "\tsub\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), SLL(y, z') -> Printf.fprintf oc "\tsll\t%s, %s, %s\n" y (pp_id_or_imm z') x
  | NonTail(x), Ld(y, z') -> Printf.fprintf oc "\tld\t[%s + %s], %s\n" y (pp_id_or_imm z') x
  | NonTail(_), St(x, y, z') -> Printf.fprintf oc "\tst\t%s, [%s + %s]\n" x y (pp_id_or_imm z') *)
  (* キャリー・オーバーフローとか全く気にしていないのですが、本当に大丈夫だろうか。
     シミュレータに要確認 *)
  | NonTail(x), Add(y, z) -> Printf.fprintf oc "\tadd\t%s, %s, %s\n" x y z
  | NonTail(x), Addi(y, i) -> Printf.fprintf oc "\taddi\t%s, %s, %d\n" x y i
  | NonTail(x), Sub(y, z) -> Printf.fprintf oc "\tsub\t%s, %s, %s\n" x y z
  | NonTail(x), Mul(y, z) -> Printf.fprintf oc "\tmult\t%s, %s, %s\n" x y z
  | NonTail(x), Div(y, z) -> Printf.fprintf oc "\tdiv\t%s, %s, %s\n" x y z
  | NonTail(x), SLL(y, i) -> Printf.fprintf oc "\tsll\t%s, %s, %d\n" x y i
  | NonTail(x), SRA(y, i) -> Printf.fprintf oc "\tsra\t%s, %s, %d\n" x y i
  | NonTail(x), Ld(y, i) -> Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x i y 
  | NonTail(_), St(x, y, i) -> Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x i y
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
      Printf.fprintf oc "\tmv.s\t%s, %s\n" x y     
      (*
      Printf.fprintf oc "\tadd.s\t%s, $f0, %s\n" x y 
      *)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" y x; *)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x) *)
  | NonTail(x), FNegD(y) ->
      (* Printf.fprintf oc "\tsub.s\t%s, $zero, %s\n" x y    (* (float)0は、bit列でも全0 *) *)
      Printf.fprintf oc "\tneg.s\t%s, %s\n" x y
      (* Printf.fprintf oc "\tfnegs\t%s, %s\n" y x; *)
      (* if x <> y then Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg y) (co_freg x) *)
  | NonTail(x), FAddD(y, z) -> Printf.fprintf oc "\tadd.s\t%s, %s, %s\n" x y z
  | NonTail(x), FSubD(y, z) -> Printf.fprintf oc "\tsub.s\t%s, %s, %s\n" x y z
  | NonTail(x), FMulD(y, z) -> Printf.fprintf oc "\tmul.s\t%s, %s, %s\n" x y z
  (* 
  | NonTail(x), FDivD(y, z) -> 
			(* $f0はゼロ、$f1は$atのノリで使ってる *)
			(* $f0だけを拘束して、Divの場合$f0を一時退避に用いて最後に$f0に0を代入してもよさそう。小数レジスタを増やしたいので *)
      Printf.fprintf oc "\tinv.s\t$f1, %s\n" z;    (* $atを浮動小数点数用に使うのはあり!? --> なし *)
      Printf.fprintf oc "\tmul.s\t%s, %s, $f1\n" x y
  *)
  | NonTail(x), FInv(y) -> Printf.fprintf oc "\tinv.s\t%s, %s\n" x y
  | NonTail(x), LdDF(y, i) -> Printf.fprintf oc "\tlw.s\t%s, %d(%s)\n" x i y 
  | NonTail(_), StDF(x, y, i) -> Printf.fprintf oc "\tsw.s\t%s, %d(%s)\n" x i y

  (* 要確認　もとのsparcと *)
  (* 退避の仮想命令の実装 (caml2html: emit_save) *)
  | NonTail(_), Save(x, y) when List.mem x allregs && not (S.mem y !stackset) ->
      save y;
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(_), Save(x, y) when List.mem x allfregs && not (S.mem y !stackset) ->
      savef y;
      Printf.fprintf oc "\tsw.s\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(_), Save(x, y) -> assert (S.mem y !stackset); ()

  (* 要確認　もとのsparcと *)
  (* 復帰の仮想命令の実装 (caml2html: emit_restore) *)
  | NonTail(x), Restore(y) when List.mem x allregs ->
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" x (offset y) reg_sp
  | NonTail(x), Restore(y) ->
      assert (List.mem x allfregs);
      Printf.fprintf oc "\tlw.s\t%s, %d(%s)\n" x (offset y) reg_sp
  
  | NonTail(x), In -> Printf.fprintf oc "\tin\t%s\n" x
  | NonTail(_), Out(x) -> Printf.fprintf oc "\tout\t%s\n" x
  | NonTail(_), OutInt(x) -> Printf.fprintf oc "\toutint\t%s\n" x
  | NonTail(x), FAbs(y) -> Printf.fprintf oc "\tabs.s\t%s, %s\n" x y
  | NonTail(x), FSqrt(y) -> Printf.fprintf oc "\tsqrt.s\t%s, %s\n" x y
  | NonTail(x), FTOI(y) -> Printf.fprintf oc "\tftoi\t%s, %s\n" x y
  | NonTail(x), ITOF(y) -> Printf.fprintf oc "\titof\t%s, %s\n" x y

  (* 末尾だったら計算結果を第一レジスタにセットしてリターン (caml2html: emit_tailret) *)
  | Tail, (Nop | St _ | StDF _ | Save _ | Out _ | OutInt _ as exp) ->
      (* g' oc (NonTail(Id.gentmp Type.Unit), exp); *)
      g' oc (NonTail(Id.genid "Tunit"), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (Set _ | SetL _ | Mov _ | Add _ | Addi _ | Sub _ | Mul _ | Div _ | SLL _ | SRA _ | Ld _ | In | FTOI _ as exp) ->
      g' oc (NonTail(regs.(0)), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (FSetD _ | FMovD _ | FNegD _ | FAddD _ | FSubD _ | FMulD _ | FInv _ | LdDF _ | FAbs _ | FSqrt _ | ITOF _ as exp) ->
      g' oc (NonTail(fregs.(0)), exp);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra
  | Tail, (Restore(x) as exp) ->
      (match locate x with
      | [i] -> g' oc (NonTail(regs.(0)), exp)
      | [i; j] when i + 1 = j -> g' oc (NonTail(fregs.(0)), exp)
      | _ -> assert false);
      Printf.fprintf oc "\tjr\t%s\n" reg_ra

  | Tail, IfEq(x, y, e1, e2) -> g'_tail_if oc "beq" x y e1 e2
  | Tail, IfLE(x, y, e1, e2) -> g'_tail_if oc "ble" x y e1 e2
  | Tail, IfFEq(x, y, e1, e2) -> g'_tail_if oc "beq.s" x y e1 e2
  | Tail, IfFLE(x, y, e1, e2) -> g'_tail_if oc "ble.s" x y e1 e2

  | NonTail(z), IfEq(x, y, e1, e2) -> g'_non_tail_if oc (NonTail(z)) "beq" x y e1 e2
  | NonTail(z), IfLE(x, y, e1, e2) -> g'_non_tail_if oc (NonTail(z)) "ble" x y e1 e2
  | NonTail(z), IfFEq(x, y, e1, e2) -> g'_non_tail_if oc (NonTail(z)) "beq.s" x y e1 e2
  | NonTail(z), IfFLE(x, y, e1, e2) -> g'_non_tail_if oc (NonTail(z)) "ble.s" x y e1 e2

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
      let ss = stacksize () in  (* ssがそんなに大きくないことが前提 *)
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      Printf.fprintf oc "\tlw\t%s, 0(%s)\n" reg_sw reg_cl;
      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp ss;
      (* CallClsでバグる、下の行をよく考えよう *)
      (* Printf.fprintf oc "\tjral\t%s\n" reg_sw; *)

      let tmp_label = Id.genid "tmp" in
      Printf.fprintf oc "\tla\t%s, %s\n" reg_ra tmp_label;
      (* Printf.fprintf oc "\taddi\t%s, %s, 12\n" reg_ra reg_ra; *)
      Printf.fprintf oc "\tjr\t%s\n" reg_sw;
      Printf.fprintf oc "%s:\n" tmp_label;

      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp (-ss);
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      if List.mem a allregs && a <> regs.(0) then
        Printf.fprintf oc "\tmv\t%s, %s\n" a regs.(0)
      else if List.mem a allfregs && a <> fregs.(0) then
        Printf.fprintf oc "\tmv.s\t%s, %s\n" a fregs.(0)
      (* else if List.mem a allfregs && a <> fregs.(0) then
        (Printf.fprintf oc "\tfmovs\t%s, %s\n" fregs.(0) a;
         Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg fregs.(0)) (co_freg a)) *)
  | NonTail(a), CallDir(Id.L(x), ys, zs) ->
      g'_args oc [] ys zs;
      let ss = stacksize () in
      Printf.fprintf oc "\tsw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp ss;
      Printf.fprintf oc "\tjal\t%s\n" x;
      Printf.fprintf oc "\taddi\t%s, %s, %d\n" reg_sp reg_sp (-ss);
      Printf.fprintf oc "\tlw\t%s, %d(%s)\n" reg_ra (ss - 4) reg_sp;
      if List.mem a allregs && a <> regs.(0) then
        Printf.fprintf oc "\tmv\t%s, %s\n" a regs.(0)
      else if List.mem a allfregs && a <> fregs.(0) then
        Printf.fprintf oc "\tmv.s\t%s, %s\n" a fregs.(0)
      (* else if List.mem a allfregs && a <> fregs.(0) then
        (Printf.fprintf oc "\tfmovs\t%s, %s\n" fregs.(0) a;
         Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg fregs.(0)) (co_freg a)) *)

and g'_tail_if oc b x y e1 e2 =
  let b_then = Id.genid (b ^ "_then") in
  Printf.fprintf oc "\t%s\t%s, %s, %s\n" b x y b_then;
  let stackset_back = !stackset in
  g oc (Tail, e2);
  Printf.fprintf oc "%s:\n" b_then;
  stackset := stackset_back;
  g oc (Tail, e1)

and g'_non_tail_if oc dest b x y e1 e2 =
  let b_then = Id.genid (b ^ "_then") in
  let b_cont = Id.genid (b ^ "_cont") in
  Printf.fprintf oc "\t%s\t%s, %s, %s\n" b x y b_then;
  let stackset_back = !stackset in
  g oc (dest, e2);
  let stackset1 = !stackset in
  Printf.fprintf oc "\tj\t%s\n" b_cont;
  Printf.fprintf oc "%s:\n" b_then;
  stackset := stackset_back;
  g oc (dest, e1);
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
    (fun (y, r) -> Printf.fprintf oc "\tmv\t%s, %s\n" r y)
    (shuffle reg_sw yrs);
  let (d, zfrs) =
    List.fold_left
      (fun (d, zfrs) z -> (d + 1, (z, fregs.(d)) :: zfrs))
      (0, [])
      zs in
  List.iter
    (fun (z, fr) ->
      Printf.fprintf oc "\tmv.s\t%s, %s\n" fr z)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" z fr; *)
      (* Printf.fprintf oc "\tfmovs\t%s, %s\n" (co_freg z) (co_freg fr)) *)
    (shuffle reg_fsw zfrs)

let h oc { name = Id.L(x); args = _; fargs = _; body = e; ret = _ } =
  Printf.fprintf oc "%s:\n" x;
  stackset := S.empty;
  stackmap := [];
  g oc (Tail, e)

let f oc (Prog(fundefs, e)) =
  Format.eprintf "generating assembly...@.";

  (* 適当な順番に並び替えて *)
  
  (* どこに置くべき???? *)
  stackset := S.empty;
  stackmap := [];

  Printf.fprintf oc "min_caml_start:\n";    (* "main"の方が良い? *)

  (* 値は適当に決めて → simulatorが決めてくれそう *)
  (* Printf.fprintf oc "\tori\t$sp, $zero, 16\n"; *)
  (* Printf.fprintf oc "\tlui\t$gp, 1\n";   *)

  (* g oc (NonTail("$dummy"), e); *)
  g oc (NonTail(regs.(0)), e);    (* MLの最後がintとかなら、ここに値が入る *)

  Printf.fprintf oc "\tnoop\n";    (**コア係より末尾にNopが欲しい *)

  List.iter (fun fundef -> h oc fundef) fundefs;

  (* Printf.fprintf oc ".section \".text\"\n"; *)

  let lib = open_in "libmincaml.S" in
  try
    while true do Printf.fprintf oc "%s\n" (input_line lib) done
  with End_of_file -> ();
  close_in lib;

(*
  (* libに書くべし .sじゃなくて.mlの方が最適化できそう *)
  (* outの付け足し  後でインライン化してね *)
  (* Printf.fprintf oc "min_caml_print_int:\n"; *)
  (* Printf.fprintf oc "\tout\t$2\n"; *)
  (* Printf.fprintf oc "\tjr\t%s\n" reg_ra; *)
  Printf.fprintf oc "min_caml_print_int:\n";
  Printf.fprintf oc "\tslti\t$at, $2, 0\n";
  Printf.fprintf oc "\tblez\t$at, min_caml_print_int_label0\n";
  Printf.fprintf oc "\tori\t$3, $zero, 45\t\t# '-'\n";
  Printf.fprintf oc "\tout\t$3\n";
  Printf.fprintf oc "\tsub\t$2, $zero, $2\n";
  Printf.fprintf oc "min_caml_print_int_label0:\n";
  Printf.fprintf oc "\tor\t$3, $zero, $2\n";
  Printf.fprintf oc "\tori\t$4, $zero, 1\n";
  Printf.fprintf oc "\tori\t$5, $zero, 10\n";
  Printf.fprintf oc "min_caml_print_int_label1:\n";
  Printf.fprintf oc "\tdiv\t$3, $3, $5\n";  (* divu???? *)
  Printf.fprintf oc "\tmult\t$4, $4, $5\n";  (* multu???? *)
  Printf.fprintf oc "\tslti\t$at, $3, 1\n";
  Printf.fprintf oc "\tblez\t$at, min_caml_print_int_label1\n";
  Printf.fprintf oc "min_caml_print_int_label2:\n";
  Printf.fprintf oc "\tori\t$5, $zero, 10\n";
  Printf.fprintf oc "\tdiv\t$4, $4, $5\n";  (* divu???? *)
  Printf.fprintf oc "\tdiv\t$3, $2, $4\n";  (* divu???? *)
  Printf.fprintf oc "\taddi\t$5, $3, 48\n";  
  Printf.fprintf oc "\tout\t$5\n";
  Printf.fprintf oc "\tslti\t$at, $4, 2\n";
  Printf.fprintf oc "\tbgtz\t$at, min_caml_print_int_label3\n";
  Printf.fprintf oc "\tmult\t$3, $3, $4\n";  (* multu???? *)
  Printf.fprintf oc "\tsub\t$2, $2, $3\n";
  Printf.fprintf oc "\tj\tmin_caml_print_int_label2\n";
  Printf.fprintf oc "min_caml_print_int_label3:\n";
  Printf.fprintf oc "\tjr\t$ra\n";

  (* print_newline  アセンブラじゃなくてmin-camlで書きたい↑↓ *)
  Printf.fprintf oc "min_caml_print_newline:\n";
  Printf.fprintf oc "\tori\t$2, $zero, 10\n";
  Printf.fprintf oc "\tout\t$2\n";
  Printf.fprintf oc "\tjr\t%s\n" reg_ra;

  (* float_of_intは関数呼び出しで対応  後でインライン化すること *)
  Printf.fprintf oc "min_caml_float_of_int:\n";
  Printf.fprintf oc "\titof\t$f2, $2\n";
  Printf.fprintf oc "\tjr\t%s\n" reg_ra;
*)
  (* List.iter (fun fundef -> h oc fundef) fundefs; *)

  (* Printf.fprintf oc ".global min_caml_start\n"; *)
  (* Printf.fprintf oc "min_caml_start:\n"; *)   (* "main"の方が良い? *)
  (* Printf.fprintf oc "\tsave\t$sp, -112, $sp\n"; (* from gcc; why 112? *) *)
  (* Printf.fprintf oc "\tsave\t$sp, -120, $sp\n"; *)
  
  (* stackset := S.empty; *)
  (* stackmap := [] *)

  (* メイン関数を末尾再帰最適すると、少し怖そうなので今はやめときます。
     noop命令も追加したし、関数呼び出しで命令が終わったら$raがundefinedになっちゃうので *)
  (* g oc (Tail, e); *)
  (* g oc (NonTail("%g0"), e) *)    (* why? "%g0"とは? dummy
                                        main(min_caml_start)が他のルーチンから呼び出されてると考える必要なさそう *)
  (* g oc (NonTail("%dummy"), e); *)

  (* 要確認 終了動作 *)
  (* Printf.fprintf oc "\tret\n"; *)
  (* Printf.fprintf oc "\trestore\n" *)

  (* Printf.fprintf oc "\tnoop\n" *)   (**コア係より末尾にNopが欲しい *)


  (* ちゃんとプラス方向にしかメモリが伸びないか確かめてください *)
  (* $sp, $gp, $zeroの扱いに注意してね *)
