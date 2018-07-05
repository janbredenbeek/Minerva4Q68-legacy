# make all variants of roms, most real work is done in uqlx
all:    xrom
	ruby $(HOME)/ruby/mmake
	echo y | qm -r 4096 -f uqlxrc -s "lrun win1_BOOT"
	cp m/MINERVA_ROM minervax_rom
	truncate --size="%16384" minervax_rom
	cat minervax_rom extrarom/q68hwde_rom >minxx_rom
	truncate --size="%16384" minxx_rom
	cat minxx_rom wl/minv.dv3  >minxxx_rom
	truncate --size="%16384" minxxx_rom
	cp minxxx_rom Q68_DEROM.SYS
	cat minervax_rom extrarom/q68hwuk_rom >minxx_rom
	truncate --size="%16384" minxx_rom
	cat minxx_rom wl/minv.dv3  >minxxx_rom
	truncate --size="%16384" minxxx_rom
	cp minxxx_rom Q68_UKROM.SYS
	cat minervax_rom extrarom/q68hwus_rom >minxx_rom
	truncate --size="%16384" minxx_rom
	cat minxx_rom wl/minv.dv3  >minxxx_rom
	truncate --size="%16384" minxxx_rom
	cp minxxx_rom Q68_USROM.SYS
	cp Q68_DEROM.SYS ~/.romdir
	cp minervax_rom ~/.romdir

test:	all
	qm -r 4096 -o Q68_DEROM.SYS -f uxtest -b "paper#2,2:cls#2:pause 100:kill_uqlx 0"

origx:  xrom
	cat min198orig.rom ~/qdos/minerva/extrarom/q68hw_rom >minorigx_rom
	truncate --size="%16384" minorigx_rom
	cat minorigx_rom wl/mnrv_dv3  >minorigxx_rom
	truncate --size="%16384" minorigx_rom

xrom:
	cp -u m/inc/q68 extrarom
	make -C extrarom

clean:
	rm -f m/*/*_rel
	rm -f m/*/lib

sources:
	(cd ..; rm -rf ~/tmpx/q68; cp -dpR q68 ~/tmpx; \
	 cd ~/tmpx/q68; rm -rf *.zip *.rom *_rom M.orig m/ROM/map m/MINERVA_ROM Q68_ROM.SYS; \
	 rm -rf wl-old; \
	 find -iname "*_REL" -o -iname "*_list" -o -iname "lib" |xargs rm -f; \
	 cd ~/tmpx; tar jcf ~/tmpx/q68-minerva.tar.bz2 q68 )

upl: sources
	{ \
	 set -e; \
	 t=`date +"%s"`; \
	 cd ~/tmpx/; mv q68-minerva.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 dropbox_uploader upload q68-minerva-$$t.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 link=`dropbox_uploader share q68-minerva-$$t.tar.bz2` ; \
	 echo share link $$link ; \
	}

smail: sources
	{ \
	 set -e; \
	 t=`date +"%s"`; \
	 cd ~/tmpx/; mv q68-minerva.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 dropbox_uploader upload q68-minerva-$$t.tar.bz2 q68-minerva-$$t.tar.bz2 ; \
	 link=`dropbox_uploader share q68-minerva-$$t.tar.bz2` ; \
	 echo Hi Peter, der link ist $$link | mutt pgraf -s "Minerva Sourcen `date` - $$t" ; \
	 echo share link $$link ; \
	}

mail:	all
	(mutt pgraf -s "Minerva ROM `date`" -a Q68_ROM.SYS)
