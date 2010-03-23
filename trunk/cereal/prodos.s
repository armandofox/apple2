        prodos_cmd      = $42
        prodos_unitnum  = $43
        prodos_bufp     = $44
        prodos_blocknum = $46

        prodos_err_io   = $27
        prodos_err_nodev = $28
        prodos_err_write_prot = $2B

        .export bufp
        bufp = prodos_bufp

        .org    $300

prodos_entry:
        ldx     prodos_cmd
        ;; fake an RTS to correct handler
        lda     #>prodos_status
        pha
        lda     cmdtbl_lo,x
        pha
        rts
cmdtbl_lo:
        .byte   < (prodos_status-1)
        .byte   < (prodos_read-1)
        .byte   < (prodos_write-1)
        .byte   < (prodos_format-1)

.macro  try_read arg
        jsr     SSCGET
        bcs     proto_err
        .if (.match (.left (1, arg), #))
          cmp #(.right (.tcount(arg)-1, arg))
        .else
          cmp arg
        .endif
        bne     proto_err
.endmacro

.macro  try_write arg
        .if (.match (.left (1, arg), #))
          lda #(.right (.tcount(arg)-1, arg))
        .else
          lda arg
        .endif
        jsr     SSCPUT
        bcs     proto_err
.endmacro


prodos_status:
        clc
        rts

;;; --------------------------------------------------
;;; ProDOS "read" driver call
;;; enter: $43=unit num, $44-$45=bufp, $46-$47=block #
;;; action:
;;;    send 'Rnn' where nn are 2-byte block ID (hi,lo)
;;;    wait for response '<nn' [or error]
;;;    wait for 256-byte block (first half)
;;;    send 'r' (note lowercase)
;;;    wait for '>'
;;;    wait for 256-byte block (second half)
;;;    send 'Ann' (for "Ack")
;;; exit:
;;;    carry set=error, clear=ok
;;;    all regs scrambled

prodos_read:
        try_write #'R'
        try_write prodos_blocknum
        try_write prodos_blocknum+1
        ;; wait for ack '<nn'
        try_read #'<'
        try_read prodos_blocknum
        try_read prodos_blocknum+1
        ;; wait for first half block data
        jsr     read256
        bcs     proto_err
        ;;  inc buf ptr for next half
        inc     bufp+1
        ;; send 'r', wait for '>'
        try_write #'r'
        try_read #'>'
        ;; wait for 2nd half block data
        jsr     read256
        bcs     proto_err

proto_err:
        lda     #prodos_err_io
        sec
        rts

prodos_write:
        lda     #prodos_err_write_prot
        sec
        rts

prodos_format:
        jmp     proto_err

.include "cereal.s"

