CC ?= gcc
CFLAGS_common ?= -Wall -std=gnu99
CFLAGS_orig = -O0
CFLAGS_opt  = -O0 -pthread -g -pg
CFLAGS_lib = -lrt

ifdef CHECK_LEAK
CFLAGS_common += -fsanitize=address -fno-omit-frame-pointer
endif

ifdef THREAD
CFLAGS_opt  += -D THREAD_NUM=${THREAD}
endif

ifeq ($(strip $(THREAD_TEST)),1)
CFLAGS_opt  += -D THREAD_TEST
endif

ifeq ($(strip $(DEBUG)),1)
CFLAGS_opt += -DDEBUG -g
endif

EXEC = phonebook_orig phonebook_opt
GIT_HOOKS := .git/hooks/applied
.PHONY: all
all: $(GIT_HOOKS) $(EXEC)

$(GIT_HOOKS):
	@scripts/install-git-hooks
	@echo

SRCS_common = main.c

tools/text_align: text_align.c tools/tool-text_align.c
	$(CC) $(CFLAGS_common) $^ -o $@

phonebook_orig: $(SRCS_common) phonebook_orig.c phonebook_orig.h
	$(CC) $(CFLAGS_common) $(CFLAGS_orig) \
		-DIMPL="\"$@.h\"" -o $@ \
		$(SRCS_common) $@.c $(CFLAGS_lib)

phonebook_opt: $(SRCS_common) phonebook_opt.c phonebook_opt.h text_align.c
	$(CC) $(CFLAGS_common) $(CFLAGS_opt) \
		-DIMPL="\"$@.h\"" -o $@ \
		$(SRCS_common) $@.c text_align.c $(CFLAGS_lib)

run: $(EXEC)
	echo 3 | sudo tee /proc/sys/vm/drop_caches
	watch -d -t "./phonebook_orig && echo 3 | sudo tee /proc/sys/vm/drop_caches"

cache-test: $(EXEC)
	perf stat --repeat 100 \
		-e cache-misses,cache-references,instructions,cycles \
		./phonebook_orig
	perf stat --repeat 100 \
		-e cache-misses,cache-references,instructions,cycles \
		./phonebook_opt

output.txt: cache-test calculate
	./calculate

plot: output.txt
	gnuplot scripts/runtime.gp

calculate: calculate.c
	$(CC) $(CFLAGS_common) $^ -o $@

thread_test: main.c
	for i in `seq 1 128`; \
	do $(MAKE) phonebook_opt THREAD_TEST=1 THREAD=$$i --silent; \
	./phonebook_opt; echo "\n"; \
	rm -rf phonebook_opt; \
	done;

thread_test_plot: clean thread_test opt.txt
	gnuplot scripts/thread_test.gp

.PHONY: clean
clean:
	$(RM) $(EXEC) *.o perf.* \
	      	calculate orig.txt opt.txt output.txt *.png align.txt
