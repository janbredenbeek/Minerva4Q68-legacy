; ************************************
; q68 hardware drivers for Minerva ROM
; ************************************
; Based on Q40/Q60/Q68 code by Richard Zidlicky
;
; Modifications for Q68 by Jan Bredenbeek
; Use and distribution governed by GNU Public License v3
; 
; Changelog:
;
; 20230709 JB (v1.4):
;   Implemented high-resolution mode (1024x768x4, DISP_MODE 4, BETA FEATURE)
;
; 20230628 JB (v1.3):
;   One version now for all keyboard languages, KBTABLE command added to switch
;
; 20230623 JB:
;   Added more initialisation code from SMSQ/E for handling keyboard interrupts
;
; 20230619 JB:
;   Interrupt handler now in external interrupt list as well as polled list
;
; 20210505 JB: (v1.2)
;
; Added scan for ROM header at end so another extension ROM image may be
; appended to the code (e.g. the SD-card driver), to reduce unused ROM space.
;
; 20190407 JB:
;
;   MDV driver now cleanly unlinked
;
; 20190405 JB:
;   Removed code under q68kbinch as this can be handled now by Minerva vectors
;   $150 and $152, including all the functionality like key repeat, ctrl-c etc.
;   Added IPC KEYROW emulation by using sx_ipcom front-end link in Minerva
;   Cleaned up rest of code as well.
;
; 20180427 JB:
;   Included tables for UK and US keyboard layouts
;   Set symbol q68_keyc to 1 for US, 44 for UK and 49 for DE

        xref    disp_mode,scr_base,scr_llen,scr_xlim,scr_ylim,rom_end

version	setstr	1.4

DEBUG	equ	0		; set to 1 to display variables and result code

;*  q68_keyc equ	1		; keyboard layout code (1 = US, 44 = UK, 49 = DE) 
;*  should go into userdefs

        include mincf
        include userdefs
        include sv.inc
        include sx.inc
        include bv.inc
        include err.inc
        include mt.inc
        include vect.inc
        include q68

string$	macro	a
	noexpand
[.lab]	dc.w	.e.[.l]-*-2
	dc.b	[a]
.e.[.l]	equ	*
	ds.w	0
	endm

BOOTDEV equ     0

; This is the start of the extension ROM header.
; Since our code is only about 2K and the system ROM scans for extension ROMs
; in increments of 16K, we would waste nearly 14K of space which could be
; occupied by another extension ROM. Also, Wolfgangs's SD-card driver is about
; 20K in length, wasting 12K of valuable ROM space. By combining our code with
; the SD-card driver, we can free up 16K in the $14000-$17FFF area, thus
; allowing for another extension ROM to be included in the 96K ROM image.
; For example, Toolkit II can now be included in the ROM image and doesn't have
; to be loaded from the BOOT file.
; Another scenario for extension ROMs which insist on placement in the $C000
; area is to include these right after the system ROM image, before the
; keyboard and SD-driver ROM.
; After doing our own initialisation, we now look for a ROM header following
; our code. If there is one, we do the usual initialisation that the system
; ROM does.

	section q68_q68hw
        
romh:
	dc.l	$4afb0001       ; ROM marker
	dc.w	procs-romh	; no procs to declare
	dc.w	rom_init-romh
	string$	{'Q68 extension ROM v[version]',10}
         ds.w     0

rom_init bsr.s    q68kbd_init       ; do our own initialisation
         move.l   a3,-(sp)          ; save ROM pointer
         lea      rom_end(pc),a3    ; end of our code
         cmpi.l   #$4afb0001,(a3)   ; is there another extension ROM after us?
         bne.s    bye               ; no, exit
         lea      8(a3),a1          ; ROM name
         suba.l   a0,a0
         move.w   ut.mtext,a2       ; print it
         jsr      (a2)
         move.w   4(a3),d0          ; S*Basic procs?
         beq.s    in_nobas          ; no
         lea      (a3,d0.w),a1
         move.w   bp.init,a2        ; else, link them in
         jsr      (a2)
in_nobas move.w   6(a3),d0          ; init routine?
         beq.s    bye               ; no
         jsr      (a3,d0.w)         ; else, call it
bye      move.l   (sp)+,a3          ; restore ROM pointer
         rts

****** q68 PS2 keyboard interface ********

*  linked in as poll routine, all variables stored rel a3
*  KEYBOARD variables

;SV_LXINT	EQU	$00	; (long) ptr to next link
				; (long) address of EXT INT routine

;SV_LPOLL	EQU	$08	; (long) ptr to next link
				; (long) address of POLLed int routine


VAR.KEYtab   EQU	$3C	; (long) ptr to ASCII table

* the following word offsets are relative pointers to the above table
* add these offsets with ctrl, shift, ctrl/shift and graphics
* e.g. add.w ktab_of_sh(a0),a0 to get the shifted table

ktab_of_ct   equ        -8      ; offset of ctrl+key table
ktab_of_sh   equ        -6      ; offset of shift+key table
ktab_of_cs   equ        -4      ; offset of ctrl+shift+key table
ktab_of_gr   equ        -2      ; offset of graphics+key table

VAR.IPClnk   EQU	$40	; link to next IPCOM front-end routine
VAR.IPCemu   EQU	$44	; pointer to IPC keyrow emulation routine

VAR.KEYraw   EQU	$48	; (8xbyte) used to emulate KEYROW

VAR.CTLflg   EQU	$50	; (byte) CTRL key is down
VAR.SHFflg   EQU	$51	; (byte) SHIFT key is down
VAR.ALTflg   EQU	$52	; (byte) ALT key is down
VAR.ACTkey   EQU	$53	; (byte) value gotten from keyboard

VAR.ARbuf    EQU	$54	; (4b) buffer for keyboard autorepeat cancel

VAR.RLSflg   EQU	$58	; (byte) next key is to be released
VAR.MODflg   EQU	$59	; (byte) next key is 'special'

; VAR.LEDflg   EQU	$56	; (byte) status of LEDs

VAR.NLKflg   EQU	$5A	; (byte) status of NUMLOCK

VAR.GFXflg   EQU	$5B	; (byte) status ALT-Gr key
VAR.ASCkey   EQU	$5C	; (byte) value converted to ASCII
VAR.KEYdwc   EQU	$5D	; (byte) count of keys held down
VAR.KEYdwk   EQU	$5E	; (16 x byte) ACTUAL key-down list
VAR.KEYdwa   EQU	$6E	; (16 x byte) ASCII key-down list

VAR.LEN	    EQU	$7E	; length of vars

*workaround broken gwass
vdwak	equ	VAR.KEYdwa-VAR.KEYdwk

* keytables from QDOS Classic
* /home/rz/qdos/qdos-classic/QZ-net/CLSC/SRC/CORE/KBD_asm - main kbd driver
*	+ gets decoded keycodes/vars (bsr HW_KEY_read)
;	+ KEY_conv: convert to ASCII
* /home/rz/qdos/qdos-classic/QZ-net/CLSC/SRC/Q40/KBD_asm
*	+ HW_KEY_read: read HW, call KEY_decode
* /home/rz/qdos/qdos-classic/QZ-net/CLSC/SRC/ISA/804Xa_asm
;	+ KEY_decode: press/relse, modifier and weird keys
* /home/rz/qdos/qdos-classic/QZ-net/CLSC/SRC/ISA/804Xd_asm - keytable-de



***************************************************************
** Q40 KBD_asm

*	INCLUDE	'CLSC_SRC_CORE_KBD_inc'
; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  start of ROM code

initreg	reg	d1-d3/a0-a4

q68kbd_init:

	movem.l	initreg,-(a7)

;* driver memory
	moveq	#0,d2		; owner is superBASIC

;* VAR.LEN should be enough
	move.l	#18+VAR.LEN,d1  ; length
	moveq	#$18,d0		;  MT.ALCHP
	trap	#1		; allocate space

	tst.l	d0
	bne	ROM_EXIT 	; exit if error
	move.l	a0,a3           ; base of linkage block
	moveq	#0,d0
	trap	#1
	cmpi.l	#'1.60',d2	; check QDOS version
	blo	initerr		; must be Minerva
	cmpi.l	#'2.00',d2	; not SMSQ/E...
	bhs	initerr
	move.l	sv_chtop(a0),a4	; base of extended sysvars
	lea	$b0(a4),a0	; linkage block of MDV driver         
	moveq	#$23,d0		; MT.RDD
	trap	#1		; unlink MDV driver

; --------------------------------------------------------------
;  set ASCII table and clear actual key.
;; most code redundant as MT.ALCHP has cleared out area already!

	move.w  #q68_keyc,d1    ; set from userdefs
        bsr     set_kb          ; set keyboard language
        beq.s   init_2          ; OK?
        lea	L01_KTAB(pc),a0 ; No, default to US
        move.l	a0,VAR.KEYtab(a3)
init_2:
	clr.b	VAR.KEYdwc(a3)	; clear held down key count

	lea	VAR.KEYraw(a3),a0
	clr.l	(a0)+
	clr.l	(a0)+		; invalidate KEYROW bits

	lea	VAR.CTLflg(a3),a0

	clr.l	(a0)+
	clr.l	(a0)+		; clear key flags + VAR.ARbuf
	st	VAR.NLKflg(a3)	; set NUMLOCK

;;	lea	VAR.ACTkey(a3),a0
;;	clr.w	(a0)+		; clear keycodes

; ----------------------------------------------------------------
; disable the Minerva polled task for reading the IPC, since there
; is no IPC in the Q68

	lea	ip_poll(a4),a0	; link to polled task
	moveq	#$1d,d0		; MT.RPOLL
	trap	#1

; replace the ROM keyboard decode routine in sx_kbenc with our own

	lea	Q68kbenc(pc),a0
	move.l	a0,sx_kbenc(a4)
; --------------------------------------------------------------
;  link in polled task routine to handle keyboard

;;	lea	POLL_SERver(pc),a1 ; redundant code, use real address
      	st      kbd_status              ; try  to use interrupts for keyboard
        move.b  kbd_status,d0           ; can I use interrupts for keyboard?
;;      btst    #7,d0
;;      beq.s   no_intr
        bpl.s   no_intr                 ;   ... no
        lea     RDKEYX(pc),a1           ; address of external interrupt handler
        lea     SV_LXINT(a3),a0
        move.l  a1,4(a0)
        moveq   #$1a,d0                 ; MT.LXINT
        trap    #1
        st      kbd_status              ; show that we use interrupts
        st      kbd_unlock              ; keyboard may start up
        suba.l  a0,a0
        lea     intmsg,a1               ; EXPERIMENTAL
        move.w  $d0,a2                  ; UT_MTEXT
        jsr     (a2)
no_intr lea     RDKEYB(pc),a1   ; real address
	lea	SV_LPOLL(a3),a0
	move.l	a1,4(a0) 	; address of polled task
	moveq	#$1c,d0		;  MT.LPOLL
	trap	#1
	lea	VAR.IPClnk(a3),a0 ; address of IPC front-end linked list
	lea	KR_ipcem(pc),a1	; address of IPC keyrow emulation routine
	move.l	a1,4(a0)	; set pointer to routine
	lea	sx_ipcom(a4),a1	; pointer to MT.IPCOM front-end list
	move.w	$d2,a2		; UT.LINK
	jsr	(a2)		; link in routine
	bra.s	ROM_EXIT

        GENIF BOOTDEV <> 0
	bsr.s	boot_init       ; 'future enhancement...'
	bra.s	ROM_EXIT
        ENDGEN

initerr	suba.l	a0,a0
        lea	inerrms,a1
	move.w	$d0,a2
	jsr	(a2)		; print error message

ROM_EXIT:
	movem.l	(a7)+,initreg
	rts

inerrms	string$	{'Incompatible QDOS Version!',10}
intmsg  string$ {'* Using keyboard interrupt *',10}

	ds.w	0
        
************************************
* Procedure and function definitions

procs   dc.w    2               ; two procedures
        dc.w    kbtable-*
        dc.b    7,'KBTABLE'
        dc.w    disp_mode-*
        dc.b    9,'DISP_MODE'
        dc.w    0               ; end of procs
        dc.w    4               ; no of functions
        dc.w    scr_base-*
        dc.b    8,'SCR_BASE'
        dc.w    scr_llen-*
        dc.b    8,'SCR_LLEN'
        dc.w    scr_xlim-*
        dc.b    8,'SCR_XLIM'
        dc.w    scr_ylim-*
        dc.b    8,'SCR_YLIM'
        dc.w    0               ; end of functions

* subroutine to get address of linkage block from BASIC
* Entry: none
* Exit: D0 error code (0 OK, err.nf block not found)
*       A3 points to linkage block

get_lb:
        movem.l d1-d2/a0-a1,-(sp)  ; save these registers
        moveq   #mt.inf,d0
        trap    #1
        lea     SV_PLIST(a0),a0 ; pointer to polled task list
        lea     RDKEYB(pc),a1   ; address of our polled task
glb_loop:
        tst.l   (a0)            ; end of list reached?
        beq.s   glb_notf        ; yes
        move.l  (a0),a0         ; else, get next entry
        cmpa.l  4(a0),a1        ; is this the entry we're looking for?
        bne.s   glb_loop        ; no, loop back
        lea     -SV_LPOLL(a0),a3 ; point to start of linkage block
        moveq   #0,d0           ; success
        bra.s   glb_ret
glb_notf:
        moveq   #err.nf,d0      ; oops... block not found!
glb_ret movem.l (sp)+,d1-d2/a0-a1
        rts

* KBTABLE command sets the keyboard table
* Usage: KBTABLE <country code>

kbtable:
        move.w  ca.gtint,a2     ; get integer parameter
        jsr     (a2)
        bne.s   kb_exit         ; if error
        subq.w  #1,d3
        bne.s   kb_bp           ; must have 1 parameter
        move.w  (a6,a1.l),d1    ; get it
        addq.l  #2,bv_rip(a6)   ; clean up math stack
        bsr     get_lb          ; get pointer to linkage block
        bne.s   kb_exit         ; oops...

set_kb:                         ; also used from init!
        lea     LNG_MODULE(pc),a1 ; pointer to first language table
kb_loop:
        cmp.w   4(a1),d1        ; is this the country code we're looking for?
        beq.s   kb_set          ; yes, set pointer
        addq.l  #6,a1           ; point to pointer to next table
        tst.w   (a1)            ; end reached?
        beq.s   kb_bp           ; yes, throw error
        adda.w  (a1),a1         ; point to next entry
        bra     kb_loop         ; loop
kb_set: 
        addq.l  #8,a1           ; point to pointer to keyboard table header
        adda.w  (a1),a1         ; (relative)
        addq.l  #2,a1           ; skip country code (should check this?)
        adda.w  (a1),a1         ; point to first keyboard table
        move.l  a1,VAR.keytab(a3) ; set pointer in our linkage block
        moveq   #0,d0           ; success
kb_exit rts

kb_bp   moveq   #err.bp,d0
        rts

*****************************************************
* BOOT driver for debugging purposes *
   GENIF BOOTDEV <> 0
bpos	equ	$18		;  store pos at this offset in chdef block

boot_init
        moveq    #0,d2                      ; owner
***XXXXX how much memory?
	moveq	 #$24,d0
        move.l   d0,d1          ;  try 0x18 bytes of memory...
	trap	 #1
        tst.l    d0
        bne.s    ret_boot

	move.l   a0,a2                      ; Adresse retten

        lea      4(a2),a1
        lea      boot_io,a0
        move.l   a0,(a1)+
        lea      boot_open,a0
        move.l   a0,(a1)+
        lea      boot_close,a0
        move.l   a0,(a1)

        move.l  a2,a0
        moveq	#$20,d0		; mt.liod
	trap	#1
ret_boot
	rts

boot_open
        move.l   a7,a3		; no pars
        move.w   $122,a2	; io.name
        jsr      (a2)
        bra.s    wrong_nm
        bra.s    wrong_nm
        bra.s    ok_nm
        dc.w     4
	dc.b	'BOOT'
        dc.w     0		; 0 pars

wrong_nm
	moveq	#-7,d0
	rts

ok_nm
*       cmp.l    #1,d3
*	bne.s	exit_bn
        move.l   #$18+4,d1	;  just one long

        move.w   $c0,a2	;  mm.alchp
        jsr      (a2)
        bne.s    exit

	clr.l	bpos(a0)	;  pos at start
        moveq    #0,d0
ret     rts

exit_iu  moveq    #-9,d0
exit     rts
exit_bn  moveq    #-12,d0
         rts
exit_nc  moveq    #-1,d0
         rts


boot_io
	move.w	$ea,a2		;  serio
        jsr    2(a2)		;  HACK serio+2=relio
	dc.w	bfpend-*
	dc.w	bfbyte-*
	dc.w	bsbyte-*

bfpend:
	move.l	boot_len,d0
	sub.l	bpos(a0),d0
	ble.s	fend
	clr.l	d0
	rts
bfbyte:	
	move.l	boot_len,d0
	sub.l	bpos(a0),d0
	ble.s	fend
	move.l	bpos(a0),d0
	move.b	boot_buf(pc,d0.l),d1
	addq.l	#1,d0
	move.l	d0,bpos(a0)
	clr.l	d0
	rts

fend    moveq    #-10,d0
        rts
bsbyte
	moveq	#-20,d0
	rts

BOOT_CLOSE
         move.w   $c2,a2                        MM_RECHP
         move.l   a3,a4
         jsr      (a2)
;  *       lea      $18(a4),a0
;  *       moveq    #mt.riod,d0
;  *       trap     #1
;  *       moveq    #mt.rechp,d0
;  *       trap     #1
         rts

boot_len
	dc.l	15
boot_buf
	dc.b	'LRUN win1_BOOT',10

   ENDGEN

*****************************************************


; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
; Conversion tables for translating ASCII to KEYROW
;
; The organization is (in ASCII order):
;  CTRL(bit7) SHFT(bit6) ROWnumber(bits5-3) COLnumber(bits2-0)

QLRAWKEY:
 dc.b 149,164,148,147,166,180,156,158   ; 00-07
 dc.b 162,43,8,154,160,150,190,175      ; 08-0F
 dc.b 165,179,172,155,182,183,188,169   ; 10-17
 dc.b 187,174,145,11,205,208,213,203    ; 18-1F
 dc.b 14,99,87,97,70,66,71,23           ; 20-27 (' '-''')
 dc.b 104,117,112,93,63,45,18,61        ; 28-2F ('('-'/')
 dc.b 53,35,49,33,6,2,50,7              ; 30-37 ('0'-'7')
 dc.b 48,40,95,31,127,29,82,125         ; 38-3F ('8'-'?')
 dc.b 113,100,84,83,102,116,92,94       ; 40-47 ('@'-'G')
 dc.b 98,106,103,90,96,86,126,111       ; 48-4F ('H'-'O')
 dc.b 101,115,108,91,118,119,124,105    ; 50-57 ('P'-'W')
 dc.b 123,110,81,24,13,16,114,109       ; 58-5F ('X'-'_')
 dc.b 21,36,20,19,38,52,28,30           ; 60-67 ('`'-'g')
 dc.b 34,42,39,26,32,22,62,47           ; 68-6F ('h'-'o')
 dc.b 37,51,44,27,54,55,60,41           ; 70-77 ('p'-'w')
 dc.b 59,46,17,88,77,80,85,75           ; 78-7F ('x'-'(C)')
 dc.b 139,227,215,225,198,194,199,151   ; 80-87
 dc.b 232,245,240,221,191,173,146,189   ; 88-8F
 dc.b 181,163,177,161,134,130,178,135   ; 90-97
 dc.b 176,168,223,159,255,157,210,253   ; 98-9F
 dc.b 241,228,212,211,230,244,220,222   ; A0-A7
 dc.b 226,234,231,218,224,214,254,239   ; A8-AF
 dc.b 229,243,236,219,246,247,252,233   ; B0-B7
 dc.b 251,238,209,152,141,144,242,237   ; B8-BF
 dc.b 9,9,137,137,73,73,201,201         ; C0-C7
 dc.b 12,12,140,140,76,76,204,204       ; C8-CF
 dc.b 10,10,138,138,74,74,202,202       ; D0-D7
 dc.b 15,15,143,143,79,70,207,207       ; D8-DF
 dc.b 25,25,153,153,89,89,217,217       ; E0-E7
 dc.b 1,129,65,193,3,131,67,195         ; E8-EF
 dc.b 4,132,68,196,0,128,64,192         ; F0-F7
 dc.b 5,133,69,197,78,107,72,58         ; F8-FF

QLRAWEND:


;**************************************************************
;* code verbatim from CLSC/SRC/ISA/804Xa_asm
;*******************************************************************
;*
;* KBD_asm - Keyboard routines
;*	 - for hardware that is compatible with 804X driver
;*	 - originated July 98 - Mark Swift
;*	 - last modified 22/09/99 (MSW)

AWKCOD	EQU	74		; awkward key that doesn't fit
AWKASC	EQU	'/'		; into scheme if NUMLOCK is on

;*******************************************************************
;*
;*  Subroutine to decode raw keyboard value
; Entry: D0 scan code from keyboard (PC-style)
; Exit: none, sets CTL/SHF/ALT flags and VAR.ACTkey to scancode

KEY_decode:

; --------------------------------------------------------------
; first test for SHIFT, CTRL, ALT, etc...

	cmp.b	#224,d0		; modify next keycode?
	beq.s	KEY_mSTO

	cmp.b	#225,d0		; modify next keycode?
	bne.s	KEY_rTST

KEY_mSTO
	move.b	d0,VAR.MODflg(a3)
	bra	KEY_none

KEY_rTST:
	cmp.b	#240,d0		; key release?
	bne.s	KEY_sTST

	move.b	d0,VAR.RLSflg(a3) ; set release flag
	bra.s	KEY_none	; and exit

KEY_sTST:
	cmp.b	#18,d0		; left shift?
	beq.s	KEY_sDO

	cmp.b	#89,d0		; right shift?
	bne.s	KEY_cTST

KEY_sDO:
	tst.b	VAR.RLSflg(a3)	; key released?
	beq.s	KEY_sSTO	; no

	moveq	#0,d0		; clear flag

KEY_sSTO
	move.b	d0,VAR.SHFflg(a3)
	bra.s	KEY_done

KEY_cTST:
	cmp.b	#20,d0		; control?
	bne.s	KEY_aTST

	tst.b	VAR.RLSflg(a3)
	beq.s	KEY_cSTO

	clr.b	VAR.MODflg(a3)	; clear the weird flag
	moveq	#0,d0

KEY_cSTO
	move.b	d0,VAR.CTLflg(a3)
	bra.s	KEY_done

KEY_aTST:
	cmp.b	#17,d0		; alt?
	bne.s	KEY_nTST

	tst.b	VAR.RLSflg(a3)
	beq.s	KEY_aSTO

KEY_aCLR
	clr.b	VAR.MODflg(a3)	; clear the weird flag
	clr.b	VAR.GFXflg(a3)	; clear ALT-Gr flag
	moveq	#0,d0

KEY_aSTO
	move.b	d0,VAR.ALTflg(a3)

	tst.b	VAR.MODflg(a3)	; test the weird flag
	beq.s	KEY_done

	move.b	d0,VAR.GFXflg(a3) ; possible ALT-Gr character
	bra.s	KEY_done

KEY_nTST:
	cmp.b	#119,d0		; NUMLOCK?
	bne.s	KEY_doKEY

	tst.b	VAR.RLSflg(a3)
	bne.s	KEY_done

	not.b	VAR.NLKflg(a3)	; set NUMLOCK flag
*	bsr	HW_DO_LEDS
	bra.s	KEY_done

KEY_doKEY:
	move.b	d0,VAR.ACTkey(a3) ; store keycode
	bra.s	KEY_exit

KEY_done:
	clr.b	VAR.MODflg(a3)	; clear the weird flag
	clr.b	VAR.RLSflg(a3)	; and the release flag

KEY_none:
	clr.b	VAR.ACTkey(a3)	; clear the ACTUAL keycode
	clr.b	VAR.ASCkey(a3)	; clear the ASCII keycode

KEY_exit:
	rts

*******************************************************************
*
* KBD_asm - US language keyboard tables
*	 - for hardware that is compatible with 804X driver
*	 - originated July 98 - Mark Swift
*	 - last modified 25/04/18 (JB)


*******************************************************************
*
*  conversion tables for translating rawkeycode to ASCII

* As of v1.3, there is now a single ROM version for all three languages.
* The tables have been extended so that they now contain the offsets from the
* base (unshifted) table to the tables for CTRL, Shift, CTRL-Shift and Graphics
* respectively (between the keyboard table header and the base table).
* The keyboard language may be set using the set_kb subroutine (entry with D1
* holding the country code, currently 1, 44 or 49)

LNG_MODULE:

 DC.W 1		; keyboard table
 DC.W 0		; no group
 DC.W 1 	; language number (US)
 DC.W L44_MOD-*	; relative ptr to next module or 0
 DC.W L01_KBD-*	; relative ptr to keyboard table

L01_KBD:

 DC.W 1 	; language (US)
 DC.W L01_KTAB-*	; relative ptr to key table
 DC.W 0		; relative ptr to non-spacing char table

* JB: Added offsets from base table to CT/SH/SC/GR tables
* (they may not be constants!). This uses the space between the header and the
* first table, but should remain compatible with the old format since the
* header contains a relative pointer to the first table...

 DC.W L01_KTAB_CT-L01_KTAB      ; offset to CTRL key table
 DC.W L01_KTAB_SH-L01_KTAB      ; offset to SHIFT key table
 DC.W L01_KTAB_SC-L01_KTAB      ; offset to CTRL/SHIFT key table
 DC.W L01_KTAB_GR-L01_KTAB      ; offset to Graphics key table

L01_KTAB:
 DC.B 0,246,0,248,240,232,236,0,0,250,242,234,244,9,159,0
 DC.B 0,0,0,0,0,'q','1',0,0,0,'z','s','a','w','2',0
 DC.B 0,'c','x','d','e','4','3',0,0,' ','v','f','t','r','5',0
 DC.B 0,'n','b','h','g','y','6',0,0,0,'m','j','u','7','8',0
 DC.B 0,',','k','i','o','0','9',0,0,'.','/','l',';','p','-',0
 DC.B 0,0,39,0,91,'=',0,0,224,0,10,']',0,'\',0,0
 DC.B 0,'\',0,0,0,0,194,0,0,201,0,192,193,0,0,0
 DC.B 0,202,216,0,200,208,27,0,0,'+',220,'-','*',212,249,0
 DC.B 0,0,0,238

L01_KTAB_CT:
 DC.B 0,247,0,249,241,233,237,0,0,251,243,235,245,0,0,0
 DC.B 0,0,0,0,0,17,145,0,0,0,26,19,1,23,146,0
 DC.B 0,3,24,4,5,148,147,0,0,32,22,6,20,18,149,0
 DC.B 0,14,2,8,7,25,150,0,0,0,13,10,21,151,152,0
 DC.B 0,140,11,9,15,144,153,0,0,142,143,12,155,16,141,0
 DC.B 0,0,135,0,187,157,0,0,226,0,0,189,0,131,0,0
 DC.B 0,188,0,0,0,0,0,0,0,206,0,194,198,0,0,0
 DC.B 0,202,218,0,202,210,128,0,0,139,222,141,138,214,0,0
 DC.B 0,0,0,239

L01_KTAB_SH:
 DC.B 0,0,0,250,242,234,238,0,0,0,0,0,246,253,126,0
 DC.B 0,0,0,0,0,'Q','!',0,0,0,'Z','S','A','W','@',0
 DC.B 0,'C','X','D','E','$',35,0,0,252,'V','F','T','R','%',0
 DC.B 0,'N','B','H','G','Y','^',0,0,0,'M','J','U','&','*',0
 DC.B 0,'<','K','I','O',')','(',0,0,'>','?','L',':','P','_',0
 DC.B 0,0,34,0,'{','+',0,0,228,0,254,'}',0,'|',0,0
 DC.B 0,'|',0,0,0,0,198,0,0,'1',0,'4','7',0,0,0
 DC.B '0','.','2','5','6','8',127,0,0,'+','3','-','*','9',250,0
 DC.B 0,0,0,0

L01_KTAB_SC:
 DC.B 0,0,0,251,243,235,239,0,0,0,0,0,247,0,0,0
 DC.B 0,0,0,0,0,177,129,0,0,0,186,179,161,183,130,0
 DC.B 0,163,184,164,165,132,0,0,0,32,182,166,180,178,133,0
 DC.B 0,174,162,168,167,185,190,0,0,0,173,170,181,134,138,0
 DC.B 0,156,171,169,175,137,136,0,0,158,159,172,154,176,191,0
 DC.B 0,0,160,0,27,139,0,0,230,0,0,29,0,30,0,0
 DC.B 0,28,0,0,0,0,0,0,0,145,0,148,151,0,0,0
 DC.B 144,142,146,149,150,152,31,0,0,139,147,141,138,153,0,0
 DC.B 0,0,0,0

L01_KTAB_GR:
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0

L01_NSTAB:

; KTB_OFFS_CT EQU	(LNG_KTAB_CT-LNG_KTAB)
; KTB_OFFS_SH EQU	(LNG_KTAB_SH-LNG_KTAB)
; KTB_OFFS_GR EQU	(LNG_KTAB_GR-LNG_KTAB)

;       ENDGEN

*******************************************************************
*
* KBD_asm - UK language keyboard tables
*	 - for hardware that is compatible with 804X driver
*	 - originated July 98 - Mark Swift
*	 - last modified 22/09/99 (MSW)


*******************************************************************
*
*  conversion tables for translating rawkeycode to ASCII

;       GENIF	q68_keyc = 44

L44_MOD:

 DC.W 1		; keyboard table
 DC.W 0		; no group
 DC.W 44 	; language number (UK)
 DC.W L49_MOD-*	; relative ptr to next module or 0
 DC.W L44_KBD-*	; relative ptr to keyboard table

L44_KBD:

 DC.W 44 	; language (UK)
 DC.W L44_KTAB-*	; relative ptr to key table
 DC.W 0		; relative ptr to non-spacing char table

 DC.W L44_KTAB_CT-L44_KTAB      ; offset to CTRL key table
 DC.W L44_KTAB_SH-L44_KTAB      ; offset to SHIFT key table
 DC.W L44_KTAB_SC-L44_KTAB      ; offset to CTRL/SHIFT key table
 DC.W L44_KTAB_GR-L44_KTAB      ; offset to Graphics key table

L44_KTAB:
 DC.B 0,246,0,248,240,232,236,0,0,250,242,234,244,9,159,0
 DC.B 0,0,0,0,0,'q','1',0,0,0,'z','s','a','w','2',0
 DC.B 0,'c','x','d','e','4','3',0,0,' ','v','f','t','r','5',0
 DC.B 0,'n','b','h','g','y','6',0,0,0,'m','j','u','7','8',0
 DC.B 0,',','k','i','o','0','9',0,0,'.','/','l',';','p','-',0
 DC.B 0,0,39,0,91,'=',0,0,224,0,10,']',0,35,0,0
 DC.B 0,'\',0,0,0,0,194,0,0,201,0,192,193,0,0,0
 DC.B 0,202,216,0,200,208,27,0,0,'+',220,'-','*',212,249,0
 DC.B 0,0,0,238

L44_KTAB_CT:
 DC.B 0,247,0,249,241,233,237,0,0,251,243,235,245,0,0,0
 DC.B 0,0,0,0,0,17,145,0,0,0,26,19,1,23,146,0
 DC.B 0,3,24,4,5,148,147,0,0,32,22,6,20,18,149,0
 DC.B 0,14,2,8,7,25,150,0,0,0,13,10,21,151,152,0
 DC.B 0,140,11,9,15,144,153,0,0,142,143,12,155,16,141,0
 DC.B 0,0,135,0,187,157,0,0,226,0,0,189,0,131,0,0
 DC.B 0,188,0,0,0,0,0,0,0,206,0,194,198,0,0,0
 DC.B 0,202,218,0,202,210,128,0,0,139,222,141,138,214,0,0
 DC.B 0,0,0,239

L44_KTAB_SH:
 DC.B 0,0,0,250,242,234,238,0,0,0,0,0,246,253,0,0
 DC.B 0,0,0,0,0,'Q','!',0,0,0,'Z','S','A','W',34,0
 DC.B 0,'C','X','D','E','$',96,0,0,252,'V','F','T','R','%',0
 DC.B 0,'N','B','H','G','Y','^',0,0,0,'M','J','U','&','*',0
 DC.B 0,'<','K','I','O',')','(',0,0,'>','?','L',':','P','_',0
 DC.B 0,0,'@',0,'{','+',0,0,228,0,254,'}',0,126,0,0
 DC.B 0,'|',0,0,0,0,198,0,0,'1',0,'4','7',0,0,0
 DC.B '0','.','2','5','6','8',127,0,0,'+','3','-','*','9',250,0
 DC.B 0,0,0,0

L44_KTAB_SC:
 DC.B 0,0,0,251,243,235,239,0,0,0,0,0,247,0,0,0
 DC.B 0,0,0,0,0,177,129,0,0,0,186,179,161,183,130,0
 DC.B 0,163,184,164,165,132,0,0,0,32,182,166,180,178,133,0
 DC.B 0,174,162,168,167,185,190,0,0,0,173,170,181,134,138,0
 DC.B 0,156,171,169,175,137,136,0,0,158,159,172,154,176,191,0
 DC.B 0,0,160,0,27,139,0,0,230,0,0,29,0,30,0,0
 DC.B 0,28,0,0,0,0,0,0,0,145,0,148,151,0,0,0
 DC.B 144,142,146,149,150,152,31,0,0,139,147,141,138,153,0,0
 DC.B 0,0,0,0

L44_KTAB_GR:
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0

; LNG_NSTAB:

; KTB_OFFS_CT EQU	(LNG_KTAB_CT-LNG_KTAB)
; KTB_OFFS_SH EQU	(LNG_KTAB_SH-LNG_KTAB)
; KTB_OFFS_GR EQU	(LNG_KTAB_GR-LNG_KTAB)

;       ENDGEN

******************************************************************
* VERBATIM from CLSC/SRC/ISA/804Xd_asm
*
* KBD_asm - German language keyboard tables
*	 - for hardware that is compatible with 804X driver
*	 - originated July 98 - Mark Swift
*	 - last modified 22/09/99 (MSW)


*******************************************************************
*
*  conversion tables for translating keycode to ASCII

;       GENIF	q68_keyc = 49

L49_MOD:

 DC.W 1		; keyboard table
 DC.W 0		; no group
 DC.W 49 	; language number (german)
 DC.W 0		; relative ptr to next module or 0
 DC.W L49_KBD-*	; relative ptr to keyboard table

L49_KBD:

 DC.W 49 	; language (german)
 DC.W L49_KTAB-*	; relative ptr to key table
 DC.W 0		; relative ptr to non-spacing char table

 DC.W L49_KTAB_CT-L49_KTAB      ; offset to CTRL key table
 DC.W L49_KTAB_SH-L49_KTAB      ; offset to SHIFT key table
 DC.W L49_KTAB_SC-L49_KTAB      ; offset to CTRL/SHIFT key table
 DC.W L49_KTAB_GR-L49_KTAB      ; offset to Graphics key table

L49_KTAB:
 DC.B 0,246,0,248,240,232,236,0,0,250,242,234,244,9,94,0
 DC.B 0,0,0,0,0,'q','1',0,0,0,'y','s','a','w','2',0
 DC.B 0,'c','x','d','e','4','3',0,0,' ','v','f','t','r','5',0
 DC.B 0,'n','b','h','g','z','6',0,0,0,'m','j','u','7','8',0
 DC.B 0,',','k','i','o','0','9',0,0,'.','-','l',132,'p',156,0
 DC.B 0,0,128,0,135,39,0,0,224,0,10,'+',0,35,0,0
 DC.B 0,'<',0,0,0,0,194,0,0,201,0,192,193,0,0,0
 DC.B 0,202,216,0,200,208,27,0,0,'+',220,'-','*',212,249,0
 DC.B 0,0,0,238

L49_KTAB_CT:
 DC.B 0,247,0,249,241,233,237,0,0,251,243,235,245,0,0,0
 DC.B 0,0,0,0,0,17,145,0,0,0,25,19,1,23,146,0
 DC.B 0,3,24,4,5,148,147,0,0,32,22,6,20,18,149,0
 DC.B 0,14,2,8,7,26,150,0,0,0,13,10,21,151,152,0
 DC.B 0,140,11,9,15,144,153,0,0,142,141,12,0,16,141,0
 DC.B 0,0,0,0,0,157,0,0,226,0,0,139,0,131,0,0
 DC.B 0,156,0,0,0,0,0,0,0,206,0,194,198,0,0,0
 DC.B 0,202,218,0,202,210,128,0,0,139,222,141,138,214,0,0
 DC.B 0,0,0,239

L49_KTAB_SH:
 DC.B 0,0,0,250,242,234,238,0,0,0,0,0,246,253,186,0
 DC.B 0,0,0,0,0,'Q','!',0,0,0,'Y','S','A','W',34,0
 DC.B 0,'C','X','D','E','$',182,0,0,252,'V','F','T','R','%',0
 DC.B 0,'N','B','H','G','Z','&',0,0,0,'M','J','U','/','(',0
 DC.B 0,';','K','I','O','=',')',0,0,':','_','L',164,'P','?',0
 DC.B 0,0,160,0,167,159,0,0,228,0,254,'*',0,39,0,0
 DC.B 0,'>',0,0,0,0,198,0,0,'1',0,'4','7',0,0,0
 DC.B '0','.','2','5','6','8',127,0,0,'+','3','-','*','9',250,0
 DC.B 0,0,0,0

L49_KTAB_SC:
 DC.B 0,0,0,251,243,235,239,0,0,0,0,0,247,0,0,0
 DC.B 0,0,0,0,0,177,129,0,0,0,185,179,161,183,130,0
 DC.B 0,163,184,164,165,132,0,0,0,32,96,166,180,178,133,0
 DC.B 0,174,162,168,167,186,190,0,0,0,173,170,181,134,138,0
 DC.B 0,155,171,169,175,137,136,0,0,154,191,172,0,176,191,0
 DC.B 0,0,0,0,0,139,0,0,230,0,0,138,0,135,0,0
 DC.B 0,158,0,0,0,0,0,0,0,145,0,148,151,0,0,0
 DC.B 144,142,146,149,150,152,31,0,0,139,147,141,138,153,0,0
 DC.B 0,0,0,0

L49_KTAB_GR:
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,'@',0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,176,0,0,'{',91,0
 DC.B 0,0,0,0,0,'}',']',0,0,0,0,0,0,0,'\',0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,126,0,0,0,0
 DC.B 0,'|',0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
 DC.B 0,0,0,0

; LNG_NSTAB:

; KTB_OFFS_CT EQU	(LNG_KTAB_CT-LNG_KTAB)
; KTB_OFFS_SH EQU	(LNG_KTAB_SH-LNG_KTAB)
; KTB_OFFS_GR EQU	(LNG_KTAB_GR-LNG_KTAB)

;       ENDGEN

******************************************************************

; --------------------------------------------------------------
;  Handle key event - response to a keyboard interrupt
;  called from polled list or external interrupt list

rkeyreg REG	d3/a3-a4	; not really needed, but just in case...

RDKEYX: moveq   #0,d3           ; external interrupt entry;
                                ; signal 'no polls missed'
RDKEYB:                         ; polled interrupt entry
	movem.l	rkeyreg,-(a7)

; read keyboard

	move.l	SV_KEYQ(a6),d0	; current keyboard queue
	beq	RDKEYBR		; if no queue
	move.l	d0,a2		; A2 holds queue address
	btst.b	#0,KEY_STATUS	; key pressed?
	beq.s	RDKEYBX		; no, exit but do key repeat proc first
kbl	move.b	KEY_CODE,d0	; get scan code
	st	KEY_UNLOCK	; signal 'got it'
	bsr	KEY_decode	; process shift/ctrl/alt/scancode

	GENIF	DEBUG = 1
	bsr	DBvars		; DEBUG: display vars
	ENDGEN

	tst.b	VAR.ACTkey(a3)	; get active scan code
	bne.s	RDKEYB1		; branch if alpha-char

	bsr	KR_DOIT		; else keyrow for SHF/CTL/ALT
	bra.s	RDKEYBXL	; ...and next/exit

RDKEYB1:
	tst.b	VAR.RLSflg(a3)	; key released?
	beq.s	RDKEYB2		; branch if key-down event

	bsr	KR_REMV		; remove key from key-down-list
	clr.b	VAR.RLSflg(a3)	; clear the release flag
	clr.b	VAR.ASCkey(a3)	; clear the ASCII keycode
	clr.b	VAR.ACTkey(a3)	; clear the ACTUAL keycode
	clr.l	VAR.ARbuf(a3)	; clear autorepeat buffer
;;	CLR.W	sv_arbuf(A6)	; reset Autorepeat buffer
	bra.s	RDKEYBXL	; and get next (if any)

RDKEYB2:
	move.l	VAR.CTLflg(a3),d0 ; test CTL/SHF/ALT+VAR.ACTkey
	cmp.l	VAR.ARbuf(a3),d0 ; key code is same as last processed?
	beq.s	RDKEYBXL	; yes, ignore autorepeat from keyboard
	bsr.s	KEY_conv	; get ASCII code or 'special' codes

	GENIF	DEBUG <> 0	; DEBUG: display output from KEY_conv

	blt.s	RKDSPEC
	beq.s	RKDNORM
	move.w	#$0A00,d1	; ignore: display 00 & LF
	bsr	DBBYTE
	bra.s	RDKEYBdn
RKDNORM	exg	d1,d2		; normal: display ASCII & LF
	move.w	#$0A00,d1
	or.b	d2,d1
	bsr	DBBYTE
	exg	d1,d2
	bra.s	RDKEYBdn
RKDSPEC	exg	d1,d2		; special: display $80+code & LF
	move.w	#$0A80,d1
	or.b	d2,d1
	bsr.s	DBBYTE
	exg	d1,d2

	ENDGEN

RDKEYBdn:
	tst.l	d0		; -2: special, 0: normal, 2: ignore
	bne.s	RDKEYBin	; if special or invalid code
	bsr	KR_ENTR		; enter key into key-down-list

; handle normal or special codes; call ip.kbrd vector which calls Q68kbenc
; via sx.kbenc pointer. This also handles BREAK, CTRL-C, CAPS LOCK etc.

RDKEYBin:
	move.l	VAR.CTLflg(a3),VAR.ARbuf(a3) ; set ARbuf to scancode+SH/CT/ALT
	move.l	a3,-(a7)	; save A3 b/c ip.kbrd smashes it!
	move.w	$150,a0		; ip.kbrd
	jsr	$4000(a0)
	move.l	(a7)+,a3	; restore A3

RDKEYBXL:
	btst.b	#0,KEY_STATUS	;  more chars to read?
	bne	kbl		; (can happen?)

RDKEYBX:
	tst.b	VAR.ARbuf+3(a3)	; key still held down?
	sne	d5		; if yes, set D5
; NOTE: only bit 3 significant (not bit 4 as Minerva doc says!)
	move.w	$152,a3		; ip.kbend; handle auto-repeat and finish up
	jsr	$4000(a3)

RDKEYBR:
	movem.l	(a7)+,rkeyreg
	rts

;; debugging code

	GENIF	DEBUG = 1

; Display variables from VAR.KEYraw to VAR.KEYdwc

DBvars	movem.l	d0-d2/a1,-(a7)
	moveq	#VAR.KEYdwk-VAR.KEYraw-1,d2
	lea	VAR.KEYraw(a3),a1
	move.w	#$2000,d1
DBvlp	move.b	(a1)+,d1
	bsr.s	DBBYTE
	subq.w	#1,d2
	bne	DBvlp
	move.w	#$0A00,d1
	move.b	(a1)+,d1
	bsr.s	DBBYTE
	movem.l	(a7)+,d0-d2/a1
	rts

; Display one byte (D1.B) in hex followed by character in D1 bits 8-15

DBBYTE	movem.l	d0-d3/a0-a2,-(a7)
	subq.l	#4,a7
	move.l	a7,a0		; room for 4 characters
	move.w	#3,-(a7)	; but we only use 3
	bsr.s	dnibble		; store hex digits
	bsr.s	dnibble
	rol.w	#8,d1
	move.b	d1,(a0)+	; store trailing character
	suba.l	a0,a0		; use channel 0 or 1
	move.l	a7,a1
	move.w	$d0,a2		; UT.MTEXT
	jsr	(a2)
	addq.l	#6,a7
	movem.l	(a7)+,d0-d3/a0-a2
	rts

; convert one nibble to hex digit

dnibble	ror.b	#4,d1
	moveq	#$0f,d0
	and.b	d1,d0
	cmpi.b	#9,d0
	bls.s	dnib1
	addq.b	#7,d0
dnib1	addi.b	#'0',d0
	move.b	d0,(a0)+
	rts

	ENDGEN

;; JB: following code is redundant and now handled by ip.kbrd

; key ind d1.w, check for special keys, insert into keyq
; unlike Minerva d1 is always word=code:8,ALT:8

	GENIF   0 = 1		; should not generate this anymore!

q68kbinch:		
	MOVEA.L	$4C(A6),A2	; SV.KEYQ
	cmp.w	sv_cqch(a6),d1  ***cant work, swapped
**	beq.s	ctlc	*** needs adapting
	sf	sv_scrst(a6)	  unfreeze screen
; tests for special cases
	cmpi.w	#$E000,d1	; CAPS?
**	beq	caps    *** needs fixing
	cmpi.w	#$F900,d1	; <CTL><F5>? (scroll lock)
	beq.s	frez
; 
	move.w	d1,sv_arbuf(a6) store char in the autorepeat buffer
	
	cmp.b	#255,d1   is it a two-byte code?
	bne.s	in1
	move.w	$de,a3		;  io.qtest
	jsr	(a3)	  how many bytes are left? (nb only d1.b zapped)
	subq.w	#2,d2	  are they enough?
	blt.s	autorld   no, don't put the character in
	st	d1		  reset the alt code
	
	bsr.s	ins2	  put the escape in the queue
in1	lsr.w	#8,d1	  get the second code

ins2	move.w	$e0,a3		; io.qin
	jsr	(a3)	  put it in the queue and return
autorld
	move.w	sv_ardel(a6),sv_arcnt(a6) reload the auto-rept counter
	rts

frez:
	not.b	sv_scrst(a6)	  toggle freeze flag
rts0
	rts

caps:
	not.b	sv_caps(a6)	  toggle caps lock flag byte
	lea	sv_csub(a6),a4	get capslock user routine address
isprog
	tst.l	(a4)	  is there some code there?
	beq.s	rts0	  no - not a good idea to call it...
	jmp	(a4)	  yes, call it and get out


* a2 keyboard q addr	
*ctlc
*	move.l	a0,-(sp)	  save a0
*	lea	-sd_end(a2),a0	find start of io definition block
*	tst.b	sd_curf(a0)	  should cursor in old wdw be visible?
*	bge.s	switch_q
*	jsr	sd_cure(pc)	  ensure cursor in old window is visible
*	lea	sd_end(a0),a2	restore a2
*switch_q
*	move.l	(a2),a2   switch to next queue
*	cmp.l	sv_keyq(a6),a2	is this the original queue?
*	beq.s	end_swit
*	tst.b	sd_curf-sd_end(a2) is this cursor active?
*	beq.s	switch_q	  no...
*	move.l	a2,sv_keyq(a6)	set new key queue pointer
*	clr.w	sv_fstat(a6)	  reset cursor flash cycle
*end_swit
*	move.l	sd_scrb-sd_end(a2),d1 have a look at the screen base here
*	add.w	d1,d1	  does it end with $0000 or $8000?
*	bne.s	offscr	  no - forget it
*	roxr.b	#1,d1
*	add.b	sv_mcsta(a6),d1 are we already on the indicated screen?
*	bpl.s	offscr	  yes - forget it
*	swap	d1
*	subq.b	#2,d1	  is it $xx020000 or $xx028000?
*	bne.s	offscr	  no - forget it
*****	bsr.s	ctlt	  switch over to that screen
*	move.b	d0,sv_mcsta(a6) and say that's what we're on
*offscr
*	move.l	(sp)+,a0	  restore a0
*	rts

        ENDGEN
	
; --------------------------------------------------------------
; convert key-stroke to ASCII or 'special' code

; Entry: VAR.ACTkey and CTL/SHF/ALT flags set
; Exit : D0.L: -2 special code, 0 normal code, +2 ignore code
;	 D1.W: ASCII code or special code

KEY_conv:
;;	movem.l	d0/a0,-(a7)	; redundant

	clr.b	VAR.ASCkey(a3)	; clear the ASCII keycode

	moveq	#0,d0
	moveq	#0,d1		; initialise result
	move.b	VAR.ACTkey(a3),d0 ; get keycode key
	beq.s	KEY_convN	; exit if not alpha key
;; JB: should never occur, already tested by calling code
        move.l  VAR.KEYtab(a3),a1 ; base of keyboard table
	cmp.w   ktab_of_ct(a1),d0
	bcc.s	KEY_convN	; exit if out-of-bounds

	tst.b	VAR.RLSflg(a3)
	bne.s	KEY_conv0	; skip if a key-up event

; check for special-action non-ascii key-combinations

	tst.b	VAR.CTLflg(a3)	; CTRL?
	beq.s	key_conv0	; no, skip this section
	tst.b	VAR.ALTflg(a3)	; ALT?
	beq.s	KC_noalt
	addq.b	#1,d1		; bit 0 = CTRL/ALT set
KC_noalt:
	tst.b	VAR.SHFflg(a3)	; SHIFT?
	beq.s	KC_noshf
	addq.b	#2,d1		; bit 1 = CTRL/SHIFT set
KC_noshf:
;       move.l	VAR.KEYtab(a3),a0 ; KEYtab defaults
	move.b	0(a1,d0.w),d0	; get "unshifted" ASCII value
	cmpi.b	#' ',d0		; SPACE?
	beq.s	KC_spexit	; Yes, do special exit
	subi.b	#9,d0		; TAB?
	bne.s	KC_notab
	addq.b	#4,d1		; bit 2 = CTRL/TAB set
	bra.s	KC_spexit
KC_notab:
	subq.b	#10-9,d0	; test for ENTER
	bne.s	KEY_conv0	; if not TAB/ENTER, skip
	addq.b	#8,d1		; bit 3 = CTRL/ENTER set

KC_spexit:
	moveq	#-2,d0;		'special' exit
	rts

; No valid keypress, signal 'ignore this return code'
KEY_convN:
	moveq	#2,d0
	rts

; --------------------------------------------------------------
; convert to ASCII

KEY_conv0:
        move.l  a1,a0           ; default table
	tst.b	VAR.GFXflg(a3)	; try gfx
	beq.s	KEY_conv1
	adda.w	ktab_of_gr(a1),a0 ; adjust for ALT-Gr chars
	move.b	VAR.ACTkey(a3),d0 ; get keycode key
	move.b	0(a0,d0.w),d1	; convert to ASCII value
	bne.s	KEY_conv6	; branch if an OK char
	clr.b	VAR.GFXflg(a3)

KEY_conv1:
        move.l  a1,a0           ; default table
	tst.b	VAR.CTLflg(a3)	; try control
	beq.s	KEY_conv2
	adda.w	ktab_of_ct(a1),a0 ; adjust for control chars

KEY_conv2:
	tst.b	VAR.MODflg(a3)	; test the weird flag
	beq.s	KEY_conv2a	; nope...
	cmpi.l	#AWKCOD,d0	; the weird awkward key?
	bne.s	KEY_conv5	; nope... ignore shift & numlock
	move.l	#AWKASC,d0	; be specific with awkward key
	bra.s	KEY_conv8

KEY_conv2a:
	move.b	VAR.ACTkey(a3),d0 ; get keycode key
	adda.w  ktab_of_sh(a1),a0 ; pre-adjust for shifted chars
	move.b	0(a0,d0.w),d0	; convert to ASCII value
	tst.b	VAR.SHFflg(a3)  ; SHIFT?
	sne.b	d1              ; set D1
	cmpi.b	#'.',d0
	beq.s	KEY_conv3	; numeric
	cmpi.b	#'0',d0
	blt.s	KEY_conv4	; not numeric
	cmpi.b	#'9',d0
	bgt.s	KEY_conv4	; not numeric

KEY_conv3:
	tst.b	VAR.NLKflg(a3)	; try numlock
	beq.s	KEY_conv4	; nope...
	not.b	d1

KEY_conv4:
	tst.b	d1
	bne.s	KEY_conv5
	suba.w	ktab_of_sh(a1),a0 ; unadjust for shifted chars

KEY_conv5:
	move.b	VAR.ACTkey(a3),d1 ; get keycode key
	move.b	0(a0,d1.w),d1	; convert to ASCII value

KEY_conv6:
	tst.b	SV_CAPS(a6)	; check for CAPS lock
	beq.s	KEY_conv8
	cmp.b	#'a',d1		; check for lower case
	blo.s	KEY_conv7
	cmp.b	#'z',d1
	bhi.s	KEY_conv7
	sub.b	#32,d1		; change to upper case
	bra.s	KEY_conv8

KEY_conv7:
	cmp.b	#128,d1		; check lower case accented
	blo.s	KEY_conv8	;; should be BLO/BCS???
	cmp.b	#139,d1
	bhi.s	KEY_conv8	;; should be BHI???
	add.b	#32,d1		; change to upper case

KEY_conv8:
	move.b	d1,VAR.ASCkey(a3) ; store new key
	tst.b	VAR.ALTflg(a3)	; check alt flag
	beq.s	KEY_convA	; no ALT
	cmpi.b	#$C0,d1		; test for cursor/caps keys
	blo.s	KEY_conv9	; 
	cmpi.b	#$e8,d1		; test for cursor/caps keys
	bhs.s	KEY_conv9
	ori.b	#1,d1		; ALT on cursor keys means bit 0 set
	move.b	d1,VAR.ASCkey(a3) ; reset VAR.ASCkey
	bra.s	KEY_convA

KEY_conv9:
	lsl.w	#8,d1		; move code to bits 8-15
	st	d1		; signal ALT code in bits 0-7

KEY_convA:
	clr.b	VAR.MODflg(a3)	; clear the weird flag

KEY_convX:
	moveq	#0,d0		; signal 'normal valid code'

;;	movem.l	(a7)+,d0/a0 redundant
	rts

; -----------------------------------------------------------------------------
; The 'keyboard encode' routine is called from ip.kbenc vector via the sx.kbenc
; pointer. On a standard QL, this does most of the conversion from 'raw' key
; codes to ASCII. However, we have already done this in the KEY_conv routine
; above. What remains to be done is taking different returns according to the
; result of the conversion:
; - Direct return: take special action (BREAK, CTRL-TAB, CTRL-ENTER, etc)
; - Return addr+2: normal ASCII code
; - Return addr+4: invalid scan code or 'compose' key, ignore this
;
; Since D0 has already been set up by KEY_conv to hold -2, 0 or +2 respectively
; in these cases, the remaining code will be quite straightforward. We do have
; to check though for CAPS LOCK and CTRL-F5, which perform special functions 
; but do have valid ASCII codes (which KEYROW emulation depends on).

Q68kbenc:
	tst.l	d0		; valid ASCII code?
	bne.s	Q68kb_2		; no, skip
	cmpi.w	#$00E0,d1	; CAPS LOCK?
	beq.s	Q68kb_cap	; Yes, make 'special' return
	cmpi.w	#$00F9,d1	; CTRL-F5?
	beq.s	Q68kb_cf5	; Yes, make 'special' return
Q68kb_2:
	addq.l	#2,d0           ; D0 now holds 0, 2 or 4
	add.l	d0,(a7)         ; Set return address accordingly
	rts                     ; and exit back to Minerva to handle the key
Q68kb_cap:
	moveq	#10,d1		; 'special' code for CAPS LOCK
	rts
Q68kb_cf5:
	moveq	#5,d1		; 'special' code for CTRL-F5
	rts

; --------------------------------------------------------------
;  enter key into keydown list

KR_ENTR:
	movem.l	d0-d3/a0-a1,-(a7)

	move.b	VAR.ACTkey(a3),d1   ; active key scancode

	moveq	#0,d0
	move.b	VAR.KEYdwc(a3),d0   ; count of keys down
	beq.s	KR_EADD             ; if empty, add immediately

	cmpi.b	#16,d0              ; buffer full?
	beq.s	KR_EXIT             ; yes, forget about it

	lea	VAR.KEYdwk(a3,d0.w),a0 ; end of list
	bra.s	KR_EBEG             ; enter loop

KR_ELUP:
	cmp.b	-(a0),d1
	beq.s	KR_EXIT		; exit if already in list

KR_EBEG
	dbra	d0,KR_ELUP          ; loop for all entries

KR_EADD:
	moveq	#0,d0
	move.b	VAR.KEYdwc(a3),d0
	move.b	d1,VAR.KEYdwk(a3,d0.w)	; put in list
	move.b	VAR.ASCkey(a3),d1
	move.b	d1,VAR.KEYdwa(a3,d0.w)	; put in list
; 	addi.b	#1,VAR.KEYdwc(a3) 	; increment count
	addq.b	#1,VAR.KEYdwc(a3) 	; a bit quicker and shorter...

	bsr.s	KR_DOIT

KR_EXIT:
	movem.l	(a7)+,d0-d3/a0-a1
	rts

; --------------------------------------------------------------
;  remove key from keydown list

KR_REMV:
	movem.l	d0-d3/a0-a1,-(a7)

	move.b	VAR.ACTkey(a3),d1   ; active key code

	moveq	#0,d0
	move.b	VAR.KEYdwc(a3),d0   ; get key count
	beq.s	KR_RXIT             ; if zero, exit immediately

	lea	VAR.KEYdwk(a3,d0.w),a0 ; point to last entry
	bra.s	KR_RBEG             ; enter loop

KR_RLUP:
	cmp.b	-(a0),d1
	beq.s	KR_RDEL             ; found entry

KR_RBEG
	dbra	d0,KR_RLUP          ; loop
	bra.s	KR_RXIT             ; not found, exit

KR_RDEL:
;	subi.b	#1,VAR.KEYdwc(a3) 	; decrement count
	subq.b	#1,VAR.KEYdwc(a3) 	; decrement count
	moveq	#0,d0
	move.b	VAR.KEYdwc(a3),d0
	move.b	VAR.KEYdwk(a3,d0.w),(a0)	; move last entry
; gwass does not like this, use workaround	
;	move.b	VAR.KEYdwa(a3,d0.w),(VAR.KEYdwa-VAR.KEYdwk)(a0)
	move.b	VAR.KEYdwa(a3,d0.w),vdwak(a0)
	clr.b	VAR.KEYdwk(a3,d0.w)	; delete last entry
	clr.b	VAR.KEYdwa(a3,d0.w)

	bsr.s	KR_DOIT             ; update keyrow list

KR_RXIT:
	movem.l	(a7)+,d0-d3/a0-a1
	rts

; --------------------------------------------------------------
;  set keyrow for all keys in keydown list

KR_DOIT:
	movem.l	d0-d3/a0-a1,-(a7)

	lea	VAR.KEYraw(a3),a1
	clr.l	(a1)+		; clear KEYROW entries
	clr.l	(a1)+

	moveq	#0,d0
	move.b	VAR.KEYdwc(a3),d0
	beq.s	KEY_KR1

	lea	VAR.KEYdwa(a3,d0.w),a0
	bra.s	KR_DBEG

KR_DLUP:
	moveq	#0,d1
	move.b	-(a0),d1            ; ascii code

	lea	QLRAWKEY(pc),a1
	moveq	#0,d2
	move.b	0(a1,d1.w),d2	; get row and bit number

	move.l	d2,d1		; save for later

	move.l	d2,d3
	lsr.l	#3,d3		; extract row number -> D3
	and.w	#$7,d3
	and.b	#$07,d2		; extract bit number -> D2

	lea	VAR.KEYraw(a3),a1
	bset	d2,0(a1,d3.w)	; set the bit in KEYROW

	lsr.b	#6,d1		; set SHFT/CTL from table
	move.b	VAR.KEYraw+7(a3),d3
	andi.b	#$F8,d3
	or.b	d3,d1
	move.b	d1,VAR.KEYraw+7(a3)

KR_DBEG
	dbra	d0,KR_DLUP

	bra.s	KEY_KR3		; set ALT from flag value

; if keydown list empty set KEYROW for SHF/CTL/ALT keys from flags

KEY_KR1:
	move.b	VAR.KEYraw+7(a3),d1
	andi.b	#$F8,d1

	tst.b	VAR.SHFflg(a3)
	beq.s	KEY_KR2

	bset	#0,d1

KEY_KR2:
	tst.b	VAR.CTLflg(a3)
	beq.s	KEY_KR3

	bset	#1,d1

KEY_KR3:
	tst.b	VAR.ALTflg(a3)
	beq.s	KEY_KR4

	bset	#2,d1

KEY_KR4:
	move.b	d1,VAR.KEYraw+7(a3)

KR_DXIT:
	movem.l	(a7)+,d0-d3/a0-a1
	rts

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;;DO_BREAK:
* Minerva specific.... 
;;	bset	#4,sx_event(a0)
;;	CLR.B	VAR.ASCkey(A3)	; reset key event
;;	bra	KEY_convA

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  Polled interrupt routine to read the keyboard
;  enters with a6=sys vars, a3=our (keyboard) vars

;; Redundant now; RDKEYB is called directly from polled list

;;POLL_SERver:
;;	move.l  sv_keyq(a6),d0   fetch ptr to current keyboard queue
;;	beq.s   POLL_EXIT        no queue, don't bother reading the IPC 
;;	bsr	RDKEYB		;  read keys, translate, stuff to q
;;POLL_EXIT:
;;	rts

; -------------------------------------------------------------------
; IPC keyboard direct read command emulation
; This uses the MT.IPCOM front-end linked list feature in Minerva
; Entry: D0.B IPC command (we only process type 9)
;	 D5.L parameter length (ignored, we only use bits 0-3)
;	 D7.B parameter count (should be 1)
;	 A0.L pointer to link (in our case VAR.IPClnk)
;	 A3.L pointer to parameter (KEYROW argument)
; Exit:	 D1.B return code (KEYROW bits)
;	 Returns at return address +2 if valid command, else direct return.

KR_IPCem:
	cmpi.b	#9,d0		; IPC KEYROW command?
	bne.s	KR_IPCrt	; no, return immediately
	cmpi.b	#1,d7		; sanity check; parameter count should be 1
	bne.s	KR_IPCrt	; just to be on the safe side...
	addq.l	#2,(a7)		; okay, we'll do it so take second return addr
	moveq	#7,d0
	and.b	(a3),d0		; D0 now holds keyrow number
	move.b	VAR.KEYraw-VAR.IPClnk(a0,d0.w),d1 ; get KEYROW byte
KR_IPCrt:
	rts			; Done

; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
;  BASIC extensions not fully implemented yet

	end
