===========
Minerva4Q68
===========

Description
-----------

A port of the Minerva operating system for the Q68 (Sinclair QL clone).

The Minerva operating system was originally designed as a replacement ROM operating system for the Sinclair QL computer, currently licenced under GPLv3. This port is aimed at the Q68, an FPGA-based replacement board for the QL. It is not intended as a serious alternative for the SMSQ/E OS supplied with the Q68, as SMSQ/E is far more extensive and better suited to support the Q68 hardware than the 48K ROM-based Minerva. We just provide this port to demonstrate the Q68's ability to run 'oldskool' ROM images, give Q68 users the Minerva look and feel, and maybe provide an opportunity to run badly written software that doesn't run on SMSQ/E (but chances are big that this software won't run on Minerva either).

The current Minerva build is based on v1.98, with a few modifications to run successfully on the Q68.


INSTALLATION:
-------------

The appropriate ROM image Q68_??ROM.SYS should be renamed to Q68_ROM.SYS and copied to a FAT32 directory on a SDHC card. The Q68 will then load this image and boot into the Minerva operating system.

The 96K ROM images contain the Minerva operating system, a keyboard driver specific for US, UK and DE (German) keyboard layouts, and a SDHC card driver. Note that in the current build the MDV driver is still present but disabled since there is no MDV hardware in the Q68.

By default, the devices win1_ and win2_ will be mapped to container files QLWA.WIN on SDHC drives 1 and 2 respectively. If present, the devices qub1_ and qub2_ will be mapped to Qubide container files QL_BDI.BIN on SDHC drives 1 and 2 respectively. This can be changed by configuring the Q68_ROM.SYS file (see below).


CONFIGURATION:
--------------

The devices win1_ to win8_ and qub1_ to qub8_ can be configured to be mapped to any *.WIN (QLWA format) or *.BIN (Qubide format) container file by using the CONFIG or MENUCONFIG program on the Q68_ROM.SYS file. You MUST use a V2 capable version of these programs. Suitable CONFIG programs can be found on http://www.dilwyn.me.uk/config/index.html.


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
