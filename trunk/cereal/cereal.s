        kbd     = $c000                     ;kbd latch, >127 means lo 7  bits are key pressed
        kbdclr  = $c010
        cout1   =       $fdf0
        prerr  = $ff2d

sscslot         =     2
ssc_data        =     $c088 + (sscslot << 4)
ssc_status      =     $c089 + (sscslot << 4)
ssc_cmd         =     $c08a + (sscslot << 4)
ssc_ctrl        =     $c08b + (sscslot << 4)

PSPEED          =     6
CHR_ESC         =     27  ;esc with hi-bit set to detect kbd

timeout         =     255       ;timeout (255 = about 3 seconds)

cksum           =     $08
counter         =     cksum+1

write256:

;; ------------------------------------------------------
;; read 256 bytes w/16-bit checksum, into page buffer.
;; entry: x = page number ($00-$ff) to use as buf
;; exit: carry clear = OK; carry set = error; all regs scrambled

read256:
        ;; save contents of cksum & counter regs
        lda     cksum
        pha
        lda     counter
        pha
        stx     bufp+1
        ;; zero cksum
        ldy     #0
        sty     cksum
rdloop: jsr     SSCGET
        bcs     read256_errexit    ;error
        sta     (bufp),y
        eor     cksum
        sta     cksum
        iny
        bne     rdloop
        ;; receive checksum
        jsr     SSCGET
        bcs     read256_exit
        cmp     cksum
        bne     read256_errexit
        clc
        bcc     read256_exit
read256_errexit:
        sec
        sty     $2ff
read256_exit:
        pla
        sta     counter
        pla
        sta     cksum
        ;; exit thru RESETSSC to clear input reg.
        jmp     RESETSSC

;;  This code is based on code from ssc.asm in ADTPro,
;;         (c) David Schmidt, GNU GPL, adtpro.sourceforge.net

;---------------------------------------------------------
; INITSSC - Initialize the SSC to slot number #sscslot
;;---------------------------------------------------------
INITSSC:
        lda #$0B        ; COMMAND: NO PARITY, RTS ON,
        sta ssc_status  ; all reset
        sta ssc_cmd     ; DTR ON, NO INTERRUPTS
        ldy #PSPEED     ; CONTROL: 8 DATA BITS, 1 STOP
        lda BPSCTRL,Y   ; BIT, BAUD RATE DEPENDS ON
        sta ssc_ctrl    ; PSPEED
        ;; fall through to RESETSSC
;---------------------------------------------------------
; RESETSSC - Clean up SSC
;---------------------------------------------------------
RESETSSC:
        bit ssc_data    ; CLEAR SSC INPUT REGISTER
        rts
        rts

;---------------------------------------------------------
; SSCPUT - Send accumulator out the serial line
;;; On exit: X=scrambled, A=char sent, Y=intact
;;; Carry set = error, clear = OK
;---------------------------------------------------------
SSCPUT:
        pha             ; Push A onto the stack
        lda #timeout
        tax
        sta counter
PUTC1:  lda $C000
        cmp #(CHR_ESC | 128)    ; Escape = abort
        beq PABORT
        lda ssc_status  ; Check status bits
        and #$70        ;mask all except DSR, DCD, Tx reg
        cmp #$10        ; DSR true && DCD true && Tx reg empty?
        beq put1
        dex
        bne PUTC1
        dec counter+1
        bne PUTC1
PABORT: pla
        sec
        bit ssc_data
        rts
put1:   pla
        sta ssc_data    ; Put character
        clc
        rts

;---------------------------------------------------------
; SSCGET - Get a character from Super Serial Card
;;;  X=scrambled, Y=intact, A=char received
;;;  Carry set = error, clear = OK
;---------------------------------------------------------
SSCGET:
        lda #timeout
        tax
        sta counter
GET1:
        lda kbd
        cmp #(CHR_ESC | 128)    ; Escape = abort
        beq PABORT
        lda ssc_status  ; Check status bits
        and #$68        ; mask all except DSR, DCD, Rx reg
        cmp #$8         ; DSR true && DCD true && Rx reg full?
        beq gotit
        dex
        bne GET1
        dec counter
        bne GET1
        beq PABORT
gotit:
        lda ssc_data    ; Get character
        clc
        rts


BPSCTRL:        .byte $13,$16,$18,$1A      ; 110, 300, 1200, 2400
                .byte $1E,$1F,$10   ; 9600, 19200, 115k


