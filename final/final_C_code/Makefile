CC = gcc
#CC = clang
MINGW = time x86_64-w64-mingw32-gcc 
#MINGW = i686-w64-mingw32-gcc
CFLAGS = -pedantic -flto -Wall -finline-limit=999999 -march=haswell -mtune=haswell -std=c11 -pipe -Wextra
LIBS = -lpthread
SOURCES = main.c challenge.c list.c maze.c state.c location.c math.c instructions.c instructions_c.c xbee.c menu.c

#all:
#	$(CC) $(CFLAGS) $(LIBS) main.c debugging.c list.c maze.c state.c location.c math.c instructions_c.c  instructions.c 

all:
	$(MINGW) -static $(CFLAGS) $(LIBS) $(SOURCES) -o ~/Dropbox/epo_2/bot/a.exe

