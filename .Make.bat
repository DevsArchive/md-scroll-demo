@echo off
_Bin\asm68k.exe /p /o ae-,op+,os+,ow+,oz+,oaq+,osq+,omq+ Main.asm, ScrollDemo.gen, , ScrollDemo.lst
_Bin\rompad.exe ScrollDemo.gen 255 0
_Bin\fixheadr.exe ScrollDemo.gen
pause