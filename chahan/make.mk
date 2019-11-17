# do_test: $(TESTS:%=test/%.s.binary) $(TESTS:%=test/%.s.bintext) $(TESTS:%=test/%.ans)
do_test: $(TESTS:%=test/%.s) $(TESTS:%=test/%.ans)

.PRECIOUS: test/%.txt test/%.s test/% test/%.res test/%.ans test/%.cmp
TRASH = $(TESTS:%=test/%.txt) $(TESTS:%=test/%.s) $(TESTS:%=test/%) $(TESTS:%=test/%.res) $(TESTS:%=test/%.ans) $(TESTS:%=test/%.cmp)

test/%.txt test/%.s: $(RESULT) test/%.ml
	./$(RESULT) test/$*
test/%.s.binary test/%.s.bintext: test/%.s simulator
	-make -C simulator TESTS=../$<
	# -によりmakeに失敗しても引き続きmakeが行われる
	# -Cで、cd simulator/; make; cd ../
test/%.ans: test/%.ml
	ocaml $< > $@
