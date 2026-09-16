ENTRY(_start)

SECTIONS
{
    . = 1M;

    .text : ALIGN(16)
    {
        KEEP(*(.text.boot))
        *(.text)
        *(.text.*)
    }

    .rodata : ALIGN(16)
    {
        *(.rodata)
        *(.rodata.*)
    }

    .data : ALIGN(16)
    {
        *(.data)
        *(.data.*)
    }

    .bss : ALIGN(16)
    {
        *(COMMON)
        *(.bss)
        *(.bss.*)
    }
}
