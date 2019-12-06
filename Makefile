# Sumii's Makefile for Min-Caml (for GNU Make)
# 
# ack.mlなどのテストプログラムをtest/に用意してmake do_testを実行すると、
# min-camlとocamlでコンパイル・実行した結果を自動で比較します。

RESULT = min-caml
NCSUFFIX = .opt
CC = gcc
CFLAGS = -g -O2 -Wall
OCAMLLDFLAGS=-warn-error -31

default: debug-code top $(RESULT) do_test
$(RESULT): debug-code top
## [自分（住井）用の注]
## ・OCamlMakefileや古いGNU Makeのバグ(?)で上のような定義が必要(??)
## ・OCamlMakefileではdebug-codeとnative-codeのそれぞれで
##   .mliがコンパイルされてしまうので、両方ともdefault:の右辺に入れると
##   再make時に（.mliが変更されているので）.mlも再コンパイルされる
clean:: nobackup

# ↓もし実装を改造したら、それに合わせて変える
SOURCES = float.c type.ml id.ml m.ml s.ml outputId.mli outputId.ml outputType.mli outputType.ml \
syntax.ml outputSyntax.mli outputSyntax.ml parser.mly lexer.mll typing.mli typing.ml kNormal.mli kNormal.ml \
alpha.mli alpha.ml beta.mli beta.ml assoc.mli assoc.ml \
inline.mli inline.ml constFold.mli constFold.ml elim.mli elim.ml \
outputKNormal.mli outputKNormal.ml commonSubexpressionElimination.mli commonSubexpressionElimination.ml \
closure.mli closure.ml asm.mli asm.ml virtual.mli virtual.ml \
simm.mli simm.ml regAlloc.mli regAlloc.ml emit.mli emit.ml \
 \
outputClosure.mli outputClosure.ml outputAsm.mli outputAsm.ml \
main.mli main.ml

# ↓テストプログラムが増えたら、これも増やす
# TESTS_ = $(wildcard test/*.ml)
# TESTS = $(TESTS_:test/%.ml=%)
# 上をちゃんと書いて
# TESTS = print sum-tail gcd sum fib ack even-odd \
# adder funcomp cls-rec cls-bug cls-bug2 cls-reg-bug \
# shuffle spill spill2 spill3 join-stack join-stack2 join-stack3 \
# join-reg join-reg2 non-tail-if non-tail-if2 \
# inprod inprod-rec inprod-loop matmul matmul-flat
# manyargs
# TESTS = print sum-tail gcd sum fib ack even-odd float1 float2 mandelbrot
# TESTS = week2-1 week2-2 week2-3a1 week2-3a2 week2-3b1 week2-3b2
# TESTS = week3-1 week3-3-1 week3-3-2 week3-3-3 week3-3-4 week3-3-5 week3-3-6 cls-bug cls-bug2 cls-rec cls-reg-bug
# TESTS = week5-1 fib ack
TESTS = non-tail-if inprod-rec inprod-loop

# ここから（SPARC, PowerPC, x86, MIPS, chahanによりコンパイル方法が異なる）
# do_test: $(TESTS:%=test/%.s) $(TESTS:%=test/%.ans)

# .PRECIOUS: test/%.txt test/%.s test/% test/%.res test/%.ans test/%.cmp
# TRASH = $(TESTS:%=test/%.txt) $(TESTS:%=test/%.s) $(TESTS:%=test/%) $(TESTS:%=test/%.res) $(TESTS:%=test/%.ans) $(TESTS:%=test/%.cmp)

# test/%.txt test/%.s: $(RESULT) test/%.ml
# 	./$(RESULT) test/$*
# test/%.ans: test/%.ml
# 	ocaml $< > $@
# ここまで

min-caml.html: main.mli main.ml id.ml m.ml s.ml \
		syntax.ml type.ml parser.mly lexer.mll typing.mli typing.ml kNormal.mli kNormal.ml \
		alpha.mli alpha.ml beta.mli beta.ml assoc.mli assoc.ml \
		inline.mli inline.ml constFold.mli constFold.ml elim.mli elim.ml \
		closure.mli closure.ml asm.mli asm.ml virtual.mli virtual.ml \
		simm.mli simm.ml regAlloc.mli regAlloc.ml emit.mli emit.ml
	./to_sparc
	caml2html -o min-caml.html $^
	sed 's/.*<\/title>/MinCaml Source Code<\/title>/g' < min-caml.html > min-caml.tmp.html
	mv min-caml.tmp.html min-caml.html
	sed 's/charset=iso-8859-1/charset=euc-jp/g' < min-caml.html > min-caml.tmp.html
	mv min-caml.tmp.html min-caml.html
	ocaml str.cma anchor.ml < min-caml.html > min-caml.tmp.html
	mv min-caml.tmp.html min-caml.html

release: min-caml.html
	rm -fr tmp ; mkdir tmp ; cd tmp ; cvs -d:ext:sumii@min-caml.cvs.sf.net://cvsroot/min-caml export -Dtomorrow min-caml ; tar cvzf ../min-caml.tar.gz min-caml ; cd .. ; rm -fr tmp
	cp Makefile stub.c SPARC/libmincaml.S min-caml.html min-caml.tar.gz ../htdocs/

include make.mk    # make -f make.mk にしても良かった?? でも、コード生成とdo_testを区別できないか
include OCamlMakefile

# https://qiita.com/uni-3/items/f7d7d7004cde146b6547
# https://qiita.com/Shigets/items/27170827707e5136ee89
