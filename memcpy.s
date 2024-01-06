.section .text
.global _memcpy

#
# Parameters:
#   %rdi - Destination pointer
#   %rsi - Source pointer
#   %rdx - Number of bytes to copy
#
# Variables:
#   %r10b - Storage for the transfer byte
#
# Returns 
#   void
_memcpy:
    cmpq $0, %rdx
    je _memcpy_end
    movb (%rsi), %r10b
    movb %r10b, (%rdi)
    incq %rsi
    incq %rdi
    decq %rdx
    jmp _memcpy
_memcpy_end:
    ret
