CC = clang
LD = ld.lld
OBJCOPY = llvm-objcopy

BUILD = compiled

KERNEL_ELF  = $(BUILD)/kernel.elf
KERNEL_BIN  = $(BUILD)/kernel.bin
KERNEL_SIZE_INC = $(BUILD)/kernel_size.inc
IMAGE_VARS_MK = $(BUILD)/image_vars.mk

BOOTLOADER1_OBJ = $(BUILD)/bootloader1.o
BOOTLOADER1_BIN = $(BUILD)/bootloader1.bin
BOOTLOADER2_OBJ = $(BUILD)/bootloader2.o
BOOTLOADER2_BIN = $(BUILD)/bootloader2.bin



IMG_SIZE_MB = 64
SECTOR_SIZE = 512

IMG_SECTORS = $$(($(IMG_SIZE_MB) * 1024 * 1024 / 512))

IMG = $(BUILD)/MyOS.img


CFLAGS = --target=x86_64-unknown-none \
         -ffreestanding \
         -fno-stack-protector \
         -mno-red-zone


-include $(IMAGE_VARS_MK)

.PHONY: all run clean

all: $(IMG)


# ============================================================
# DIRETÓRIO
# ============================================================

$(BUILD):
	mkdir -p $(BUILD)


# ============================================================
# KERNEL
# ============================================================

$(BUILD)/boot.o: boot.s | $(BUILD)
	$(CC) --target=x86_64-unknown-none \
		-c boot.s \
		-o $@


$(BUILD)/kernel.o: kernel.c | $(BUILD)
	$(CC) $(CFLAGS) \
		-c kernel.c \
		-o $@


$(KERNEL_ELF): $(BUILD)/boot.o $(BUILD)/kernel.o linker.ld
	$(LD) -T linker.ld \
		-o $@ \
		$(BUILD)/boot.o \
		$(BUILD)/kernel.o


$(KERNEL_BIN): $(KERNEL_ELF)
	$(OBJCOPY) -O binary \
		$(KERNEL_ELF) \
		$(KERNEL_BIN)


$(KERNEL_SIZE_INC): $(KERNEL_BIN)
	@SIZE=$$(stat -c%s $(KERNEL_BIN)); \
	echo "#define KERNEL_SIZE $$SIZE" > $@; \
	echo "Kernel: $$SIZE bytes"


$(EFI_KERNEL_SIZE_H): $(KERNEL_BIN)
	@echo "#define KERNEL_SIZE_B $$(stat -c%s $(KERNEL_BIN))" > $@
	@echo "#define KERNEL_SECTORS $$(($$(stat -c%s $(KERNEL_BIN)) + 511) / 512)" >> $@

# ============================================================
# VARIÁVEIS DA IMAGEM
# ============================================================

$(IMAGE_VARS_MK): $(KERNEL_BIN) | $(BUILD)
	@SIZE=$$(stat -c%s $(KERNEL_BIN)); \
	SECTORS=$$(( (SIZE + 511) / 512 )); \
	START=$$(( SECTORS + 3 )); \
	FS_SIZE=$$(( $(IMG_SECTORS) - START )); \
	echo "KERNEL_SIZE_B := $$SIZE" > $@; \
	echo "KERNEL_SECTORS := $$SECTORS" >> $@; \
	echo "FS_START := $$START" >> $@; \
	echo "FS_SECTORS := $$FS_SIZE" >> $@; \
	echo "Kernel: $$SIZE bytes"; \
	echo "Kernel sectors: $$SECTORS"; \
	echo "Filesystem start: LBA $$START"; \
	echo "Filesystem sectors: $$FS_SIZE"



$(BOOTLOADER1_OBJ): bootloader1.s $(KERNEL_SIZE_INC) | $(BUILD)
	$(CC) \
		--target=i386-unknown-none \
		-m16 \
		-x assembler-with-cpp \
		-I$(BUILD) \
		-c bootloader1.s \
		-o $@


$(BOOTLOADER1_BIN): $(BOOTLOADER1_OBJ)
	$(LD) \
		-m elf_i386 \
		--image-base 0x7C00 \
		--oformat binary \
		-Ttext 0x7C00 \
		-o $@ \
		$(BOOTLOADER1_OBJ)


# ============================================================
# BOOTLOADER 2
# ============================================================

$(BOOTLOADER2_OBJ): bootloader2.s $(KERNEL_SIZE_INC) | $(BUILD)
	$(CC) \
		--target=i386-unknown-none \
		-m16 \
		-x assembler-with-cpp \
		-I$(BUILD) \
		-c bootloader2.s \
		-o $@


$(BOOTLOADER2_BIN): $(BOOTLOADER2_OBJ)
	$(LD) \
		-m elf_i386 \
		--image-base 0x8000 \
		--oformat binary \
		-Ttext 0x8000 \
		-o $@ \
		$(BOOTLOADER2_OBJ)

# ============================================================
# DISK IMAGE
# ============================================================


$(IMG): \
	$(BOOTLOADER1_BIN) \
	$(BOOTLOADER2_BIN) \
	$(KERNEL_BIN) \
	$(IMAGE_VARS_MK)

	@echo "==> Criando imagem BIOS..."
	dd if=/dev/zero \
		of=$(IMG) \
		bs=1M \
		count=$(IMG_SIZE_MB) \
		status=progress

	@echo "==> Criando tabela MBR..."
	printf 'label: dos\nunit: sectors\n\n1 : start=$(FS_START), size=$(FS_SECTORS), type=c, bootable\n' \
		| sfdisk $(IMG)

	@echo "==> Gravando Stage 1..."
	dd if=$(BOOTLOADER1_BIN) \
		of=$(IMG) \
		bs=1 \
		count=446 \
		conv=notrunc \
		status=none

	printf '\x55\xAA' \
		| dd of=$(IMG) \
			bs=1 \
			seek=510 \
			conv=notrunc \
			status=none

	@echo "==> Gravando Stage 2..."
	dd if=$(BOOTLOADER2_BIN) \
		of=$(IMG) \
		bs=512 \
		seek=1 \
		conv=notrunc

	@echo "==> Gravando kernel..."
	dd if=$(KERNEL_BIN) \
		of=$(IMG) \
		bs=512 \
		seek=2 \
		conv=notrunc

	@echo "==> Criando FAT32..."
	mkfs.fat \
		-F 32 \
		--offset=$(FS_START) \
		$(IMG)

	@echo ""
	@echo "========================================"
	@echo " BIOS IMAGE CRIADA"
	@echo "========================================"
	@echo "Kernel:       $(KERNEL_SIZE_B) bytes"
	@echo "Kernel:       $(KERNEL_SECTORS) setores"
	@echo "FAT32 começa: LBA $(FS_START)"
	@echo "FAT32 setores: $(FS_SECTORS)"
	@echo "========================================"
	@echo "Use:"
	@echo "	qemu-system-x86_64 -drive file=compiled/MyOS.img -display curses -monitor none -serial none"
	@echo "Ou:"
	@echo "	make run"
	@echo "=================================="


# ============================================================
# RUN
# ============================================================

run: $(IMG)
	qemu-system-x86_64 -drive file=$(IMG) -display curses -monitor none -serial none

# ============================================================
# CLEAN
# ============================================================

clean:
	rm -rf $(BUILD)
