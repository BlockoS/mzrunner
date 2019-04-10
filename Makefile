CC   = gcc
CXX  = g++
RASM = rasm
ECHO = echo

CCFLAGS = -W -Wall
RASMFLAGS =

ALL = bin2m12 cge2bin gfx main.bin main.m12 main-emu.bin main-emu.m12

all: $(ALL)

bin2m12: tools/bin2m12.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^

cge2bin: tools/cge2bin.c
	@$(ECHO) "CC	$@"
	@$(CC) $(CCFLAGS) -o $@ $^ -lm

gfx:
	@$(ECHO) "GEN	GFX"
	@./cge2bin -x 0 -y 0 -w 40 -h 25 ./data/playfield.txt ./data/playfield.bin
	@./cge2bin -x 0 -y 0 -w 40 -h 25 ./data/title.txt ./data/title.bin

main.bin: gfx
	@$(ECHO) "RASM	$@"
	@$(RASM) $(RASMFLAGS) main.asm -o $(basename $@)

%.m12: %.bin bin2m12
	@$(ECHO) "M12	$@"
	@./bin2m12 $< $@ AC2019

main-emu.bin: main.bin
	@$(ECHO) "RASM	$@"
	@$(RASM) -DEMU=1 $(RASMFLAGS) main.asm -o $(basename $@)

clean:
	@$(ECHO) "CLEANING UP..."
	@rm -f bin2m12 cge2bin main.bin main_emu.bin main.m12 main.m12
	@find $(BUILD_DIR) -name "*.o" -exec rm -f {} \;
