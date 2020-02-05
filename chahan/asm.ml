(* chahan assembly with a few virtual instructions *)

type id_or_imm = V of Id.t | C of int
type t = (* 命令の列 (caml2html: sparcasm_t) *)
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp = (* 一つ一つの命令に対応する式 (caml2html: sparcasm_exp) *)
(* outとかしっかり自分たちのアーキテクチャに対応したいよなん。
   外部関数を呼ぶといちいちスタックフレームの確保・退避が起こって無駄だし、
   インライン化したら適切なレジスタ割当もできるから、良いことしかなさそう。
   今は一時レジスタ$atみたいな感じで無理やり辻褄を合わせてるけど、それも効率的に使いたいし *)
  | Nop
  | Set of int
  | FSetD of float
  | SetL of Id.l
  | Mov of Id.t
  | Neg of Id.t
  | Add of Id.t * id_or_imm
  | Sub of Id.t * id_or_imm
  | Mul of Id.t * Id.t
  | Div of Id.t * Id.t
  | SLL of Id.t * id_or_imm
  | SRA of Id.t * int
  | Ld of Id.t * id_or_imm
  | St of Id.t * Id.t * id_or_imm
  | FMovD of Id.t
  | FNegD of Id.t
  | FAddD of Id.t * Id.t
  | FSubD of Id.t * Id.t
  | FMulD of Id.t * Id.t
  (* | FDivD of Id.t * Id.t *)
  | FInv of Id.t
  | LdDF of Id.t * id_or_imm
  | StDF of Id.t * Id.t * id_or_imm
  | Comment of string
  (* virtual instructions *)
  | IfEq of Id.t * id_or_imm * t * t
  | IfLE of Id.t * id_or_imm * t * t
  | IfGE of Id.t * id_or_imm * t * t (* 左右対称ではないので必要 *)
  | IfFEq of Id.t * Id.t * t * t
  | IfFLE of Id.t * Id.t * t * t
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list
  | CallDir of Id.l * Id.t list * Id.t list
  | Save of Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 (caml2html: sparcasm_save) *)
  | Restore of Id.t (* スタック変数から値を復元 (caml2html: sparcasm_restore) *)
  (* もともとライブラリにあった命令 *)
  | Out of Id.t
  | OutInt of Id.t
  | FAbs of Id.t
  | FSqrt of Id.t
  | FTOI of Id.t
  | ITOF of Id.t
  | Cos of Id.t
  | Sin of Id.t
  | Tan of Id.t
  | ATan of Id.t
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
(* プログラム全体 = トップレベル関数 + メインの式 (caml2html: sparcasm_prog) *)
type prog = Prog of fundef list * t

let fletd(x, e1, e2) = Let((x, Type.Float), e1, e2)
let seq(e1, e2) = Let((Id.genid "Tunit", Type.Unit), e1, e2)
(* let seq(e1, e2) = Let((Id.gentmp Type.Unit, Type.Unit), e1, e2) *)

let regs = (* Array.init 16 (fun i -> Printf.sprintf "%%r%d" i) *)
  [| "$2"; "$3"; 
     "$4"; "$5"; "$6"; "$7"; 
     "$8"; "$9"; "$10"; "$11"; "$12"; "$13"; "$14"; "$15";
     "$16"; "$17"; "$18"; "$19"; "$20"; "$21"; "$22"; "$23";
     "$24"; "$25"; 
     "$26"; "$27";
     "$30" |]
(* よく考えて *)
(* $f0はゼロ、$f1は$atのノリで使ってる *)
let fregs = (* Array.init 16 (fun i -> Printf.sprintf "%%f%d" (i * 2)) *)
  Array.init 30 (fun i -> Printf.sprintf "$f%d" (i + 2))
(* 浮動小数は班員と要相談 *)
let allregs = Array.to_list regs
let allfregs = Array.to_list fregs
let reg_cl = regs.(Array.length regs - 1) (* closure address (caml2html: sparcasm_regcl) *)
let reg_sw = regs.(Array.length regs - 2) (* temporary for swap *)
let reg_fsw = fregs.(Array.length fregs - 1) (* temporary for swap *)
let reg_sp = "$sp" (* stack pointer *)
let reg_hp = "$gp" (* heap pointer (caml2html: sparcasm_reghp) *)
let reg_ra = "$ra" (* return address *)
let is_reg x = (x.[0] = '$')
(* let co_freg_table =
  let ht = Hashtbl.create 16 in
  for i = 0 to 15 do
    Hashtbl.add
      ht
      (Printf.sprintf "%%f%d" (i * 2))
      (Printf.sprintf "%%f%d" (i * 2 + 1))
  done;
  ht
let co_freg freg = Hashtbl.find co_freg_table freg (* "companion" freg *) *)

(* super-tenuki *)
let rec remove_and_uniq xs = function
  | [] -> []
  | x :: ys when S.mem x xs -> remove_and_uniq xs ys
  | x :: ys -> x :: remove_and_uniq (S.add x xs) ys

(* free variables in the order of use (for spilling) (caml2html: sparcasm_fv) *)
let fv_id_or_imm = function V(x) -> [x] | _ -> []
let rec fv_exp = function
  | Nop | Set(_) | FSetD(_) | SetL(_) | Comment(_) | Restore(_) -> []
  | Mov(x) | Neg(x) | SRA(x, _) | FMovD(x) | FNegD(x) | FInv(x) | Save(x, _) | Out(x) | OutInt(x) | FAbs (x) | FSqrt (x) | FTOI(x) | ITOF(x) | Cos(x) | Sin(x) | Tan(x) | ATan(x) -> [x]
  | Add(x, y') | Sub(x, y') | SLL(x, y') | Ld(x, y') | LdDF(x, y') -> x :: fv_id_or_imm y'
  | St(x, y, z') | StDF(x, y, z') -> x :: y :: fv_id_or_imm z'
  | Mul(x, y) | Div(x, y) | FAddD(x, y) | FSubD(x, y) | FMulD(x, y) -> [x; y]
  | IfEq(x, y', e1, e2) | IfLE(x, y', e1, e2) | IfGE(x, y', e1, e2) -> x :: fv_id_or_imm y' @ remove_and_uniq S.empty (fv e1 @ fv e2) (* uniq here just for efficiency *)
  | IfFEq(x, y, e1, e2) | IfFLE(x, y, e1, e2) -> x :: y :: remove_and_uniq S.empty (fv e1 @ fv e2) (* uniq here just for efficiency *)
  | CallCls(x, ys, zs) -> x :: ys @ zs
  | CallDir(_, ys, zs) -> ys @ zs
and fv = function
  | Ans(exp) -> fv_exp exp
  | Let((x, t), exp, e) ->
      fv_exp exp @ remove_and_uniq (S.singleton x) (fv e)
let fv e = remove_and_uniq S.empty (fv e)

let rec concat e1 xt e2 =
  match e1 with
  | Ans(exp) -> Let(xt, exp, e2)
  | Let(yt, exp, e1') -> Let(yt, exp, concat e1' xt e2)

(* let align i = (if i mod 8 = 0 then i else i + 4) *)
