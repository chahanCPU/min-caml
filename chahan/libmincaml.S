# 全部.mlにしたい。このためだけにスタックの確保・退避を行うのはコストが高い。
# asm.mlのexpに命令を追加して、インライン化・レジスタ割当ができるように。
# ライブラリ
min_caml_print_newline:
	ori	$2, $zero, 10		# LF
	out	$2
	jr	$ra
min_caml_print_int:
	slti	$at, $2, 0
	blez	$at, print_int_label0
	ori	$3, $zero, 45		# '-'
	out	$3
	sub	$2, $zero, $2
print_int_label0:
	or	$3, $zero, $2
	ori	$4, $zero, 1
	ori	$5, $zero, 10
print_int_label1:
	div	$3, $3, $5		# divu?
	mult	$4, $4, $5		# multu?
	slti	$at, $3, 1
	blez	$at, print_int_label1
print_int_label2:
	ori	$5, $zero, 10
	div	$4, $4, $5		# divu?
	div	$3, $2, $4		# divu?
	addi	$5, $3, 48
	out	$5
	slti	$at, $4, 2
	bgtz	$at, print_int_label3
	mult	$3, $3, $4		# multu?
	sub	$2, $2, $3
	j	print_int_label2
print_int_label3:
	jr	$ra
min_caml_print_byte:
	out	$2
	jr	$ra
# min_caml_prerr_int:		# 未実装
# min_caml_prerr_byte:		# 未実装
# min_caml_prerr_float:		# 未実装
min_caml_read_int:		# 動作確認をすること
	in	$2
	jr	$ra
min_caml_read_float:		# 動作確認をすること
	in	$at
	sw	$at, 16($sp)		# 16?
	lw.s	$f2, 16($sp)		# 16?
	jr	$ra
min_caml_create_array:		# まだできていない
	# mov	%i2, %i4		# 引数は%i2(配列の要素数)と%i3	(SPARC)
	# mov	%i1, %i2		# %i1はヒープポインタ	(SPARC)
	or	$4, $zero, $2
	or	$2, $zero, $gp
create_array_loop:
	# tst	%i4
	# bnz	create_array_cont
	bgtz	$4, create_array_cont
	andcc	%i1, 4, %g0
	bz	create_array_exit
	nop
	add	%i1, 4, %i1
create_array_exit:
	jr	$ra
create_array_cont:
	st	%i3, [%i1]
	dec	%i4
	add	%i1, 4, %i1
	b	create_array_loop
	nop
min_caml_create_float_array:		# まだできていない
	mov	%i2, %i3
	mov	%i1, %i2
create_float_array_loop:
	tst	%i3
	bnz	create_float_array_cont
	nop
	retl
	nop
create_float_array_cont:
	std	%f0, [%i1]
	dec	%i3
	add	%i1, 8, %i1
	b	create_float_array_loop
	nop
# min_caml_abs_float:		# libmincaml.mlを参照
min_caml_sqrt:
	fsqrt	$f2, $f2
	jr	$ra
# min_caml_floor:		# libmincaml.mlを参照
min_caml_int_of_float:
min_caml_truncate:
	ftoi	$2, $f2
	jr	$ra
min_caml_float_of_int:
	itof	$f2, $2
	jr	$ra
# min_caml_cos:		# libmincaml.mlを参照
# min_caml_sin:		# libmincaml.mlを参照
# min_caml_atan:		# libmincaml.mlを参照
