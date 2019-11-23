assembly: $(TESTS:%=test/%.s)
# do_test: $(TESTS:%=test/%.s) $(TESTS:%=test/%.ans)
# do_test: $(TESTS:%=test/%.s.binary) $(TESTS:%=test/%.s.bintext) $(TESTS:%=test/%.ans)
do_test: $(TESTS:%=test/%.cmp)

# ここも要検討
.PRECIOUS: test/%.txt test/%.s test/%.bin test/%.res test/%.ans test/%.cmp
TRASH = $(TESTS:%=test/%.txt) $(TESTS:%=test/%.s) $(TESTS:%=test/%.bin) $(TESTS:%=test/%.res) $(TESTS:%=test/%.ans) $(TESTS:%=test/%.cmp)

# test/%.txt test/%.s: $(RESULT) test/%.ml
test/%.s: $(RESULT) libmincaml.S libmincaml.ml test/%.ml
	@cp test/$*.ml .tmp0.ml
	@cat libmincaml.ml test/$*.ml > .tmp.ml
	@cp .tmp.ml test/$*.ml
	./$(RESULT) test/$*
	@cp .tmp0.ml test/$*.ml
	@rm -f .tmp0.ml .tmp.ml
# sed -i '1r libmincaml.ml' test/$*.ml
# cp libmincaml.ml temp.ml
# $(shell cat libmincaml.S test)
# $(file >> test/$*.ml, $(shell cat libmincaml.S))
# ./$(RESULT) test/$*
# ↑なぜか上手く行く 行かなかった
# 1行目でtest/*.mlの末尾にlibmincaml.Sを追加しているはずなのに
# 実行後にはもとのtest/*.mlに戻ってる
# makefileでリダイレクト・パイプを使うと上手く行かない
test/%.res: test/%.s 
	make -C simulator TESTS=../$<
	@rm -f $(*:%=test/%.s.binary)
	@mv $(*:%=test/%.s.bintext) $(*:%=test/%.bin)
	@mv $(*:%=test/%.s.res) $(*:%=test/%.res)
# simulatorの拡張子を書き直したい
# -によりmakeに失敗しても引き続きmakeが行われる
# @により標準出力に表示されない
# -Cで、cd simulator/; make; cd ../
test/%.ans: test/%.ml
	ocaml $< > $@
test/%.cmp: test/%.res test/%.ans
	-diff $^ > $@
# -によりmakeに失敗しても引き続きmakeが行われる
# mandelbrotで何故か失敗する。中身は正しそうだが
