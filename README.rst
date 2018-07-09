===========
Minerva4Q68
===========

A port of the Minerva operating system for the Q68.

INSTALLATION:
=============

The appropriate ROM image Q68_??ROM.SYS should be renamed to Q68_ROM.SYS and
copied to a FAT32 directory on a SDHC card. The Q68 will then load this image
and boot into the Minerva operating system.

The 96K ROM images contain the Minerva operating system, a keyboard driver
specific for US, UK and DE (German) keyboard layouts, and a SDHC card driver.

Current issues:

- The keyboard driver currently does not support auto-repeat and key mappings
  need to be updated.
  
- The current build supports up to 16MB RAM.

Contributors:

- Minerva operating system by Laurence Reeves;
- Keyboard driver: Richard Zidlicky, Jan Bredenbeek
- SDHC device driver: Wolfgang Lenerz

  
