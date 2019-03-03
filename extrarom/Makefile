all:	q68hwde_rom q68hwuk_rom q68hwus_rom
#all:	q68hw_rom



q68hwde_rom: q68hw.asm q68 SV.inc sx.inc
	echo "q68_keyc equ	49" > userdefs
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qmac;'q68hw' : kill_uqlx" || true
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qlink;'-WITH link -CRF' : kill_uqlx" || true
	cp LINK_exe q68hwde_rom

q68hwuk_rom: q68hw.asm q68 SV.inc sx.inc
	echo "q68_keyc equ	44" > userdefs
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qmac;'q68hw' : kill_uqlx" || true
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qlink;'-WITH link -CRF' : kill_uqlx" || true
	cp LINK_exe q68hwuk_rom

q68hwus_rom: q68hw.asm q68 SV.inc sx.inc
	echo "q68_keyc equ	1" > userdefs
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qmac;'q68hw' : kill_uqlx" || true
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qlink;'-WITH link -CRF' : kill_uqlx" || true
	cp LINK_exe q68hwus_rom




