ifeq ($(CHERI),1)
TOOLCHAIN:=LLVM
endif

CCDIR   ?= /Users/jonathanwoodruff/cheri/zcheri/output/sdk/bin/
ifeq ($(TOOLCHAIN),LLVM)
CC      := $(CCDIR)/clang
LD      := $(CCDIR)/ld.lld
OBJDUMP := $(CCDIR)/llvm-objdump
OBJCOPY := $(CCDIR)/llvm-objcopy

RISCV_FLAGS += -mcmodel=medium -mno-relax
LIBS := 
else # GCC
CC      := riscv64-unknown-elf-gcc
LD      := riscv64-unknown-elf-ld
OBJDUMP := riscv64-unknown-elf-objdump
OBJCOPY := riscv64-unknown-elf-objcopy
RISCV_FLAGS += -mcmodel=medany
LIBS := -lgcc
endif

# Make sure user explicitly defines the target GFE platform.
ifeq ($(TOOLCHAIN),LLVM)
ifeq ($(CHERI),1)
  RISCV_FLAGS += -target riscv64-unknown-elf -march=rv64imafdzcherihybrid_zba_zbb_zbc_zbs_zicond1p0 -mabi=l64pc128d -menable-experimental-extensions
else
  RISCV_FLAGS += -target riscv64-unknown-elf -march=rv64imafdc_zba_zbb_zbc_zbs_zicond1p0 -mabi=lp64d -menable-experimental-extensions
endif
else
  RISCV_FLAGS += -march=rv64imafdc_zba_zbb_zbc_zbs_zicond -mabi=lp64d
endif

# 25 MHz clock
CLOCKS_PER_SEC := 25000000

# Define sources and compilation outputs.
COMMON_DIR := ../Toooba-mibench2
LINKER_SCRIPT := $(COMMON_DIR)/test.ld
COMMON_ASM_SRCS := \
	$(COMMON_DIR)/crt.S
COMMON_C_SRCS := \
	$(COMMON_DIR)/syscalls.c \
	$(COMMON_DIR)/util.c \
	$(COMMON_DIR)/cvt.c
COMMON_OBJS := \
	$(patsubst %.c,%.o,$(notdir $(COMMON_C_SRCS))) \
	$(patsubst %.S,%.o,$(notdir $(COMMON_ASM_SRCS)))
OBJS := $(COMMON_OBJS) $(OBJS)

# Define compile and load/link flags.
CFLAGS := \
	$(RISCV_FLAGS) \
	-DBARE_METAL \
	-DCLOCKS_PER_SEC=$(CLOCKS_PER_SEC) \
	-DHAS_FLOAT=1 \
	-DRUNS=$(RUNS) \
	-O3 \
	-Wall \
	-static \
	-std=gnu99 \
	-ffast-math \
	-fno-common \
	-fno-builtin \
	-fno-pic \
	-I$(COMMON_DIR)
ASFLAGS := $(CFLAGS)
LDFLAGS := \
	-v \
	-static \
	-nostdlib \
	-nodefaultlibs \
	-nostartfiles \
	$(LIBS) \
	-T $(LINKER_SCRIPT)

DHRY-LFLAGS = $(LDFLAGS)

DHRY-CFLAGS := $(CFLAGS)
#DHRY-CFLAGS := -O3 -DTIME -DNOENUM -Wno-implicit -save-temps
#DHRY-CFLAGS += -fno-builtin-printf -fno-common -falign-functions=4

#Uncomment below for FPGA run, default DHRY_ITERS is 2000 for RTL
#DHRY-CFLAGS += -DDHRY_ITERS=20000000

SRC = dhry_1.c dhry_2.c strcmp.S $(COMMON_C_SRCS) $(COMMON_ASM_SRCS)
HDR = dhry.h

override CFLAGS = $(DHRY-CFLAGS) $(XCFLAGS) 
dhrystone: $(SRC) $(HDR) $(COMMON_C_SRCS) $(COMMON_ASM_SRCS)
	$(CC) $(CFLAGS) $(SRC) $(LDFLAGS) $(LOADLIBES) $(LDLIBS) -o $@

clean:
	rm -f *.i *.s *.o dhrystone dhrystone.hex

