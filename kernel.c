// encoding: utf-8
// Copyright (c) 2026 Luan Pestana
// SPDX-License-Identifier: MIT

// ATENCAO //
// O kernel.c DEVE comecar pela funcao main, ou o bootloader ira falhar

 // Pre declara funcoes e variaveis declaradas apos o main, ou nao sera possivel usa-las no main, mas NAO crie uma funcao antes do main
volatile char *video = (volatile char *)0xB8000;
int cursor = 0;
void print(const char *str);
void clear(void);

void kernel_main(void){
    
    //print("Este texto esta sendo imprimido pelo kernel em x86_64");
    
    clear();
    print("Linha 1\n");
    print("Linha 2\n");
    print("Este texto esta sendo imprimido pelo kernel em x86_64");

    for (;;){
        __asm__ volatile ("hlt");
    }
}

void print(const char *str){
    while (*str != '\0') {
        if (*str == '\n') {
            cursor += 80 - (cursor % 80);
        } else {
            video[cursor * 2] = *str;
            video[cursor * 2 +1] = 0x07;
            cursor++;
        }
        str++;
    }
}

void clear(void){
    for (int i = 0; i < 80 * 25; i++){
        video[i * 2] = ' ';
        video[i * 2 + 1] = 0x07;
    }
}

int strlen(const char *str){
    int i = 0;

    while (str[i] != '\0') {
        i++;
    }

    return i;
}


