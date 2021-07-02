Minerva4Q68
===========

Description
-----------

A port of the Minerva operating system for the Q68 (Sinclair QL clone).

The Minerva operating system was originally designed as a replacement ROM operating system for the Sinclair QL computer, currently licenced under GPLv3. This port is aimed at the Q68, an FPGA-based replacement board for the QL. It is not intended as a serious alternative for the SMSQ/E OS supplied with the Q68, as SMSQ/E is far more extensive and better suited to support the Q68 hardware than the 48K ROM-based Minerva. We just provide this port to demonstrate the Q68's ability to run 'oldskool' ROM images, give Q68 users the Minerva look and feel, and maybe provide an opportunity to run badly written software that doesn't run on SMSQ/E (but chances are big that this software won't run on Minerva either).

The current Minerva build is based on v1.98, with a few modifications to run successfully on the Q68.


INSTALLATION:
-------------

The appropriate ROM image Q68_??ROM.SYS should be renamed to Q68_ROM.SYS and copied to the root directory of a FAT32-formatted SDHC card. The Q68 will then load this image and boot into the Minerva operating system.

The 80K ROM images contain the Minerva operating system, a keyboard driver specific for US, UK and DE (German) keyboard layouts, and a SDHC card driver. Note that in the current build the MDV driver is still present but disabled since there is no MDV hardware in the Q68.

By default, the devices win1_ and win2_ will be mapped to container files QLWA.WIN on SDHC drives 1 and 2 respectively. If present, the devices qub1_ and qub2_ will be mapped to Qubide container files QL_BDI.BIN on SDHC drives 1 and 2 respectively. This can be changed by configuring the Q68_ROM.SYS file (see below).

By combining the keyboard and SD-card driver, the size of the ROM image has been reduced from 96K to 80K. The remaining 16K may be used to add another 16K extension ROM image, e.g. Toolkit II. This additional extension ROM will be placed at location $14000, after the Q68_ROM.SYS image. To build a complete 96K image, the extension ROM should be placed in the ~/q68 directory under the name x14000_rom and a rebuild done. Alternatively, the Q68_ROM.SYS image may be extended by issuing the following commands in an emulated QDOS or SMSQ/E environment:
~~~
base=RESPR(96*1024)\
LBYTES Q68_ROM.SYS,base\
LBYTES extension_rom_image,base+80*1024\
RENAME Q68_ROM.SYS,Q68_ROM.ORG\
SBYTES Q68_ROM.SYS,base,96*1024
~~~
and then the Q68_ROM.SYS file must be copied to a FAT32-formatted SDHC card. Please note that the Q68 requires the files on this card to lie in *contiguous* sectors, so if there are already any files on the card it's strongly recommended to save these, then reformat the card, and then write all files back at once.

If you have extension ROMs that insist on being placed in the $C000 slot, you may include them by placing the image in the ~/q68 directory under the name xc000_rom. The keyboard and SD-card driver images will then be relocated to the $10000-$17FFF area and linked in after the xc000_rom extension. Note that you may include an extension ROM either at $C000 or $14000, but not at both locations as the total size of Minerva plus Q68 drivers plus extension ROM is limited to 96K!

As an alternative to loading the ROM image at startup, we now provide a boot loader which allows the Minerva system to be loaded from within a running SMSQ/E system. This avoids the need to use a separate FAT32-formatted SDHC card, and allows you to boot Minerva with a single LRESPR command. The boot loader Min4Q68ldr.bin is just 32 bytes and must be followed by the Q68_ROM.SYS image itself. Using 'make lrespr' after building the Q68_ROM.SYS image will create a Min4Q68_rext file which may be copied to a QDOS WIN container. Alternatively, you may create this file from within a QDOS-compatible system itself by issuing the following commands:
~~~
size=96*1024+32
base=RESPR(size)
LBYTES Min4Q68ldr.bin,base
LBYTES Q68_ROM.SYS,base+32
SBYTES Min4Q68_rext,base,size
~~~
CONFIGURATION:
--------------

The devices win1_ to win8_ and qub1_ to qub8_ can be configured to be mapped to any \*.WIN (QLWA format) or \*.BIN (Qubide format) container file by using the CONFIG or MENUCONFIG program on the Q68_ROM.SYS file. You MUST use a V2 capable version of these programs. Suitable CONFIG programs can be found on http://www.dilwyn.me.uk/config/index.html.


Current issues:
---------------

- The SD-card driver requires a CARD_INIT 2 command to use the SD card in slot 2; other SD-card related commands are presently not implemented.
- The maximum amount of RAM supported is limited to 16MB, as the slave block system's structure currently prevents supporting more RAM.
- The serial port and network port of the Q68 are not supported.
- Building instructions need to be added (work in progress).


Contributors:
-------------

- Minerva operating system by Laurence Reeves;
- Keyboard driver: Richard Zidlicky, Jan Bredenbeek
- SDHC device driver: Wolfgang Lenerz

Version history:
----------------

- May 2018: support for US and UK keyboards, RAM test limited to 16MB to avoid problems with slave block system
- April 2019: improved keyboard driver, now only compatible with Minerva
- May 2019: Patch included for LBYTES bug over network (contributed by Marcel Kilgus)
- June 2021: Combined keyboard and SD-card drivers in one single ROM image, leaving 16K available for other extension ROMs. Patched SD-card driver for stale TRAP #14 instruction left over (from debugging?)