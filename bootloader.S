// encoding: utf-8
// Copyright (c) 2026 Luan Pestana
// SPDX-License-Identifier: MIT
.code16
.section .text
.global _start                                                                    #include "kernel_size.inc"

// Os enderecos sao escritos como AA:BB, que resulta em (AA * 16 + BB), onde BB se chama offset

_start:
    // Impede interrupcoes
    cli

    // Zera o AX
    xor %ax, %ax

    // Zera o DS, os enderecos durante o bootloader sao calculados DS:offset, com o DS em zero eh possivel escolher os enderecos somente com os offsets
    mov %ax, %ds

    // Zera o ES, usado para acessar a memoria, eh zerado para nao permanecer algum valor herdado de firmware
    mov %ax, %es

    // Poe SS como zero e SP como 0x7C00, a cpu usa SS:SP para localizar a stack, dessa forma fica 0:7C00
    mov %ax, %ss
    mov $0x7C00, %sp

    mov $0x02, %ah // AH eh usado para a BIOS saber qual operacao eh a desejada. Ler setores
    mov $0x01, %al // Ler 1 setor
    mov $0x00, %ch // Cilindro 0                                                      mov $0x02, %cl // Setor 2 (contagem dos setores comeca em 1)
    mov $0x00, %dh // Head 0 (cabeca de leitura)
    // DL ja tem a unidade do disco no boot fornecido pela BIOS
    mov $0x8000, %bx // Poe os dados no offset 0x8000 da RAM

    int $0x13 // Chama BIOS para executar a tarefa especificada nos registradores

    jc disk_error // Se der erro, executa o disk_error


    // Saindo de Real-Mode 16bits para 64bits a fim de executar o kernel em x86_64 //

    // Habilita o A20, permitindo acessar enderecos acima de 1MiB
    in $0x92, %al // Le a porta I/O e poe o valor lido em AL
    or $0x02, %al // Aplica um OR (porta logica) bit a bit do numero 2 em 8 bits com o numero do registrador AL, como 2 em 8 bit eh 00000010, na pratica isso poe o segundo bit do registrador AL como 1
    out %al, $0x92 // Faz o oposto do in, poe o valor de AL na porta I/O numero 0x92
    // Assim o bit que foi ativado pela operacao or, foi o bit que habilita o A20

    // Fora do Real-Mode a cpu passa a usar descritores de segmentos armazenados na GDT
    lgdt gdt_descriptor // Carrega a GDT                                          
    // Mesmo processo feito para habilitar o A20, porem para habilitar o Protection Enable (modo de 32 bits)
    mov %cr0, %eax
    or $0x1, %eax
    mov %eax, %cr0

    // Long Jump, diferente do Jump, consegue pular para um segmento tambem (Jump pula apenas para um enderenco)
    ljmp $0x08, $protected_mode // Entra no Protected Mode


disk_error:
    // Aponta o registrador ES (extra segment) para 0xB800, que eh o endereco da memoria de texto VGA
    mov $0xB800, %ax
    mov %ax, %es

    // Escreve um texto na memoria de textoVGA                                    
    movb $'E', %es:0                                                                  movb $0x07, %es:1
                                                                                      movb $'r', %es:2
    movb $0x07, %es:3

    movb $'r', %es:4
    movb $0x07, %es:5

    movb $'o', %es:6
    movb $0x07, %es:7

    movb $'r', %es:8                                                                  movb $0x07, %es:9
                                                                                  hlt                                                                                   jmp disk_error
                                                                                  
// Instrucoes que seram executados durante o Protected Mode (modo 32 bits)
.code32                                                                           protected_mode:
    // Iniciando a paginacao //                                                   
    mov $0x1000, %edi // Endereco onde comeca a paginacao
    xor %eax, %eax // Zera EAX
    mov $4096 / 4, %ecx // Escreve 1024 em EAX
    rep stosl // Escreve o valor de EAX repetidamente na memoria

    mov $0x2000, %eax // Endereco da proxima tabela
    or $0x03, %eax // Os dois bits finais do 3 em 8 bit (00000011) significam Present (Valida) e Writable
    mov %eax, 0x1000 // Escreve o valor de EAX no byte 0x1000 da memoria, o endereco da segunda tabela no comeco da primeira tabela

    // Mesma ideia do anterior
    mov $0x3000, %eax
    or $0x03, %eax
    mov %eax, 0x2000

    // Habilita o setimo bit, Page Size, que diz que a entrada representa uma pagina de 2 MiB e nao eh para procurar abaixo da entrada                                  mov $0x00000083, %eax
    mov %eax, 0x3000
                                                                                      // Poe o endereco da primeira tabela no registrador CR3 (registrador que a cpu ja le a fim de achar o endereco da estrutura de paginacao)
    mov $0x1000, %eax
    mov %eax, %cr3

    // Fim da paginacao //



    // Habilita o bit 5 do registrador CR4, habilitando o PAE (Physical Address Extension)                                                                              mov %cr4, %eax
    or $0x20, %eax
    mov %eax, %cr4                                                                
    // Poe o endereco de um MSR (MSR sao registradores especiais, inacessiveis com MOV) no registrador ECX
    mov $0xC0000080, %ecx
    rdmsr // RDMSR le o MSR do endereco presente em ECX e poe o valor lido no EAX     or $0x100, %eax // Habilita o bit 8, responsavel pelo LME (Long Mode Enable, ativa o modo 64 bits)                                                                  wrmsr // Escreve o valor de volta no MSR

    // Habilita Paging, habilitando o bit 31
    mov %cr0, %eax
    or $0x80000000, %eax
    mov %eax, %cr0

    ljmp $0x18, $long_mode // Entra no Long Mode

// Instrucoes que seram executados durante o Long Mode (modo 64 bits)
.code64
long_mode:
    // Aponta para a memoria VGA (endereco da memoria VGA)
    mov $0xB8000, %rax

    // Escreve um texto na memoria de textoVGA
    movb $'P', 0(%rax)
    movb $0x07, 1(%rax)
                                                                                      movb $'i', 2(%rax)
    movb $0x07, 3(%rax)                                                           
    movb $'l', 4(%rax)                                                                movb $0x07, 5(%rax)

    movb $'o', 6(%rax)
    movb $0x07, 7(%rax)

    movb $'t', 8(%rax)
    movb $0x07, 9(%rax)

    movb $'O', 10(%rax)
    movb $0x07, 11(%rax)                                                          
    movb $'S', 12(%rax)
    movb $0x07, 13(%rax)                                                          
    movb $' ', 14(%rax)
    movb $0x07, 15(%rax)
                                                                                      // Copiar kernel
    mov $0x8000, %rsi // Origem, onde o kernel esta na RAM                            mov $0x100000, %rdi // Destino
    mov $KERNEL_SIZE, %rcx // Tamanho do kernel
    rep movsb

    // Entregar CPU ao kernel
    jmp 0x100010

    jmp hang

// Declarando cada GDT, com seus respectivos descritores de segmento, .quad manda o assembler reservar 8 bytes e por este valor
gdt_start:

gdt_null:
    .quad 0x0000000000000000

gdt_code32:
    .quad 0x00CF9A000000FFFF
                                                                                  gdt_data:
    .quad 0x00CF92000000FFFF                                                                                                                                        gdt_code64:
    .quad 0x00AF9A000000FFFF                                                      
gdt_end:

// Diz ao GDTR o endereco e o limite da GDT
gdt_descriptor:                                                                       .word gdt_end - gdt_start - 1
    .long gdt_start


// Loop onde a cpu fica inativa
hang:
    hlt
    jmp hang

// Isto diz que apartir daqui tudo ficara apartir do offset 510 (se nao ha 510 bytes, os bytes faltantes para totalizar 510 serao criados zerados)
.org 510
// Escreve a assinatira 0xAA55 (2 bytes), totalizando 512 bytes
.word 0xAA55