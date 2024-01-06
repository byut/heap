#
# common.s
# 
# Shared symbols and macros used by multiple 
# project files
# ...

.section .data

#
# System calls
# ...
.equ SYS_EXIT,  0x3C
.equ SYS_READ,  0x00
.equ SYS_WRITE, 0x01
.equ SYS_BRK,   0x0C

#
# File descriptors
# ...
.equ FD_STDIN, 0x00
.equ FD_STDOUT, 0x01
