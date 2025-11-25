NASM = nasm
LD   = ld

NASMFLAGS = -f elf32 -g -F dwarf
LDFLAGS   = -m elf_i386

ASM_SRCS = main.asm unixhelp.asm urlparse.asm confpars.asm
OBJ_FILES = $(ASM_SRCS:.asm=.o)

TARGET = prog

all: $(TARGET)

$(TARGET): $(OBJ_FILES)
	$(LD) $(LDFLAGS) -o $@ $^

%.o: %.asm
	$(NASM) $(NASMFLAGS) -o $@ $<

clean:
	rm -f $(OBJ_FILES) $(TARGET)

.PHONY: all clean
