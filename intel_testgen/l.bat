@echo off

link /MACHINE:X86 /OPT:REF /OPT:ICF /INCREMENTAL:NO /DEBUG /out:testgen.exe testgen.obj dbghelp.lib user32.lib