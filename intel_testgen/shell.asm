.586p
.model flat,stdcall
option casemap:none

include c:\masm32\include\masm32.inc
include c:\masm32\include\kernel32.inc

includelib c:\masm32\lib\masm32.lib
includelib c:\masm32\lib\kernel32.lib

.code

_start:
int 3
db 1022 dup(90h)
int 3

invoke ExitProcess,0

end _start