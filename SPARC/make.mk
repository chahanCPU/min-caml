assembly: $(TESTS:%=test/%.s)
do_test: $(TESTS:%=test/%.s) $(TESTS:%=test/%.ans)

# ここも要検討
.PRECIOUS: test/%.txt test/%.s test/% test/%.res test/%.ans test/%.cmp
TRASH = $(TESTS:%=test/%.txt) $(TESTS:%=test/%.s) $(TESTS:%=test/%) $(TESTS:%=test/%.res) $(TESTS:%=test/%.ans) $(TESTS:%=test/%.cmp)

# test/%.txt test/%.s: $(RESULT) test/%.ml
test/%.s: $(RESULT) test/%.ml
	./$(RESULT) test/$*
test/%.ans: test/%.ml
	ocaml $< > $@
