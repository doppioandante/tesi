/*
 * Allows to set arbitrary speed for the serial device on Linux.
 * stty allows to set only predefined values: 9600, 19200, 38400, 57600, 115200, 230400, 460800.
 */
#include <stdio.h>
#include <fcntl.h>
#include <errno.h>
#include <stdlib.h>
#include <unistd.h>
#include <stropts.h>
#include <asm/termios.h>

int main(int argc, char* argv[]) {

    if (argc != 2) {
        printf("Usage: %s <serial device>", argv[0]);
        return 1;
    }

    int fd = open(argv[1], O_RDONLY);
    int speed = 31250;

    struct termios2 tio;
    ioctl(fd, TCGETS2, &tio);
    tio.c_cflag &= ~CBAUD;
    tio.c_cflag |= BOTHER;
    tio.c_ispeed = speed;
    tio.c_ospeed = speed;
    int r = ioctl(fd, TCSETS2, &tio);
    close(fd);

    return r;
}
