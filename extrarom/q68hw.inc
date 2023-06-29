; *****************************
; Q68 extension rom definitions
; *****************************

*  linked in as poll routine, all variables stored rel a3
*  KEYBOARD variables

VAR.lxint    EQU        $00	; (long) original INT2 vector
VAR.axint    EQU	$04	; (long) address of EXT INT routine

;SV_LPOLL	EQU	$08	; (long) ptr to next link
				; (long) address of POLLed int routine



VAR.KEYtab   EQU	$3C	; (long) ptr to ASCII table

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
