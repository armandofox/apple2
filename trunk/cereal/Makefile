
BLANKDISK = ./blank_dos33.dsk
ADDR  =  300

CEREAL3.dsk: a.out
	cp $(BLANKDISK) $@
	a2in b.$(ADDR) $@ $(basename $@) < $^

%.o: %.s
	ca65 $<

a.out: prodos.o 
	ld65 -t none -o $@ -S $(ADDR) -m $@.map $^

clean:
	-rm CEREAL3.dsk *.o

