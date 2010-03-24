        .org     $800

        .export  bufp
        bufp    =     $3c

initsscentry:
        jmp     INITSSC
resetsscentry:
        jmp     RESETSSC
sscgetentry:
        jmp     SSCGET
read256entry:
        ldx     $00
        jmp     read256


        .include        "cereal.s"

