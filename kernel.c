// encoding: utf-8
// Copyright (c) 2026 Luan Pestana
// SPDX-License-Identifier: MIT

// ATENCAO //
// O kernel.c DEVE comecar pela funcao main, ou o bootloader ira falhar

void kernel_main(void){
    volatile char *video = (volatile char *)0xB8000;

    int strlen(const char *str); // Pre declara uma funcao declarada apos o main, ou nao sera possivel usala no main

    char *text = "Bootloader funcionando, este texto esta sendo imprimido pelo kernel em x86_64";

    int text_size = strlen(text);

    int i2 = 0;
    for (int i = 0; i < text_size; i++){
        video[i2] = text[i];
        video[i2+1] = 0x07;
        i2 += 2;
    }

    for (;;){
        __asm__ volatile ("hlt");
    }
}

int strlen(const char *str)
{
    int i = 0;

    while (str[i] != '\0') {
        i++;
    }

    return i;
}
