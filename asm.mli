type id_or_imm = V of Id.t | C of int
type t =
  | Ans of exp
  | Let of (Id.t * Type.t) * exp * t
and exp =
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
  (* virtual instructions *)
  | IfEq of Id.t * id_or_imm * t * t
  | IfLE of Id.t * id_or_imm * t * t
  | IfGE of Id.t * id_or_imm * t * t
  | IfFEq of Id.t * Id.t * t * t
  | IfFLE of Id.t * Id.t * t * t
  (* closure address, integer arguments, and float arguments *)
  | CallCls of Id.t * Id.t list * Id.t list
  | CallDir of Id.l * Id.t list * Id.t list
  | Save of Id.t * Id.t (* レジスタ変数の値をスタック変数へ保存 *)
  | Restore of Id.t (* スタック変数から値を復元 *)
  (* もともとライブラリにあった命令 *)
  | Out of Id.t
  | OutInt of Id.t
  | FAbs of Id.t
  | FSqrt of Id.t
  | FTOI of Id.t
  | ITOF of Id.t
type fundef = { name : Id.l; args : Id.t list; fargs : Id.t list; body : t; ret : Type.t }
type prog = Prog of fundef list * t

val fletd : Id.t * exp * t -> t (* shorthand of Let for float *)
val seq : exp * t -> t (* shorthand of Let for unit *)

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
