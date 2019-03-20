* System variables extension
        nolist

sx_case  equ $00  L non-zero = user routine on CTRL/ALT/SHIFT/ENTER (C/A/S/E?)
sx_itran equ $04  L input tranlation routine
sx_otran equ $08  L output translation routine
sx_driv  equ $0C  L MM_RECHP is memory management driver, close entry point

sx_kbenc equ $10  L keyboard encoder routine
sx_ipcom equ $14  L linked list to front end MT.IPCOM calls
*spare   equ $18  L reserved (routine/table)
*spare   equ $1C  L reserved (routine/table)

sx_trn   equ $20  L default i/o translation table address
sx_msg   equ $24  L default message table address
sx_f0    equ $28  L default primary font
sx_f1    equ $2C  L default secondary font

sx_dspm  equ $30  B real display mode settings (dual screen)
sx_toe   equ $31  B turn off ehancements (bit 7 set, allow FORMAT + files open)
sx_event equ $32  B event byte. bit 4 = CTRL/space, 5=+ALT, 6=+SHIFT, 7=+both
sx_fstat equ $33  B cursor flash rate, size and colour RRRRSCCC
sx_kbste equ $34  B*12 special key remap table

sx_qdos  equ $40  B*4 returned by MT.INF, VER$(-2)
sx_basic equ $44  W+B*4 returned by VER$, VER$(0)
*spare   equ $4A  W*3 reserved

* Initial RAM based linkages
ip_poll  equ $50  L*2 00000000 IP_POLL
*        equ $58  L*6 BASE+$60 SD_SCHED BASE+$68 IP_SCHED 00000000 IO_SCAN
*        equ $70  L*4 BASE+$80 OD_SERIO OD_SEROP OD_SERCL
*        equ $80  L*4 BASE+$90 IO_SERQ  OD_PIPOP OD_PIPCL
sx_con   equ $90  L*4 BASE+$A0 OD_CONIO OD_CONOP OD_CONCL
*        equ $A0  L*4 00000000 OD_NETIO OD_NETOP OD_NETCL
*        equ $B0  L*8 00000000 DD_MDVIO DD_MDVOP DD_MDVCL MD_SLAVE 0 0 MD_FORMT
*        equ $D0  L,W,C*3 MD_END 3 'MDV'

* Final allignment bit
*spare   equ $D9  B*7 reserved

*        equ $E0 end of system extension

        list
