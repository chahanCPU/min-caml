assembly: $(TESTS:%=test/%.s)
# do_test: $(TESTS:%=test/%.s) $(TESTS:%=test/%.ans)
# do_test: $(TESTS:%=test/%.s.binary) $(TESTS:%=test/%.s.bintext) $(TESTS:%=test/%.ans)
do_test: $(TESTS:%=test/%.cmp)

# ここも要検討
.PRECIOUS: test/%.txt test/%.s test/%.bin test/%.res test/%.ans test/%.cmp
TRASH = $(TESTS:%=test/%.txt) $(TESTS:%=test/%.s) $(TESTS:%=test/%.bin) $(TESTS:%=test/%.res) $(TESTS:%=test/%.ans) $(TESTS:%=test/%.cmp)

# test/%.txt test/%.s: $(RESULT) test/%.ml
test/%.s: $(RESULT) test/%.ml
	./$(RESULT) test/$*
test/%.res: test/%.s simulator
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
	diff -a $^ > $@
# -によりmakeに失敗しても引き続きmakeが行われる
# mandelbrotで何故か失敗する。中身は正しそうだが
