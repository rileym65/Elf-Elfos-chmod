; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

include    bios.inc
include    kernel.inc

           org     8000h
           lbr     0ff00h
           db      'chmod',0
           dw      9000h
           dw      endrom+7000h
           dw      2000h
           dw      endrom-2000h
           dw      2000h
           db      0
 
           org     2000h
           br      start

include    date.inc
include    build.inc
           db      'Written by Michael H. Riley',0

; Rb - modifications
;      0 - +e
;      1 - -e

start:     mov     rb,0                ; clear modifications
stloop:    lda     ra                  ; move past any spaces
           smi     ' '
           lbz     stloop
           dec     ra                  ; move back to non-space character
swloop:    lda     ra                  ; get byte from command line
           smi     '+'                 ; look for plus symbol
           lbz     swplus              ; jump if so
           smi     2                   ; check for minus symbol
           lbnz    swdone              ; otherwise done with switches
swminus:   lda     ra                  ; get switch name
           smi     'x'                 ; check for e
           lbnz    swerr               ; jump if not
           glo     rb                  ; set -e modification
           ori     2
           plo     rb                  ; and put it back
           lbr     stloop              ; loop back for more
swplus:    lda     ra                  ; get switch name
           smi     'x'                 ; check for e
           lbnz    swerr               ; jump if not
           glo     rb                  ; set +e modification
           ori     1
           plo     rb                  ; put it back
           lbr     stloop              ; loop back for more
swerr:     sep     scall               ; display error
           dw      f_inmsg
           db      'Invalid switch specified',10,13,0
           lbr     o_wrmboot           ; and return to Elf/OS
swdone:    mov     rf,flags            ; where to store flags
           glo     rb                  ; get operations
           str     rf                  ; and save them
           dec     ra                  ; move back to previous byte
           ghi     ra                  ; copy argument address to rf
           phi     rf
           glo     ra
           plo     rf
loop1:     lda     rf                  ; look for first less <= space
           smi     33
           lbdf    loop1
           dec     rf                  ; backup to char
           ldi     0                   ; need proper termination
           str     rf
           ghi     ra                  ; back to beginning of name
           phi     rf
           glo     ra
           plo     rf
           ldn     rf                  ; get byte from argument
           lbnz    good                ; jump if filename given
           sep     scall               ; otherwise display usage message
           dw      f_inmsg
           db      'Usage: type filename',10,13,0
           sep     sret                ; and return to os
good:      ldi     high fildes         ; get file descriptor
           phi     rd
           ldi     low fildes
           plo     rd
           ldi     0                   ; flags for open
           plo     r7
           sep     scall               ; attempt to open file
           dw      o_open
           lbnf    mainlp              ; jump if file was opened
           ldi     high errmsg         ; get error message
           phi     rf
           ldi     low errmsg
           plo     rf
           sep     scall               ; display it
           dw      o_msg
           lbr     o_wrmboot           ; and return to os
mainlp:    mov     rf,sector           ; point to dir sector in FILDES
           inc     rf
           lda     rf                  ; retrieve sector
           plo     r8
           lda     rf
           phi     r7
           lda     rf
           plo     r7
           ldi     0e0h                ; lba mode
           phi     r8
           mov     rf,secbuf           ; where to load sector
           sep     scall               ; call bios to read the sector
           dw      f_ideread
           mov     rf,dirent           ; need dirent offset
           lda     rf
           phi     r7
           lda     rf
           adi     6                   ; point to flags byte
           plo     r7
           ghi     r7
           adci    0                   ; propagate carry
           phi     r7                  ; r7 now points to flags
           glo     r7                  ; now point to correct spot in sector buffer
           adi     secbuf.0
           plo     r7
           ghi     r7
           adci    secbuf.1
           phi     r7
           mov     rf,flags            ; recover operations
           ldn     rf
           plo     rb
           glo     rb                  ; get operations
           ani     1                   ; see if +x
           lbz     notx                ; jump if not
           ldn     r7                  ; get flags
           ori     2                   ; turn on executable flag
           str     r7                  ; and put it back
notx:      glo     rb                  ; get operations
           ani     2                   ; see if -x
           lbz     notmx               ; jump if not
           ldn     r7                  ; get flags
           ani     0fdh                ; turn off executable flag
           str     r7                  ; and put it back
notmx:
           mov     rf,sector           ; point to dir sector in FILDES
           inc     rf
           lda     rf                  ; retrieve sector
           plo     r8
           lda     rf
           phi     r7
           lda     rf
           plo     r7
           ldi     0e0h                ; lba mode
           phi     r8
           mov     rf,secbuf           ; where to load sector
           sep     scall               ; write sector back to disk
           dw      f_idewrite

done:      lbr     o_wrmboot           ; return to os

errmsg:    db      'File not found',10,13,0
flags:     db      0
fildes:    db      0,0,0,0
           dw      dta
           db      0,0
           db      0
sector:    db      0,0,0,0
dirent:    dw      0,0
           db      0,0,0,0

endrom:    equ     $

buffer:    ds      20
cbuffer:   ds      80
dta:       ds      512
secbuf:    dw      512


