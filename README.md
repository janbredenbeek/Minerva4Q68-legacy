Minerva4Q68
===========

Description
-----------

A port of the Minerva operating system for the Q68 (Sinclair QL clone).

The Minerva operating system was originally designed as a replacement ROM operating system for the Sinclair QL computer, currently licenced under GPLv3. This port is aimed at the Q68, an FPGA-based replacement board for the QL. It is not intended as a serious alternative for the SMSQ/E OS supplied with the Q68, as SMSQ/E is far more extensive and better suited to support the Q68 hardware than the 48K ROM-based Minerva. We just provide this port to demonstrate the Q68's ability to run 'oldskool' ROM images, give Q68 users the Minerva look and feel, and maybe provide an opportunity to run badly written software that doesn't run on SMSQ/E (but chances are big that this software won't run on Minerva either).

The current Minerva build is based on v1.98, with a few modifications to run successfully on the Q68.


INSTALLATION:
-------------

The Q68_ROM.SYS file should copied to the root directory of a FAT32-formatted SDHC card. The Q68 will then load this image and boot into the Minerva operating system.

The 80K ROM images contain the Minerva operating system, a keyboard driver for US, UK and DE (German) keyboard layouts, and a SDHC card driver. Note that in the current build the MDV driver is still present but disabled since there is no MDV hardware in the Q68.

The keyboard language may be set using the KBTABLE command, which has the telephone country code as parameter. Currently, the supported codes are US (1), UK (44), and German (49). The default is US; you may change this by editing the userdef file in the extrarom directory and rebuilding it.

By default, the devices win1_ and win2_ will be mapped to container files QLWA.WIN on SDHC drives 1 and 2 respectively. If present, the devices qub1_ and qub2_ will be mapped to Qubide container files QL_BDI.BIN on SDHC drives 1 and 2 respectively. This can be changed by configuring the Q68_ROM.SYS file (see below).

By combining the keyboard and SD-card driver, the size of the ROM image has been reduced from 96K to 80K. The remaining 16K may be used to add another 16K extension ROM image, e.g. Toolkit II. This additional extension ROM will be placed at location $14000, after the Q68_ROM.SYS image. To build a complete 96K image, the extension ROM should be placed in the ~/q68 directory under the name x14000_rom and a rebuild done. Alternatively, the Q68_ROM.SYS image may be extended by issuing the following commands in an emulated QDOS or SMSQ/E environment:
~~~
base=RESPR(96*1024)
LBYTES Q68_ROM.SYS,base
LBYTES extension_rom_image,base+80*1024
RENAME Q68_ROM.SYS,Q68_ROM.ORG
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

The devices win1_ to win8_ and qub1_ to qub8_ can be configured to be mapped to any \*.WIN (QLWA format) or \*.BIN (Qubide format) container file by using the CONFIG or MENUCONFIG program on the Q68_ROM.SYS file. You MUST use a V2 capable version of these programs. Suitable CONFIG programs can be found on https://dilwyn.qlforum.co.uk/config/index.html.

HIGH RESOLUTION MODE 1024x768x4
-------------------------------

From v1.4 onwards, the Q68's 1024x768x4 mode is supported. Note that this mode has not been tested extensively so please use it with caution. 

The 1024x768x4 mode is implemented using the DISP_MODE command with a subset of the SMSQ/E version. Currently, modes 0 (256x256x8), 1 (512x256x4), and 4 (1024x768x4) are supported. Implementing the full range, including 65536-colour modes, would require a total rewrite of the screen drivers and also raise incompatibility problems with the Pointer Interface etc, so if you need these modes then better stick to SMSQ/E...

That said, it would have been nice if the Q68 had supported 8-colour mode with higher resolution, which is fairly easy to implement in the current drivers. Also, 1024x768 might be difficult to read on modern LCD-type monitors where the native resolution is not an exact multiple of 1024x768. To this end, downscaling to 512x384 would be a good compromise (e.g. DISP_MODE 6, but with 8 colours? (end of feature request :-)))

Note that Minerva's dual screen feature is not supported in 1024x768 mode, and trying to switch to DISP_MODE 4 with dual screen enabled will produce a 'not complete' error. Please reboot first with dual screen disabled.

If you use the Pointer Interface in 1024x768 mode, then some caution is required. The ptr_gen program needs to be patched to support the extended screen size and different screen buffer address. Thus, you must load it with some code like this (Toolkit II extensions required):
~~~
200 DEFine PROCedure patch_ptr
210 LOCal a,p,s
220   a=RESPR(FLEN(\ptr_gen))
230   LBYTES ptr_gen,a
240   s=0: PRINT "Patching pointer interface...";
250   FOR p=a TO a+FLEN(\ptr_gen) STEP 2
260     IF PEEK_L(p)=32768 AND PEEK_W(p+4)=128 AND PEEK_W(p+6)=512 AND PEEK_W(p+8)=256 THEN
270       POKE_L p-4,HEX('fe800000'): POKE_L p,HEX('30000'): REMark buffer address and size
280       POKE_W p+4,256: POKE_W p+6,1024: POKE_W p+8,768: REMark line length, X size, Y size
290       s=1: EXIT p
300     END IF
310   END FOR p
320   IF s=1 THEN
330     PRINT "Success!": CALL a: LRESPR wman: LRESPR hot_rext
340   ELSE
350     PRINT "Failed!"
360   END IF
370 END DEFine patch_ptr
~~~
Note that you must switch to 1024x768 mode /BEFORE/ activating the Pointer Interface. After this, you cannot switch back to the lower-resolution modes.

The functions SCR_BASE, SCR_LLEN, SCR_XLIM and SCR_YLIM return the base address, pixel line length in bytes, and X and Y limits of the current screen mode, like their SMSQ/E counterparts. In the current version, any parameters are ignored.

Current issues:
---------------

- The SD-card driver requires a CARD_INIT 2 command to use the SD card in slot 2; other SD-card related commands are presently not implemented.
- The maximum amount of RAM supported is limited to 16MB, as the slave block system's structure currently prevents supporting more RAM.
- The serial port and mouse interface of the Q68 are currently not supported. The QLNET and Ethernet interfaces are supported using external utilities, see https://dilwyn.qlforum.co.uk/q68/index.html for more information.
- Some users of Q68 boards with newer firmware (v1.05) have reported problems with the keyboard and the Q68 'freezing' after the F1/F2 prompt. These are currently under investigation. Please use the Issues section to report any problems, stating as much information as possible (including the firmware version, which can be read from the Q68's initial boot screen; temporary removal of the SD card will give you enough time to read it).
- Building instructions need to be added (work in progress).


Contributors:
-------------

- Minerva operating system by Laurence Reeves;
- Keyboard driver: Richard Zidlicky, Jan Bredenbeek
- SDHC device driver: Wolfgang Lenerz

Version history:
----------------

- 9 July 2023: v1.4 released. Implemented 1024x768x4 mode (beta)
- 29 June 2023: v1.3 released. Support for external interrupts on all Q68 firmware versions, support for keyboard interrupt on newer firmware versions, one language version now for all three keyboard layouts.
- June 2021: Combined keyboard and SD-card drivers in one single ROM image, leaving 16K available for other extension ROMs. Patched SD-card driver for stale TRAP #14 instruction left over (from debugging?)
- May 2019: Patch included for LBYTES bug over network (contributed by Marcel Kilgus)
- April 2019: improved keyboard driver, now only compatible with Minerva
- May 2018: support for US and UK keyboards, RAM test limited to 16MB to avoid problems with slave block system
