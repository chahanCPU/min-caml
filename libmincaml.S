# 全部.mlにしたい。このためだけにスタックの確保・退避を行うのはコストが高い。
# asm.mlのexpに命令を追加して、インライン化・レジスタ割当ができるように。
# simulator: ラベルにコメントをつけると、だめっぽい？
# ライブラリ
# min_caml_print_newline:
# 	ori	$2, $zero, 10		# LF
# 	out	$2
# 	jr	$ra
# min_caml_print_int:
# 	slti	$at, $2, 0
# 	blez	$at, print_int_label0
# 	ori	$3, $zero, 45		# '-'
# 	out	$3
# 	sub	$2, $zero, $2
# print_int_label0:
# 	or	$3, $zero, $2
# 	ori	$4, $zero, 1
# 	ori	$5, $zero, 10
# print_int_label1:
# 	div	$3, $3, $5		# divu?
# 	mult	$4, $4, $5		# multu?
# 	slti	$at, $3, 1
# 	blez	$at, print_int_label1
# print_int_label2:
# 	ori	$5, $zero, 10
# 	div	$4, $4, $5		# divu?
# 	div	$3, $2, $4		# divu?
# 	addi	$5, $3, 48
# 	out	$5
# 	slti	$at, $4, 2
# 	bgtz	$at, print_int_label3
# 	mult	$3, $3, $4		# multu?
# 	sub	$2, $2, $3
# 	j	print_int_label2
# print_int_label3:
# 	jr	$ra
# min_caml_print_byte:
# 	out	$2
# 	jr	$ra
# min_caml_prerr_int:		# 未実装
# min_caml_prerr_byte:		# 未実装
# min_caml_prerr_float:		# 未実装
min_caml_read_int:
	# ori	$at, $at, 0    # inは上位24ビットをゼロ埋め
	in	$1
	sll	$1, $1, 24
	in	$2
	sll	$2, $2, 16
	add	$1, $1, $2
	in	$2
	sll	$2, $2, 8
	add	$1, $1, $2
	in	$2
	add	$1, $1, $2
	jr	$ra
min_caml_read_float:
	# ori	$at, $at, 0    # inは上位24ビットをゼロ埋め
	in	$1
	sll	$1, $1, 24
	in	$2
	sll	$2, $2, 16
	add	$1, $1, $2
	in	$2
	sll	$2, $2, 8
	add	$1, $1, $2
	in	$2
	add	$1, $1, $2
	sw	$1, 16($sp)		# 16?
	lw.s	$f1, 16($sp)		# 16?
	jr	$ra
min_caml_create_array:
	mv	$3, $1
	mv	$1, $gp
create_array_loop:
	ble	$3, $zero, create_array_exit
	sw	$2, 0($gp)
	addi	$3, $3, -1
	addi	$gp, $gp, 4
	j	create_array_loop
create_array_exit:
	jr	$ra
min_caml_create_float_array:
	mv	$2, $1
	mv	$1, $gp
create_float_array_loop:
	ble	$2, $zero, create_float_array_exit
	sw.s	$f1, 0($gp)
	addi	$2, $2, -1
	addi	$gp, $gp, 4
	j	create_float_array_loop
create_float_array_exit:
	jr	$ra
# min_caml_abs_float:		# libmincaml.mlを参照
# min_caml_sqrt:
# 	sqrt.s	$f2, $f2
# 	jr	$ra
# min_caml_floor:		# libmincaml.mlを参照
# min_caml_int_of_float:
# min_caml_truncate:
# 	ftoi	$2, $f2
# 	jr	$ra
# min_caml_float_of_int:
# 	itof	$f2, $2
# 	jr	$ra
# min_caml_cos:		# libmincaml.mlを参照
# min_caml_sin:		# libmincaml.mlを参照
# min_caml_atan:		# libmincaml.mlを参照
# min_caml_print_char:		# print_byte, raytracer専用?
# 	out	$2
# 	jr	$ra
