/*
	MUST BE EXECUTED IN C:\\projects\\intel_testgen\\ with shell.exe
*/

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>

#define DEBUGMODE 0

void diffContext(CONTEXT *c1, CONTEXT *c2);
int debugNewProcess(char *assembledFile, CONTEXT *cOriginal, CONTEXT *cNew);

int main(int argc, char **argv)
{
	if(argc != 2)
	{
		printf("[E] trololol\n");
		return 0;
	}

	CONTEXT cOriginal;
	CONTEXT cNew;

	memset(&cOriginal,0,sizeof(CONTEXT));
	memset(&cNew,0,sizeof(CONTEXT));

	cOriginal.ContextFlags = CONTEXT_FULL;
	cNew.ContextFlags = CONTEXT_FULL;

	if(DEBUGMODE) printf("[I] testgen\n");

	if(debugNewProcess(argv[1],&cOriginal,&cNew) == 1)
	{
		diffContext(&cOriginal, &cNew);
	}
	
	return 0;
}

// c2 is new.
void diffContext(CONTEXT *c1, CONTEXT *c2)
{
	int registerChanged = 0;
	if(c1->Eax != c2->Eax) printf("assert_equal $cpu.eax, 0x%08x\n", c2->Eax); registerChanged++;
	if(c1->Ebx != c2->Ebx) printf("assert_equal $cpu.ebx, 0x%08x\n", c2->Ebx); registerChanged++;
	if(c1->Ecx != c2->Ecx) printf("assert_equal $cpu.ecx, 0x%08x\n", c2->Ecx); registerChanged++;
	if(c1->Edx != c2->Edx) printf("assert_equal $cpu.edx, 0x%08x\n", c2->Edx); registerChanged++;
	if(c1->Esp != c2->Esp) printf("# assert_equal $cpu.esp, 0x%08x\n", c2->Esp); registerChanged++;
	if(c1->Ebp != c2->Ebp) printf("assert_equal $cpu.ebp, 0x%08x\n", c2->Ebp); registerChanged++;
	if(c1->Esi != c2->Esi) printf("assert_equal $cpu.esi, 0x%08x\n", c2->Esi); registerChanged++;
	if(c1->Edi != c2->Edi) printf("assert_equal $cpu.edi, 0x%08x\n", c2->Edi); registerChanged++;
	if(c1->EFlags != c2->EFlags) printf("assert_equal $cpu.eflags, 0x%08x\n", c2->EFlags); registerChanged++;
	if(c1->SegDs != c2->SegDs) printf("assert_equal $cpu.ds, 0x%08x\n", c2->SegDs); registerChanged++;
	if(c1->SegEs != c2->SegEs) printf("assert_equal $cpu.es, 0x%08x\n", c2->SegEs); registerChanged++;
	if(c1->SegFs != c2->SegFs) printf("assert_equal $cpu.fs, 0x%08x\n", c2->SegFs); registerChanged++;
	if(c1->SegGs != c2->SegGs) printf("assert_equal $cpu.gs, 0x%08x\n", c2->SegGs); registerChanged++;
	printf("# %d registers changed\n", registerChanged);
	return;
}

int debugNewProcess(char *assembledFile, CONTEXT *cOriginal, CONTEXT *cNew)
{
	FILE *f = fopen(assembledFile,"rb");
	fseek(f,0,SEEK_END);
	unsigned long fSize = ftell(f);
	char *asmBlob = (char *)malloc(fSize);
	fseek(f,0,SEEK_SET);
	fread(asmBlob,1,fSize,f);
	fclose(f);

	PROCESS_INFORMATION pi;
	STARTUPINFO si;

	memset (&si, 0, sizeof (STARTUPINFO));
	si.cb = sizeof(si);

	if(DEBUGMODE) printf("[I] attempting to create shell...\n");

	// why is this inside the process space of terminaydor.exe?
	if (CreateProcess
      ("C:\\projects\\intel_testgen\\shell.exe", "C:\\projects\\intel_testgen\\shell.exe", NULL, NULL, FALSE,
       DEBUG_PROCESS + CREATE_SUSPENDED, NULL,
       "C:\\projects\\intel_testgen\\", &si, &pi) == 0)
    {
		char *errorMessage;
		FormatMessage (FORMAT_MESSAGE_ALLOCATE_BUFFER +
                     FORMAT_MESSAGE_FROM_SYSTEM, 0, GetLastError (), 0,
                     (char *) &errorMessage, 1, NULL);
		if(DEBUGMODE)  printf ("[E] %s", errorMessage);
		return 0;
    }

	if(DEBUGMODE)  printf("[I] pi.hProcess = %08x\n", pi.hProcess);

	unsigned long bytesWritten = 0;
	WriteProcessMemory(pi.hProcess,(LPVOID )0x00401001,asmBlob,fSize,&bytesWritten);
	
	if(bytesWritten != fSize)
	{
		if(DEBUGMODE) printf("[E] could not write to process memory with WriteProcessMemory\n");
		CloseHandle(pi.hProcess);
		return 0;
	}

	
	ResumeThread(pi.hThread);

	int firstTime = 1;
	
	DEBUG_EVENT de;
    while (WaitForDebugEvent (&de, INFINITE))
	{
		if(de.u.Exception.dwFirstChance == 0)
		{
			if(DEBUGMODE)  printf("[!] Second chance exception!\n");
			ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
		}
		// printf("[E@] %08x, %x\n", de.u.Exception.ExceptionRecord.ExceptionAddress,de.dwDebugEventCode );
		switch(de.dwDebugEventCode)
		{	
			case EXCEPTION_DEBUG_EVENT:
				if(de.u.Exception.ExceptionRecord.ExceptionAddress == (LPVOID )0x004013ff)
				{
					if(DEBUGMODE) printf("[!] fetching new context\n");
					GetThreadContext(pi.hThread,cNew);
					CloseHandle(pi.hProcess);
					return 1;
				}
				else
				{
					if(firstTime == 1)
					{
						firstTime = 0;
						ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
						break;
					}
					else if(de.u.Exception.ExceptionRecord.ExceptionAddress == (LPVOID )0x00401000)
					{
						if(DEBUGMODE) printf("[!] fetching initial context\n");
						GetThreadContext(pi.hThread,cOriginal);
						ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
						break;
					}
					else
					{
						if(DEBUGMODE) printf("[E] actual exception at %08x\n",de.u.Exception.ExceptionRecord.ExceptionAddress );
						ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
						break;
					}
				}
				break;
			case LOAD_DLL_DEBUG_EVENT:
				if(DEBUGMODE) printf ("[+] DLL\n");
				ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
				break;
			case UNLOAD_DLL_DEBUG_EVENT:
				if(DEBUGMODE) printf ("[-] DLL\n");
				ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
				break;
			case EXIT_PROCESS_DEBUG_EVENT:
				return 0;
				break;
			case CREATE_THREAD_DEBUG_EVENT:
				if(DEBUGMODE) printf ("[+] Thread @ %08x\n",(unsigned long) de.u.CreateThread.lpStartAddress);
				ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_CONTINUE);
				break;
			default:
				// printf("[E] exception code 0x%x\n", de.dwDebugEventCode);
				ContinueDebugEvent (de.dwProcessId, de.dwThreadId, DBG_EXCEPTION_NOT_HANDLED);
				break;
		}
	}

	return 0;
}
