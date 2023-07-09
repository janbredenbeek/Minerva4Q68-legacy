***********************************
* Q68 screen extensions for Minerva
***********************************

* Use and distribution governed by GNU Public License v3
* 
* Changelog:
*
* 20230705 JB:
*   Start of work

        xdef    disp_mode,scr_base,scr_llen,scr_xlim,scr_ylim,rom_end
        
        include mincf
        include userdefs
        include sv.inc
        include sx.inc
        include bv.inc
        include err.inc
        include mt.inc
        include vect.inc
        include q68

        section q68screen

* SCR_BASE, SCR_LLEN, SCR_XLIM, SCR_YLIM functions

* These functions are now commonly found in environments which support
* screen resolutions higher than the original QL's 512x256x4 or 256x256x8.
* SCR_BASE: Returns base of screen buffer
*              $20000: QL screen 0, $28000 QL screen 1 (Minerva dual-screen)
*           $FE800000: Q68 extended modes (2-7)
*
* SCR_LLEN: Returns length of one screen line of pixels in bytes
*           QL mode 4 or 8: 128 bytes
*           Q68 mode 4 (1024x768x4): 256 bytes
*           (Other Q68 modes presently not implemented)
*
* SCR_XLIM, SCR_YLIM: Return display width and height in pixels
*
* On SMSQ/E, these functions have some issues:
*   - SCR_BASE returns a negative value for Q68 extended modes!
*   - The functions accept a channel as parameter, however this is ignored
*     (a pity, since channels may have a different screen base (dual-screen)
*      and often different window sizes)
* In order to remain compatible, we'll ignore the parameter for now...

* subroutine to get status of Q68 extended screen mode

get_dm  moveq   #mt.inf,d0
        trap    #1
        move.l  sv_chtop(a0),a4         ; get base of sx variables
        moveq   #1<<sx.q68m4,d0         ; test status of Q68 mode
        and.b   sx_dspm(a4),d0
        rts

* table containing values to be returned for scr_base, scr_llen, scr_x/ylim
* each entry two values for QL and Q68 extended mode respectively

scrtab: dc.w    2,$fe80         ; scr_base (msw only)
        dc.w    128,256         ; scr_llen
        dc.w    512,1024        ; scr_xlim
        dc.w    256,768         ; scr_ylim

scr_base:
        moveq   #0,d4
        bra.s   scr_ent
scr_llen:        
        moveq   #4,d4
        bra.s   scr_ent
scr_xlim:
        moveq   #8,d4
        bra.s   scr_ent
scr_ylim:
        moveq   #12,d4
scr_ent:
        bsr     get_dm          ; get status of hires mode bit
        lsr.w   #sx.q68m4-1,d0  ; move to bit 1
        lea     scrtab(pc,d0.w),a1 ; select first or second entry
        moveq   #0,d5
        move.w  (a1,d4.w),d5    ; get table entry
        moveq   #6,d1           ; ensure enough space on ri stack
        move.w  bv.chrix,a2
        jsr     (a2)
        move.l  bv_rip(a6),a1   ; ri stack pointer
        subq.l  #2,a1           ; two bytes needed
        move.w  d5,(a6,a1.l)    ; stack the result
        tst.w   d4              ; EQ for scr_base, NE for others
        seq     d4              ; d4.b is now -1 for scr_base, 0 for others
        bne.s   stk_word        ; jump if not scr_base
        subq.l  #2,a1           ; this needs a long word
        swap    d5
        move.l  d5,(a6,a1.l)    ; result is in msw, clear lsw
        moveq   #9,d0           ; RI.FLONG (minerva only!)
        moveq   #0,d7           ; REALLY NEEDED?
        move.w  ri.exec,a2
        jsr     (a2)            ; convert long to float (see remarks above!)
stk_word:
        move.l  a1,bv_rip(a6)   ; set stack
        addq.b  #3,d4           ; d4.b is now 2 for scr_base (float), 3 for
                                ; others (int) so correct type
        moveq   #0,d0           ; finish with no error
        rts

* High resolution 1024x768x4 for the Q68!
* Implemented the DISP_MODE command with a subset of the SMSQ/E version
* Currently, modes 0 (256x256x8), 1 (512x256x4) and 4 (1024x768x4) supported
* (sorry guys, implementing 65536-colour mode would require a total rewrite of
*  the screen drivers. If you need this, then better stick with SMSQ/E...
*  That said, it would have been nice if the Q68 had supported 8-colour mode
*  with higher resolution, which is fairly easy to implement. Also, 1024x768
*  might be difficult to read on modern LCD-type monitors where the native 
*  resolution is not an exact multiple of 1024x768. To this end, downscaling to
*  512x384 would be a good compromise. (e.g. DISP_MODE 6, but with 8 colours?
*  (end of feature request :-)))
*
* The 1024x768 mode is flagged by setting bit 4 of sx.dspm (which is reserved
* in the original Minerva). The parameters of each CON/SCR channel are modified
* accordingly, which is transparant to most TRAPs. The MT.DMODE trap will
* handle most of the hard work when changing the modes.
* Note that Minerva's dual-screen option is not available in 1024x768 mode, and
* attempting to switch to 1024x768 with dual screen enabled will generate an
* error.

disp_mode:
        move.w  ca.gtint,a2
        jsr     (a2)
        bne.s   dm_end
        subq.w  #1,d3
        bne.s   dm_bp           ; one integer parameter allowed
        move.w  (a6,a1.l),d4
        addq.l  #2,bv_rip(a6)
        tst.w   d4
        beq.s   dm_lores
        cmpi.w  #1,d4
        bne.s   dm_hires
; QL modes 0 or 1 requested
dm_lores:
        bsr     get_dm
        bclr    #sx.q68m4,sx_dspm(a4)
        lsl.w   #3,d4           ; now 0 or 8 for DISP_MODE 0/1
        moveq   #8,d1
        eor.b   d4,d1           ; flip bit 3 so DISP_MODE 0 -> MODE 8
        bra.s   dm_setmd
dm_hires:
        cmpi.w  #q68.dl4,d4     ; only 1024x768x4 accepted
        bne.s   dm_bp
        bsr     get_dm          ; get current display mode
        bne.s   dm_setmd        ; we're already in hi-res mode!
        move.w  a0,d0
        bpl.s   dm_nc           ; sorry, dual screen not supported in hi-res
        bset    #sx.q68m4,sx_dspm(a4) ; set hi-res bit
        moveq   #0,d1           ; clear d1 (atm irrelevant in hi-res mode)
; MT.DMODE will handle all the nitty-gritty work of clearing the screen,
; resetting windows and finally informing the hardware of the mode change
; This trap has been modified to handle the hi-res mode when bit 4 of sx_dspm
; has been set.
dm_setmd:
        moveq   #-1,d2          ; leave TV mode alone
        moveq   #mt.dmode,d0
        trap    #1              ; set mode
dm_end  rts

dm_bp:  moveq   #err.bp,d0      ; 'bad parameter' return
        rts
dm_nc   moveq   #err.nc,d0      ; 'not complete'
        rts
        
rom_end  equ      *
        
        end
        