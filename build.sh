
gcc -Wall -Wextra -std=c11 -pedantic -ggdb  -o x11_core.o -c x11_core.c -lX11 -lXext

  
ar rcs lib_x11_core.a x11_core.o 
  
echo --- compiled lib file ---

odin run . -extra-linker-flags:"-lX11 -lXext"
