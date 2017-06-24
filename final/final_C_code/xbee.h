#ifndef XBEE_H
#define XBEE_H

#define COMPORT "COM6"
#define BAUDRATE CBR_9600

#include <stdio.h>
#include <stdlib.h>
#include <windows.h>
#include <string.h>

void initSio(HANDLE hSerial);
int readByte(HANDLE hSerial, unsigned char *buffRead);
void writeByte(HANDLE hSerial, unsigned char *buffWrite);

#endif
