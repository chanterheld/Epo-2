#ifndef CONFIG_H
#define CONFIG_H

#define INFINITE_INT    9999999
#define INFINITE_FLOAT  9999.f

#define CLEAR   ""//"\x1B[0m"
#define RED     ""//"\x1B[31m"
#define GREEN   ""//"\x1B[32m"
#define YELLOW  ""//"\x1B[33m"
#define BLUE    ""//"\x1B[34m"

#define RECHTDOOR       0x00 // 0   // 0b00000000
#define LINKSAF         0x30 // 48  // 0b00110000
#define RECHTSAF        0x50 // 80  // 0b01010000
#define LINKSAF_90	    0x20 // 32  // 0b00100000
#define RECHTSAF_90     0x40 // 64  // 0b01000000
#define KEREN           0x60 // 96  // 0b01100000
#define CHECKPOINT	    0x08 // 8   // 0b00001000
#define CHECK_AND_BACK  0x80 // 128 // 0b10000000
#define ACHTERUIT	    0x01 // 1   // 0b00000001
#define CUT             0x10

#define RECHTDOOR_TIME		18
#define LINKSAF_TIME     	20
#define RECHTSAF_TIME    	20
#define LINKSAF_90_TIME		28
#define RECHTSAF_90_TIME 	28
#define KEREN_TIME			38
#define ACHTERUIT_TIME		2
#define MINES_POSSIBLE_TIME 0.01

#define MAX_DISTANCE_MULTIPLIER 1.2
#define MAX_RUN                 100
#define MAX_DESTINATIONS        4
#define NUMBER_OF_THREADS       1

#define BUFFER_MINE     0x3
#define BUFFER_NO_MINE  0x2
#define BUFFER_SUCCES   0x1

#define START   1

#define MAX_NUMBER_OF_MINES                 5
#define NUMBER_OF_MINES_POSSIBLE_LOCATIONS  40

#define SAVEFILE    "saved_maze.maze.txt"

#endif /* CONFIG_H */
