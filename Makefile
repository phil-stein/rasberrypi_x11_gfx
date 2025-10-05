CFLAGS=-Wall -Wextra -std=c11 -pedantic -ggdb
LIBS=-lX11 -lXext

.PHONY: all
all: x11_core 


x11_core: obj
    $(CC) $(CFLAGS) -DDB_IMPL=DB_XIMAGE -o x11_core.o x11_core.c  $(LIBS)

obj:
    ar rcs lib_x11_core.a x11_core.o $(LIBS)
