(* chahan assembly with a few virtual instructions *)

type id_or_int = V of Id.t | C of int  (* intには定数レジスタの中身が入る *)
type id_or_float = W of Id.t | D of float  (* 倍精度になるけど、いいかぁ *)
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
  | Mov of id_or_int
  | Add of id_or_int * id_or_int
  | Addi of id_or_int * int  (* 即値は16ビット、すなわち-32768以上32768未満 *)
  | Sub of id_or_int * id_or_int
  | Mul of id_or_int * id_or_int
  | Div of id_or_int * id_or_int
  | SLL of id_or_int * int
  | SRA of id_or_int * int
  | Ld of id_or_int * int
  | St of id_or_int * id_or_int * int
  | FMovD of id_or_float
  | FNegD of id_or_float
  | FAddD of id_or_float * id_or_float
  | FSubD of id_or_float * id_or_float
  | FMulD of id_or_float * id_or_float
  (* | FDivD of Id.t * Id.t *)
  | FInv of id_or_float
  | LdDF of id_or_int * int
  | StDF of id_or_float * id_or_int * int
  (* virtual instructions *)
  | IfEq of id_or_int * id_or_int * t * t
  | IfLE of id_or_int * id_or_int * t * t
      (* ↑ id_or_imm を Id.t に変更する。ゼロの特殊ケースver.を作る *)
  | IfFEq of id_or_float * id_or_float * t * t
  | IfFLE of id_or_float * id_or_float * t * t
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list
  | CallDir of Id.l * Id.t list * Id.t list
  | Save of Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 (caml2html: sparcasm_save) *)
  | Restore of Id.t (* スタック変数から値を復元 (caml2html: sparcasm_restore) *)
  (* もともとライブラリにあった命令 *)
  | In
  | Out of id_or_int
  | OutInt of id_or_int
  | FAbs of id_or_float
  | FSqrt of id_or_float
  | FTOI of id_or_float
  | ITOF of id_or_int
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
(* プログラム全体 = トップレベル関数 + メインの式 (caml2html: sparcasm_prog) *)
type prog = Prog of fundef list * t

let fletd(x, e1, e2) = Let((x, Type.Float), e1, e2)
let seq(e1, e2) = Let((Id.genid "Tunit", Type.Unit), e1, e2)
(* let seq(e1, e2) = Let((Id.gentmp Type.Unit, Type.Unit), e1, e2) *)

(* 定数レジスタの代入命令を書かなくちゃ *)
(* 本当はデータフロー解析とか、コントロール解析で勝手にやってほしいのだが *)
let regs_const =  (* 定数レジスタ *)
  [(0, "$0"); (1, "$1"); (2, "$2"); (3, "$3"); (4, "$4"); (5, "$5"); (255, "$6"); (-1, "$7")]
let fregs_const =
  [(0., "$f0")]
let regs = (* Array.init 16 (fun i -> Printf.sprintf "%%r%d" i) *)  (* 汎用レジスタ *)
  Array.init 53 (fun i -> Printf.sprintf "$%d" (i + 8))
(* よく考えて *)
(* $f0はゼロ、$f1は$atのノリで使ってる *)
let fregs = (* Array.init 16 (fun i -> Printf.sprintf "%%f%d" (i * 2)) *)
  Array.init 63 (fun i -> Printf.sprintf "$f%d" (i + 1))
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
let init_hp = ref 32

(* super-tenuki *)
let rec remove_and_uniq xs = function
  | [] -> []
  | x :: ys when S.mem x xs -> remove_and_uniq xs ys
  | x :: ys -> x :: remove_and_uniq (S.add x xs) ys

(* free variables in the order of use (for spilling) (caml2html: sparcasm_fv) *)
let fv_id_or_int = function V(x) -> [x] | C(_) -> []
let fv_id_or_float = function W(x) -> [x] | D(_) -> []
let rec fv_exp = function
  | Nop | Set(_) | FSetD(_) | SetL(_) | Restore(_) | In -> []
  | Mov(x) | Addi(x, _) | SLL(x, _) | SRA(x, _) | Ld(x, _) | LdDF(x, _) -> fv_id_or_int x
  | Add(x, y) | Sub(x, y) | Mul(x, y) | Div(x, y) | St(x, y, _) -> fv_id_or_int x @ fv_id_or_int y
  | Save(x, _) -> [x]
  | StDF(x, y, _) -> fv_id_or_float x @ fv_id_or_int y
  | FMovD(x) | FNegD(x) | FInv(x) -> fv_id_or_float x
  | FAddD(x, y) | FSubD(x, y) | FMulD(x, y) -> fv_id_or_float x @ fv_id_or_float y
  | IfEq(x, y, e1, e2) | IfLE(x, y, e1, e2) -> fv_id_or_int x @ fv_id_or_int y @ remove_and_uniq S.empty (fv e1 @ fv e2)
  | IfFEq(x, y, e1, e2) | IfFLE(x, y, e1, e2) -> fv_id_or_float x @ fv_id_or_float y @ remove_and_uniq S.empty (fv e1 @ fv e2)  (* uniq here just for efficiency *)
  | CallCls(x, ys, zs) -> x :: ys @ zs
  | CallDir(_, ys, zs) -> ys @ zs
  | Out(x) | OutInt(x) | ITOF(x) -> fv_id_or_int x
  | FAbs(x) | FSqrt(x) | FTOI(x) -> fv_id_or_float x
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
