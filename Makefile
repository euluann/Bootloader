CC = clang
LD = ld.lld
OBJCOPY = llvm-objcopy

BUILD = compiled

KERNEL_ELF = $(BUILD)/kernel.elf
KERNEL_BIN = $(BUILD)/kernel.bin
KERNEL_SIZE = $(BUILD)/kernel_size.inc

BOOTLOADER_OBJ = $(BUILD)/bootloader.o
BOOTLOADER_BIN = $(BUILD)/bootloader.bin

IMG = $(BUILD)/MyOS.img
ISO = $(BUILD)/MyOS.iso

CFLAGS = --target=x86_64-unknown-none \
         -ffreestanding \
         -fno-stack-protector \
         -mno-red-zone

all: $(ISO)

$(BUILD):
	mkdir -p $(BUILD)

$(BUILD)/boot.o: boot.S | $(BUILD)
	$(CC) --target=x86_64-unknown-none -c $< -o $@

$(BUILD)/kernel.o: kernel.c | $(BUILD)
	$(CC) $(CFLAGS) -c $< -o $@

$(KERNEL_ELF): $(BUILD)/boot.o $(BUILD)/kernel.o linker.ld
	$(LD) -T linker.ld -o $@ $(BUILD)/boot.o $(BUILD)/kernel.o

$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary $< $@

$(KERNEL_SIZE): $(KERNEL_BIN)
	echo ".equ KERNEL_SIZE, $$(stat -c%s $(KERNEL_BIN))" > $@

$(BOOTLOADER_OBJ): bootloader.S $(KERNEL_SIZE) | $(BUILD)
	$(CC) --target=i386-unknown-none -m16 -c $< -o $@

$(BOOTLOADER_BIN): $(BOOTLOADER_OBJ)
	$(LD) -m elf_i386 \
		--image-base 0x7C00 \
		--oformat binary \
		-Ttext 0x7C00 \
		-o $@ $<

$(IMG): $(BOOTLOADER_BIN) $(KERNEL_BIN)
	@echo "Criando imagem de disco"
	dd if=/dev/zero of=$@ bs=512 count=2880

	@echo "Gravando bootloader no primeiro setor"
	dd if=$(BOOTLOADER_BIN) of=$@ conv=notrunc

	@echo "Gravando kernel no segundo setor"
	dd if=$(KERNEL_BIN) of=$@ bs=512 seek=1 conv=notrunc

	@echo "Imagem gerada em $@"

$(ISO): $(IMG)
	@echo "Copiando Imagem"
	rm -rf $(BUILD)/iso
	mkdir -p $(BUILD)/iso
	cp $(IMG) $(BUILD)/iso/MyOS.img

	@echo "Gerando ISO"
	xorriso -as mkisofs \
		-o $@ \
		-b MyOS.img \
		-c boot.cat \
		-boot-load-size 2880 \
		$(BUILD)/iso

	rm -rf $(BUILD)/iso

	@echo
	@echo "ISO gerada em $@"
	@echo
	@echo "Para testar use:"
	@echo "  qemu-system-x86_64 -cdrom $@ -display curses"

run: $(ISO)
	qemu-system-x86_64 -cdrom $(ISO) -display curses

clean:
	rm -rf $(BUILD) $(KERNEL_SIZE)

.PHONY: all run clean