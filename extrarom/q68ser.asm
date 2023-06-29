; **********************************
; q68 serial drivers for Minerva ROM
; **********************************
; Based on SMSQ/E code by Tony Tebby/Wolfgang Lenerz
;
; Modifications for Minerva by Jan Bredenbeek
; Use and distribution governed by GNU Public License v3
; 
; Changelog:
;
; 20190705 JB Start of work

	section q68_ser

DEBUG	equ	0		; set to 1 to display variables and result code

q68	equ	1

         include userdefs
         include sv.inc
         include sx.inc
         include q68
         include q68hw.inc

; Initialise the serial port
; ==========================
; We need to do quite a bit of work on the interrupt code, since the Q68 does
; use the regular Level 2 Interrupt, BUT... it doesn't set the External
; Interrupt bit of the PC.INTR register when a TX/RX interrupt occurs!
; Hence, an unmodified Minerva would not recognise the interrupt and just
; return without clearing it, resulting in an endless interrupt loop!
; Of course, we could patch Minerva itself, but fortunately the INT2 vector
; at location $68 is now in writable RAM so we can redirect it to our own code
; to front-end Minerva's handler.
;
; For now, only the physical I/O layer will be adapted for the Q68 hardware.
; This means that the high-level I/O will still be handled through Minerva's
; I/O, Open, and Close routines. This is not ideal, as they assume a fixed
; buffer size of 81 bytes for both TX and RX queues, which will probably be too
; small for high-speed rates without handshake.
; This code expects the RX queue pointed to by SV_SER1C to be followed by the
; TX queue at offset $62 (82 bytes + 16 bytes queue header).

; This is called from the initialisation code in q68hw.asm, with A3 still
; pointing to the linkage block.

int2vec  equ      $68

         xdef     ser_init

ser_init lea      VAR.lxint(a3),a0  ; 
         lea      serint2(pc),a1
         cmpa.l   int2vec,a1
         beq.s    si_rts            ; Don't link in twice!
         move.l   int2vec,(a0)      ; save original int2 vector
         move.l   a1,int2vec        ; and set our own
         
; Next, we must replace Minerva's transmit and receive interrupt handlers with
; our own. 