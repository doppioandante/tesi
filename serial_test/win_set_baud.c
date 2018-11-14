#include <windows.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int WINAPI WinMain (HINSTANCE hInstance, HINSTANCE hPrevInstance, PSTR szCmdLine, int iCmdShow)
{
    if (szCmdLine[0] == '\0') {
        fputs("Command line parameters: <serial port name>\n", stderr);
        return 1;
    }

    HANDLE hComm;
    hComm = CreateFile(
        szCmdLine,
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

    DCB dcb;
    FillMemory(&dcb, sizeof(dcb), 0);
    dcb.DCBlength = sizeof(dcb);
    BuildCommDCB("31250,n,8,1", &dcb);

    BOOL res = SetCommState(hComm, &dcb);
    if (!res) {
        fputs("Error in serial setup\n", stderr);
    }

    CloseHandle(hComm);
    return res ? 0 : 1;
}
