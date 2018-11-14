#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

void usage() {
    fputs("Command line parameters: <serial port name>\n", stderr);
}

int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
    char* token = strtok(szCmdLine, " ");
    if (token == NULL) {
        usage();
        return 1;
    }
    const PSTR szPort = strdup(token);
    HANDLE hComm;
    hComm = CreateFile(
        szPort,  
        GENERIC_READ | GENERIC_WRITE, 
        0, 
        0, 
        OPEN_EXISTING,
        FILE_FLAG_OVERLAPPED,
        0);
    if (hComm == INVALID_HANDLE_VALUE) {
        puts("Cannot open serial port");
        return 1;
    }
    free(szPort);
    
    DCB dcb;
    FillMemory(&dcb, sizeof(dcb), 0);
    dcb.DCBlength = sizeof(dcb);
    BuildCommDCB("31250,n,8,1", &dcb);

    if (!SetCommState(hComm, &dcb)) {
        fputs("Error in serial setup\n", stderr);
        printf("%d\n", dcb.BaudRate);
        return 1;
    }

    CloseHandle(hComm);
    return 0;
}
