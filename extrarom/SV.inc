* SYS.SV system variable definitions
        nolist

SV_IDENT equ $00  W identification word
*spare   equ $02  W
SV_CHEAP equ $04  L base of common heap area
SV_CHPFR equ $08  L first free space in common heap area
SV_FREE  equ $0C  L base of free area
SV_BASIC equ $10  L base of basic area
SV_TRNSP equ $14  L base of transient program area
SV_TRNFR equ $18  L first free space in transient program area
SV_RESPR equ $1C  L base of resident procedure area
SV_RAMT  equ $20  L top of ram (+1)

*spare   equ $24  W*5 spare

SV_RAND  equ $2E  W random number
SV_POLLM equ $30  W count of poll interupts missed
SV_TVMOD equ $32  B 0 if not TV display
SV_SCRST equ $33  B screen status (0 = active)
SV_MCSTA equ $34  B display mode of current job 0/8 mode4/mode8
SV_PCINT equ $35  B current value of PC interrupt register
*spare   equ $36  B
SV_NETNR equ $37  B network station number

SV_I2LST equ $38  L pointer to list of interrupt 2 drivers
SV_PLIST equ $3C  L pointer to list of polled tasks
SV_SHLST equ $40  L pointer to list of scheduler tasks
SV_DRLST equ $44  L pointer to list of device drivers
SV_DDLST equ $48  L pointer to list of directory device drivers
SV_KEYQ  equ $4C  L pointer to a keyboard queue
SV_TRAPV equ $50  L pointer to the trap redirection table

* pointers to the resource management tables
* the slave block tables have 8 byte entries, the others 4 byte entries

SV_BTPNT equ $54  L pointer to most recent slave block entry
SV_BTBAS equ $58  L pointer to base of slave block table
SV_BTTOP equ $5C  L pointer to top of slave block table

SV_JBTAG equ $60  W current value of Job tag
SV_JBMAX equ $62  W highest current Job number
SV_JBPNT equ $64  L pointer to current Job table entry
SV_JBBAS equ $68  L pointer to base of Job table
SV_JBTOP equ $6C  L pointer to top of Job table

SV_CHTAG equ $70  W current value of channel tag
SV_CHMAX equ $72  W highest current channel number
SV_CHPNT equ $74  L pointer to last channel checked
SV_CHBAS equ $78  L pointer to base of channel table
SV_CHTOP equ $7C  L pointer to top of channel table, and extended sysvars

SV_FRBL  equ $80  L interrupt level release memory linked list (SMS2)
*spare?  equ $84  B
*        equ $85  B set to $FF by ptrgen if this IS a QL!
*spare?  equ $86  W

SV_CAPS  equ $88  B caps lock 0=off $FF=on
*spare   equ $89  B (though people may overwrite as above was defined as W!)
SV_ARBUF equ $8A  W autorepeat buffer
SV_ARDEL equ $8C  W autorepeat delay
SV_ARFRQ equ $8E  W autorepeat 1/freq
SV_ARCNT equ $90  W autorepeat count
SV_CQCH  equ $92  W keyboard change queue character code (can be + ALT!)
SV_WP    equ $94  W microdrive write protect (1st byte) IPC P26 input
SV_SOUND equ $96  W sound status (only 1st byte used?)
SV_SER1C equ $98  L receive  channel 1 queue address
SV_SER2C equ $9C  L receive  channel 2 queue address
SV_TMODE equ $A0  B ZX8302 transmit mode (includes baudrate)
*spare   equ $A1  B
SV_CSUB  equ $A2  L Subroutine to jump to on CAPSLOCK (can only reach + 32767!)
SV_TIMO  equ $A6  W Timeout for switching transmit mode
SV_TIMOV equ $A8  W Value of switching timeout (two characters)
SV_FSTAT equ $AA  W flashing cursor count (silly if > about 16!)

SV_PROGD equ $AC  L to $60 byte extension, old prog default string + QLIB_USE
SV_DATAD equ $B0  L to data default string, this -$24 = new PROGD
SV_DESTD equ $B4  L to dest default string, this is above + $24
SV_THING equ $B8  L THING list

*spare   equ $BC  W*25

SYS_KLNK equ $E8  L pointer to keyboard linkage blok (taken from SMSQ/E)

SV_MDRUN equ $EE  B which drive is running?
SV_MDCNT equ $EF  B microdrive run-up run-down counter
SV_MDDID equ $F0  B*8 drive ID*4 of each microdrive
SV_MDSTA equ $F8  B*8 status 0= no pending ops

SV_FSDEF equ $100 L*16 pointers to file system physical definition
SV_FSLST equ $140 L pointer to list of file channel definitions

SV_TRAN  equ $144 B key translation off(0) or on(1)
SV_ICHAR equ $145 B compose char workspace
SV_TRTAB equ $146 L pointer to key translation tables
SV_MGTAB equ $14A L pointer to message table
DAYTAB   equ $1C    ERR. for names of days
MONTAB   equ $1D    ERR. names of months

SV_TURB1 equ $154 L? used by TURBO
SV_TURB2 equ $156 L?
SV_TURB3 equ $15E W Length of file name!!!!
SV_TURB4 equ $160 B*41 file name!!!!!!
* TASKMASTER uses $154 L*4

SV_STACB equ $180 L*192 bottom of stack
SV_STACT equ $480   big stack - no check

SV_TRAPO equ 2*($28+2) offset of trap vector table from (SV_TRAPV)

SV.IDENT equ $D254 green, red, blue and black, with flash bits

* device driver definitions (for the driver's own pseudo system vars)

SV_LXINT equ $00  L link to next external interrupt service
SV_AXINT equ $04  L address of external interrupt service
SV_LPOLL equ $08  L link to next polling interrupt service
SV_APOLL equ $0C  L address of polling interrupt service
SV_LSCHD equ $10  L link to next scheduler task
SV_ASCHD equ $14  L address of scheduler task
SV_LIO   equ $18  L link to next IO driver
SV_AIO   equ $1C  L address of input/output routine
SV_AOPEN equ $20  L address of channel open routine
SV_ACLOS equ $24  L address of channel close routine

        list
