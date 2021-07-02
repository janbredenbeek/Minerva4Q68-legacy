### Makefile for Minerva4Q68 ###

# Uncomment the line which applies to your keyboard layout

KBLANG = US

# KBLANG=UK
# KBLANG=DE

all:    xrom
	ruby $(HOME)/ruby/mmake
	echo y | qm -r 4096 -f uqlxrc -s "lrun win1_BOOT"
	cp m/MINERVA_ROM minervax_rom
	truncate --size="%16384" minervax_rom

# insert your favourite extension ROM here which will be linked in BEFORE
# the Q68 keyboard and SD-card drivers.
# also for ROMs that insist on being placed in the $C000-$FFFF area.
# The name must be xc000_rom

	if [ -f xc000_rom ]; then cat minervax_rom xc000_rom > minxx_rom; else cp minervax_rom minxx_rom; fi
	truncate --size="%16384" minxx_rom

#	cat minervax_rom extrarom/q68hw_rom >minxx_rom
#	truncate --size="%16384" minxx_rom

# prepare Q68 keyboard and SD-card driver ROMs

	cat q68hw_rom wl/minv.dv3 > q68hwx_rom
	truncate --size="%16384" q68hwx_rom

# append any other extension ROMs which will be placed at $14000-$17FFF
# and linked in after the q68hw ROM. Name must be x14000_rom
# NOTE: You can have ONLY ONE 16K extension ROM, either at $C000 or $14000!

	if [ -f x14000_rom ]; then cat minxx_rom q68hwx_rom x14000_rom > Q68_ROM.SYS ; else cat minxx_rom q68hwx_rom > Q68_ROM.SYS ; fi

#	cp minxxx_rom Q68_ROM.SYS
#	cp minxx_rom ~/.romdir

# target for loading Q68_ROM.SYS from SMSQ/E so you can LRESPR it without
# having to change SD-cards

lrespr: all
	cat Min4Q68ldr.bin Q68_ROM.SYS > Min4Q68_rext

test:	all
	qm -r 4096 -o minxx_rom -f uxtest -n -b "paper#2,2:cls#2:pause 100:kill_uqlx 0"

origx:  xrom
	cat min198orig.rom extrarom/q68hw_rom >minorigx_rom
	truncate --size="%16384" minorigx_rom
	cat minorigx_rom wl/mnrv_dv3  >minorigxx_rom
	truncate --size="%16384" minorigx_rom

xrom:
	cp -u m/inc/q68 extrarom
	make -C extrarom
	cp extrarom/q68hw$(KBLANG)_rom q68hw_rom

clean:
	rm -f m/*/*_rel
	rm -f m/*/*_REL
	rm -f m/*/*_list
	rm -f m/*/lib

sources:
	(cd ..; rm -rf ~/tmpx/q68; cp -dpR q68 ~/tmpx; \
	 cd ~/tmpx/q68; rm -rf *.zip *.rom *_rom M.orig m/ROM/map m/MINERVA_ROM Q68_ROM.SYS; \
	 rm -rf wl-old; \
	 find -iname "*_REL" -o -iname "*_list" -o -iname "lib" |xargs rm -f; \
	 cd ~/tmpx; tar jcf ~/tmpx/q68-minerva.tar.bz2 q68 )

smail: sources
	{ \
	 set -e; \
	 t=`date +"%s"`; \
	 cd ~/tmpx/; mv q68-minerva.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 dropbox_uploader upload q68-minerva-$$t.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 link=`dropbox_uploader share q68-minerva-$$t.tar.bz2` ; \
	 echo Hi Peter, der link ist $$link | mutt pgraf -s "Minerva Sourcen `date` - $$t" ; \
	}

mail:	all
	(mutt pgraf -s "Minerva ROM `date`" -a Q68_ROM.SYS)
