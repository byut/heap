#
# heap.s
#
# Source code related to memory operations 
# such as allocation, deallocation and reallocation.
# ...

.include "common.s"

.section .data

.equ HEADER_SIZE, 10

#
# Information regarding the heap state
# ...
heap_start: .quad 0
heap_end:   .quad 0

.section .text
.global _hinit
.global _malloc
.global _realloc
.global _free


#
# Initializes the heap memory to perform 
# multiple allocations and deallocations of data fragments
#
# Parameters:
#   void
#
# Variables:
#   void
#
# Returns:
#   %rax - function completion status (0 - success, 1 - failure)
_hinit:
    cmpq $0, heap_start(%rip)
    movq $1, %rax
    jne _hinit_end

    movq $SYS_BRK, %rax
    movq $0, %rdi
    syscall

    incq %rax
    movq %rax, heap_start(%rip)
    movq %rax, heap_end(%rip)

    movq $0, %rax   
_hinit_end:
    ret


# 
# Allocates an uninitialized memory chunk on the heap.
#
# If allocation succeeds, returns a pointer that is suitably 
# aligned for any object type.
# 
# Parameters:
#   %rdi - number of bytes to allocate
#
# Variables:
#   %rsi - pointer to the current position on the heap
#   %rdx - size of the memory chunk being examined
#
# Returns:
#   %rax - pointer to the allocated chunk, or a null-pointer (0) 
#          if allocation failed
_malloc:
    pushq %rbp
    movq %rsp, %rbp

    movq heap_start(%rip), %rsi

_malloc_start:
    cmpq heap_end(%rip), %rsi
    je _malloc_more

    movq 2(%rsi), %rdx
    cmpw $0x00, (%rsi)
    je _malloc_next

    cmpq %rdx, %rdi
    jle _malloc_here

_malloc_next:
    addq $HEADER_SIZE, %rsi
    addq %rdx, %rsi
    jmp _malloc_start

_malloc_here:
    movw $0x00, (%rsi)
    addq $HEADER_SIZE, %rsi
    movq %rsi, %rax
    jmp _malloc_end

_malloc_more:
    addq $HEADER_SIZE, heap_end(%rip)
    addq %rdi, heap_end(%rip)
    
    pushq %rdi
    pushq %rsi

    movq $SYS_BRK, %rax
    movq heap_end(%rip), %rdi
    syscall

    cmpq $0, %rax
    je _malloc_end

    popq %rsi
    popq %rdi

    movw $0x00, (%rsi)
    movq %rdi, 2(%rsi)
    addq $HEADER_SIZE, %rsi
    movq %rsi, %rax

_malloc_end:
    movq %rbp, %rsp
    popq %rbp
    ret

#
# Expands or contracts the given memory chunk.
#
# Parameters:
#   %rdi - size of the new memory chunk
#   %rsi - pointer to the memory chunk that must be reallocated
#
# Variables:
#   %rdx - size of the memory chunk that must be reallocated
#
# Returns:
#   %rax - pointer to the reallocated memory chunk
_realloc:
    pushq %rdi
    pushq %rsi
    call _malloc
    popq %rsi
    popq %rdi

    cmpq $0, %rsi
    je _realloc_end

    movq -8(%rsi), %rdx
    cmpq %rdx, %rdi
    jge _realloc_memcpy
    movq %rdi, %rdx

_realloc_memcpy:
    pushq %rax
    pushq %rsi
    movq %rax, %rdi
    call _memcpy

    popq %rdi
    call _free
    popq %rax

_realloc_end:
    ret


#
# Frees the memory space pointed to by the pointer
# that must have been returned by a previous call to _malloc
#
# Parameters:
#   %rdi - pointer to the memory chunk that should be deallocated
#
# Variables:
#   void
#
# Returns:
#   void
_free:
    subq $HEADER_SIZE, %rdi
    movw $0x01, (%rdi)
    ret

