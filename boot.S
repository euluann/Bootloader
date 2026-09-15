
// encoding: utf-8
// Copyright (c) 2026 Luan Pestana
// SPDX-License-Identifier: MIT
.global _start
.extern kernel_main

.section .text

_start:
    mov $stack_top, %rsp                                                              call kernel_main

.hang:                                                                                hlt
    jmp .hang

.section .bss                                                                     .align 16
                                                                                  stack_bottom:
    .skip 16384

stack_top: