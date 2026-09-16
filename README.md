# Bootloader

A small experimental x86_64 bootloader written in Assembly.

It starts in 16-bit Real Mode, switches to 32-bit Protected Mode, enables paging and Long Mode, enters 64-bit mode, and transfers control to a C kernel.

Features

- Real Mode → Protected Mode → Long Mode
- A20 activation
- GDT setup
- Paging and PAE
- 64-bit kernel loading

License

MIT

Compile:
```Make```