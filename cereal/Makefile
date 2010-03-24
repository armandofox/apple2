
BLANKDISK = ./blank_dos33.dsk
ADDR  =  300

CEREAL3.dsk: prodos.bin
	cp $(BLANKDISK) $@
	a2in b.$(ADDR) $@ $(basename $@) < $^

CEREALTEST.dsk: cerealtest.bin
	cp $(BLANKDISK) $@
	a2in b.$(ADDR) $@ $(basename $@) < $^
	a2in t $@ CEREALTEST.EXEC < cerealtest.txt

%.o: %.s
	ca65 $<

%.bin: %.o 
	ld65 -t none -o $@ -S $(ADDR) -m $@.map $^

clean:
	-rm CEREAL3.dsk *.o

