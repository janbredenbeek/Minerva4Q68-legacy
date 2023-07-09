all:	q68hw_rom q68scr_rel

q68hw_rom: q68hw.asm q68 SV.inc sx.inc bv.inc err.inc mt.inc vect.inc
	cp -p q68hw.asm q68hw_asm
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qmac;'q68hw -errors' : kill_uqlx" || true
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qlink;'-WITH link -CRF' : kill_uqlx" || true
	cp LINK_bin q68hw_rom

q68scr_rel: q68scr.asm q68 SV.inc sx.inc bv.inc err.inc mt.inc vect.inc
	cp -p q68scr.asm q68scr_asm
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qmac;'q68scr -errors' : kill_uqlx" || true
	qm -f uqlxrc -s "tk2_ext: data_use win1_: ew ccc1_qlink;'-WITH link -CRF' : kill_uqlx" || true
	cp LINK_bin q68hw_rom
