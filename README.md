# Heap

A memory manager written in Assembly language, utilizing the GNU Assembler (GAS) with AT&T syntax.

## Calling Convention

This implementation adheres to the 64-bit x86 C Calling Convention.

> The following is sourced from the initial document authored by Adam Ferrari, subsequently revised
> by Alan Batson, Mike Lack, Anita Jones, and Aaron Bloomfield. You should be able to locate it by
> searching for _The 64-bit x86 C Calling Convention_ in your internet search engine.

1. Before calling a subroutine, the caller should save the contents of certain registers that are
   designated caller-saved. The caller-saved registers are r10, r11, and any registers that
   parameters are put into. If you want the contents of these registers to be preserved across the
   subroutine call, push them onto the stack.
1. To pass parameters to the subroutine, we put up to six of them into registers (in order: rdi,
   rsi, rdx, rcx, r8, r9). If there are more than six parameters to the subroutine, then push the
   rest onto the stack in reverse order
1. To call the subroutine, use the `call` instruction. This instruction places the return address on
   top of the parameters on the stack, and branches to the subroutine code.
1. After the subroutine returns the caller must remove any additional parameters (beyond the six
   stored in registers) from stack. This restores the stack to its state before the call was
   performed.
1. The caller can expect to find the return value of the subroutine in the register RAX.
1. The caller restores the contents of caller-saved registers (r10, r11, and any in the parameter
   passing registers) by popping them off of the stack. The caller can assume that no other
   registers were modified by the subroutine.

## Building from source

To build the project, start by compiling the source code into object files and then gather them into
a single static library:

```zsh
mkdir build
as --64 -o build/heap.o heap.s
as --64 -o build/memcpy.o memcpy.s
as --64 -o build/common.o common.s
ar crs build/libheap.a build/heap.o build/memcpy.o build/common.o
```

Alternatively, you can use the gcc compiler to create a shared library and then link it into your
project in the same manner as you would with any other library:

```zsh
gcc -nostdlib -shared -o build/libheap.so heap.s memcpy.s common.s
```
