# Heap

A simple memory manager written in Assembly language, utilizing the GNU Assembler (GAS) with AT&T
syntax.

## Overview

This implementation is a very rudimentary alternative to the memory allocator commonly encountered
in the C language, but it effectively illustrates how memory within our computer systems works.

Initially, the program is provided with only a limited set of methods for handling information.
Application data can be stored either in the CPU registers or placed on the stack. While the former
offers exceptionally fast memory access, developers are constrained by a finite number of available
registers. On the other hand, the latter option allows for a more flexible memory management
approach, but it employs the stack data structure, suitable primarily for storing local values that
can be used by a specific sequence of instructions. Certainly, there is the option of using a file
system as well, but its utilization would lead to suboptimal performance, as it was never
specifically designed for such a purpose.

The primary issue lies in the absence of a specific type of memory that can be dynamically expanded,
contracted, and accessed from any part of the application at any given time. This is where the
program's heap becomes significant.

As you may already know, before our program's initial instruction is carried out, the system's
kernel creates a so-called sandbox for our program to play in. This 'so-called sandbox' is also
often referred to as virtual memory. Essentially, it's just a mapping technique that allows our
program to interact with an abstracted, virtual address space that is then mapped to the actual
physical memory located on RAM chips or swap drives. Trying to access an unmapped virtual address
will result in an error known as a segmentation fault. The program break point represents the last
valid address that we can use.

The objective is to have the flexibility to relocate the program's break point at any given moment,
which can be accomplished through the use of the 'brk' system call. However, there is another
valuable system call 'mmap' allowing the mapping of memory pages for our program's use. Nonetheless,
due to its higher complexity, this implementation gives the preference to the former syscall over
the latter.

Unfortunately, solely relying on the system call is insufficient because new allocations only occur
beyond the program's break point. Hence, it's crucial to find a way to reuse previously allocated
chunks whenever feasible. And that's precisely what this memory allocator implementation addresses.

> If you're keen on delving into the details of how computer systems operate, consider reading
> _Programming from the Ground Up_ by Jonathan Bartlett. Despite being written some time ago, it
> effectively covers important concepts and introduces Assembly coding fundamentals.

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

## Calling Convention

This implementation adheres to the 64-bit x86 C Calling Convention. Nonetheless, given the absence
of a standard and the possibility of changes in the foreseeable future, despite C being known for
its compatibility with new standards, the guidelines for invoking a subroutine are provided below.

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

## Example C program

Unlike typical C libraries, whether static or shared, this library lacks explicit declarations for
the functions it implements. In other words, there are no header files. Hence, it is necessary to
manually define function signatures before using them in our C code. The following code illustrates
this process:

```cpp
extern void  _hinit(void);
extern void *_malloc(size_t);
extern void *_realloc(size_t, void *);
extern void *_free(void *);
```

Now, if you’ve been paying attention, you have noticed that there is no declaration of the
`_memcpy()` function, even though we implement it
[here.](https://github.com/byut/heap/blob/main/memcpy.s) Given that we won't be utilizing it in our
C code, the compiler, while examining our C program, doesn't need to be aware that it was defined
somewhere else. In fact, within the context of our C program, it doesn't need to have any knowledge
of its existence whatsoever.

Considering the nature of the task, we want a memory allocator to be universal for any of the
available data types. Therefore, in this example program, we'll attempt to allocate a structure that
contains fields of various sizes. It will appear as follows:

```cpp
typedef struct data_st {
    uint8_t  uint8;
    uint16_t uint16;
    uint32_t uint32;
    uint64_t uint64;
    int8_t   int8;
    int16_t  int16;
    int32_t  int32;
    int64_t  int64;
    double   double_;
    float    float_;
    char    *string;
    bool     boolean;
} Data;
```

As you can see, we have signed and unsigned integers of varying capacities, double, float, character
pointer (string), and boolean data types. Following the allocation of the required memory for this
structure, we'll assign each field its respective maximum value (except for signed integers, where
we'll assign their minimum value to emphasize their signed nature). This approach allows us to
ensure that the memory chunks have been appropriately aligned by our memory allocator.

Let's construct our main function:

```cpp
int main(int argc, char *argv[]) {
    // Initialize the heap
    _hinit();

    // Allocate enough memory space for our structure
    Data *pData = _malloc(sizeof(Data));

    // Assign each field its respective max value (min for signed integers)
    Data_max(pData);

    // Print the result
    Data_print(pData);

    // Exit with a success status
    return 0;
}
```

> Please note that `Data_max()` and `Data_print()` are not included in the C standard library. I
> haven't included their source code here, as the section has already exceeded my initial
> expectations regarding its length.

Now, all that remains is to link our library and compile everything into a unified executable:

```zsh
gcc -L<path_to_lib_dir> -o build/out main.c -lheap
```

If you have compiled the library as a shared one, you'll also need to specify the LD_LIBRARY_PATH so
that the program can locate our library once it has been successfully compiled and linked.

If no errors occurred, you can run the executable generated by the gcc compiler. Here's the output I
received:

```
Address:   0x55ed25f1a00b

uint8_t:   255
uint16_t:  65535
uint32_t:  4294967295
uint64_t:  18446744073709551615
int8_t:    -128
int16_t:   -32768
int32_t:   -2147483648
int64_t:   -9223372036854775808
double:    1.7976931348623157e+308
float:     3.4028234664e+38
boolean:   true
string:    !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
```

It appears that everything is functioning as anticipated. Now, let's add a couple of reallocations
on top of that. However, this time, we'll allocate enough space to accommodate two instances of
these structures. And since reallocation involves moving any data stored in the reallocated chunk to
the new memory chunk, there is no need to assign any values to it.

The new piece of code appears as follows:

```cpp
pData = _realloc(sizeof(Data) * 2, pData);
Data_print(pData);
Data_print(pData + 1);
```

Let's inspect the new output:

```
Address:   0x55ed25f1a055

uint8_t:   255
uint16_t:  65535
uint32_t:  4294967295
uint64_t:  18446744073709551615
int8_t:    -128
int16_t:   -32768
int32_t:   -2147483648
int64_t:   -9223372036854775808
double:    1.7976931348623157e+308
float:     3.4028234664e+38
boolean:   true
string:    !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
```

There are a couple of aspects to examine. First, all the values are still present even though we
didn't assign anything. Second, the address of this chunk has changed. Since we extended our chunk
to accommodate another instance of such a structure, let's see its contents.

```
Address:   0x55ed25f1a095

uint8_t:   0
uint16_t:  0
uint32_t:  0
uint64_t:  0
int8_t:    0
int16_t:   0
int32_t:   0
int64_t:   0
double:    0.0000000000000000e+00
float:     0.0000000000e+00
boolean:   false
string:    (null)
```

If we don't encounter a segmentation fault, it indicates that everything is functioning correctly.
Now, let's reallocate the chunk again, but this time, let's shrink it back to its initial capacity.

```
Address:   0x55ed25f1a00b

uint8_t:   255
uint16_t:  65535
uint32_t:  4294967295
uint64_t:  18446744073709551615
int8_t:    -128
int16_t:   -32768
int32_t:   -2147483648
int64_t:   -9223372036854775808
double:    1.7976931348623157e+308
float:     3.4028234664e+38
boolean:   true
string:    !"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijklmnopqrstuvwxyz{|}~
```

Once again, if no segmentation fault is triggered, everything is in order. However, it's worth
noting that the address is precisely the same as in the initial example. This is because when we
reallocated our first chunk, we marked the region where it was previously stored as unused. When
allocating our last chunk, we discovered that this region matched the required size, so instead of
moving the program break, we simply marked that region as occupied and copied as much as we could
from the previous chunk into it.

## Performance

While this memory allocator does function, it is not particularly useful for anything beyond an
academic exercise. The implementation is simply too rudimentary to be effective. The major problem
lies in the allocation function. There are actually several issues with it.

First and foremost, it's too slow, or more precisely, it's not sufficiently fast. I mention _not
sufficiently fast_ because it runs in O(N) time, where N is the total number of allocated blocks.
While this is an optimal solution for many algorithms, it may not meet the speed requirements in our
scenario.

Another issue is the inefficient usage of unallocated memory. When the caller requests allocation
for another block, the allocation function places it in the first fitting unallocated chunk it
locates. This _first fitting chunk_ might be substantial enough to accommodate three times the
requested size, yet the excess memory remains unused, simply occupying space.
