type id_or_int = V of Id.t | C of int  (* intには定数レジスタの中身が入る *)
type id_or_float = W of Id.t | D of float
type t =
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp =
  | Nop
  | Set of int
  | FSetD of float
  | SetL of Id.l
  | Mov of id_or_int
  (* | Neg of Id.t *)
  | Add of id_or_int * id_or_int
  | Addi of id_or_int * int  (* 即値は16ビット、すなわち-32768以上32768未満 *)
  | Sub of id_or_int * id_or_int
  | Mul of id_or_int * id_or_int
  | Div of id_or_int * id_or_int
  | SLL of id_or_int * int
  | SRA of id_or_int * int
  | Ld of Id.t * int
  | St of Id.t * Id.t * int
  | FMovD of id_or_float
  | FNegD of id_or_float
  | FAddD of id_or_float * id_or_float
  | FSubD of id_or_float * id_or_float
  | FMulD of id_or_float * id_or_float
  (* | FDivD of Id.t * Id.t *)
  | FInv of id_or_float
  | LdDF of Id.t * int
  | StDF of Id.t * Id.t * int
  (* virtual instructions *)
  | IfEq of id_or_int * id_or_int * t * t
  | IfLE of id_or_int * id_or_int * t * t
  | IfFEq of id_or_float * id_or_float * t * t
  | IfFLE of id_or_float * id_or_float * t * t
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list
  | CallDir of Id.l * Id.t list * Id.t list
  | Save of Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 *)
  | Restore of Id.t (* スタック変数から値を復元 *)
  (* もともとライブラリにあった命令 *)
  | In
  | Out of id_or_int
  | OutInt of id_or_int
  | FAbs of id_or_float
  | FSqrt of id_or_float
  | FTOI of id_or_float
  | ITOF of id_or_int
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
type prog = Prog of fundef list * t

val fletd : Id.t * exp * t -> t (* shorthand of Let for float *)
val seq : exp * t -> t (* shorthand of Let for unit *)

val regs_const : (int * Id.t) list
val fregs_const : (float * Id.t) list
val regs : Id.t array
val fregs : Id.t array
val allregs : Id.t list
val allfregs : Id.t list
val reg_cl : Id.t
val reg_sw : Id.t
val reg_fsw : Id.t
val reg_ra : Id.t
val reg_hp : Id.t
val reg_sp : Id.t
val is_reg : Id.t -> bool
(* val co_freg : Id.t -> Id.t (* 2つのレジスタでdouble型を扱う *) *)

val fv : t -> Id.t list
val concat : t -> Id.t * Type.t -> t -> t

(* val align : int -> int *)
