# Bootloader

A small experimental x86_64 bootloader written in Assembly, with a C kernel.

The boot process is divided into two stages.

## Features

- Two-stage bootloader
- Bootloader self-detection using a custom signature
- LBA discovery and disk sector loading
- Real Mode → Protected Mode → Long Mode
- GDT, PAE and Paging setup
- 64-bit kernel loading
- Automated build with "make"
- Automated QEMU testing with "make run"
- Disk image and ISO generation

## Boot Process

### Stage 1

The first stage runs in 16-bit Real Mode and is responsible for locating the bootloader on the disk.

It searches for the bootloader's custom signature, obtains its starting LBA, and uses it to locate and load the following bootloader sectors into RAM.

It then transfers execution to Stage 2.

### Stage 2

Stage 2 performs the CPU mode transition:

Real Mode
    ↓
Protected Mode
    ↓
PAE + Paging
    ↓
Long Mode
    ↓
64-bit Kernel

After entering 64-bit mode, control is transferred to the C kernel.

## Requirements

- "make"
- "clang"
- "ld.lld"
- "llvm-objcopy"
- "xorriso"
- "qemu-system-x86_64"
- Standard Unix utilities: "dd", "stat", "mkdir", "cp", "rm"

A Linux environment is recommended.

## Build

Build everything with:

```bash
make
```

This automatically compiles the kernel and both bootloader stages, creates the disk image, and generates the ISO.

## Run

Build and test the bootloader + kernel in QEMU:

```bash
make run
```

## Clean

Remove all generated files:

```bash
make clean
```

## Output

Build artifacts are generated in:

```
compiled/
├── MyOS.img
├── MyOS.iso
├── kernel.bin
├── bootloader1.bin
└── bootloader2.bin
```

## License

MIT