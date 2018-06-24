#include "challenge.h"
#include "maze.h"
#include "list.h"
#include "state.h"
#include "location.h"
#include "instructions.h"
#include "config.h"
#include "xbee.h"
#include <stdio.h>
#include <windows.h>

void printInstructions(List *instructions)
{
    Instruction *instruction;
    for (int i = 0; i < instructions->length; ++i) {
        instruction = getListData(instructions, i);
        printf("%4x", instruction->code);
        if (instruction->code & CHECKPOINT || instruction->code & CHECK_AND_BACK)
            putchar('\n');
    }
    putchar('\n');
}

bool removeIfEqual(List *places, Location *location)
{
    Location *current;
    for (int i = 1; i < places->length; ++i) {
        current = getListData(places, i);
        if (location->i == current->i && location->j == current->j) {
            removeIndex(places, i);
            printf("Removing location: %d %d\n", location->i, location->j);
            return true;
        }
    }

    return false;
}

void challengeA(int a, int b, int c, int d)
{
    Maze maze = initMaze(false);
    State state = setState(a);
    List *places = initList(sizeof(Location));
    Location location;
    location = setLocation(a);  addList(places, &location);
    location = setLocation(b);  addList(places, &location);
    location = setLocation(c);  addList(places, &location);
    location = setLocation(d);  addList(places, &location);


    //XBEE STUFF
    HANDLE hSerial;
    hSerial = CreateFile(COMPORT,
    GENERIC_READ | GENERIC_WRITE,
    0,
    0,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
    );
    initSio(hSerial);

    List *instructions = bruteforceInstructions(maze, state, places);
    printInstructions(instructions);

    int count = 1;
    unsigned char buffer = BUFFER_SUCCES;
    Instruction *instruction;

    while (count < instructions->length) {
        if (buffer == BUFFER_NO_MINE || buffer == BUFFER_SUCCES) {
            instruction = getListData(instructions, count);
            buffer = instruction->code;

            writeByte(hSerial, &buffer);

            count += 2;
        }
        readByte(hSerial, &buffer);
    }

    deleteList(places);
    deleteList(instructions);
}

void challengeB(int a, int b, int c, int d)
{
    Maze maze = initMaze(true);
    State state = setState(a);
    List *places = initList(sizeof(Location));
    Location location;
    location = setLocation(a);  addList(places, &location);
    location = setLocation(b);  addList(places, &location);
    location = setLocation(c);  addList(places, &location);
    location = setLocation(d);  addList(places, &location);

    List *all_places = copyList(places);

    //XBEE STUFF
    HANDLE hSerial;
    hSerial = CreateFile(COMPORT,
    GENERIC_READ | GENERIC_WRITE,
    0,
    0,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
    );
    initSio(hSerial);


    List *instructions = bruteforceInstructions(maze, state, places);
    printInstructions(instructions);

    int count = 1;
    unsigned char buffer = BUFFER_SUCCES;
    Instruction *instruction;
    while (count < instructions->length) {
        if (buffer == BUFFER_MINE) {
            instruction = getListData(instructions, count - 2);
            addMine(&maze, instruction->location);printf("NUMBER_OF_MINES_FOUND: %d\n", maze.number_of_mines_found);
            checkMinesNotPossible(&maze, all_places);
            state = instruction->state * -1;

            if (count > 2) { 
                instruction = getListData(instructions, count - 3);
                setList(places, 0, &instruction->location);
            }
            deleteList(instructions);
            instructions = bruteforceInstructions(maze, state, places);

            count = 0;
            buffer = BUFFER_SUCCES;

        } if (buffer == BUFFER_NO_MINE || buffer == BUFFER_SUCCES) {
            instruction = getListData(instructions, count);
            buffer = instruction->code;

            if (count > 1) {
                instruction = getListData(instructions, count - 2);
                addNoMine(&maze, instruction->location);
            }

            removeIfEqual(places, &instruction->location);

            writeByte(hSerial, &buffer);

            count += 2;
        }
        readByte(hSerial, &buffer);
    }

    deleteList(all_places);
    deleteList(places);
    deleteList(instructions);
}

List *getPlacesC(Maze *maze, List *old_places)
{
    Location *current = getListData(old_places, 0);
    List *places = initList(sizeof(Location));
    addList(places, current);
    Location location;

    for (int i = 0; i < 11; ++i) {
        for (int j = 0; j < 11; ++j) {
            if (maze->mines_possible[i][j] == true) {
                location.i = i;
                location.j = j;
                addList(places, &location);
            }
        }
    }
    printf("NEW_PLACES_LENGTH: %d\n", places->length);
    return places;
}

void challengeC_part_1()
{
    Instruction *instruction_temp;
    Location *TEST;

    Maze maze = initMaze(true);
    State state = setState(START);
    Location start = setLocation(START);
    List *temp_places = initList(sizeof(Location));
    addList(temp_places, &start);
    List *places = getPlacesC(&maze, temp_places);
    deleteList(temp_places);
    
    //XBEE STUFF
    HANDLE hSerial;
    hSerial = CreateFile(COMPORT,
    GENERIC_READ | GENERIC_WRITE,
    0,
    0,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
    );
    initSio(hSerial);

    List *instructions = approximateInstructions(maze, state, places);
    printInstructions(instructions);
    int count = 1;
    unsigned char buffer = BUFFER_SUCCES;
    Instruction *instruction;

    while (maze.number_of_mines_found < MAX_NUMBER_OF_MINES) {
        if (buffer == BUFFER_MINE) {
            instruction = getListData(instructions, count - 2);
            addMine(&maze, instruction->location); printf("MINE ADDED AT %d %d", instruction->location.i, instruction->location.j);
            printMaze(maze);
            //removeIfEqual(places, &instruction->location);
            temp_places = places;
            places = getPlacesC(&maze, temp_places);
            deleteList(temp_places);

            state = instruction->state * -1;
            printf("COMPUTE STATE: %d\n", state);
            if (count > 2) { 
                instruction = getListData(instructions, count - 3);
                setList(places, 0, &instruction->location);
            }
            printf("COMPUTE_LOCATION: %d %d\n", instruction->location.i, instruction->location.j);
            deleteList(instructions);
            instructions = approximateInstructions(maze, state, places);
            printInstructions(instructions);
            printf("NUMBER_OF_MINES_FOUND: %d\n", maze.number_of_mines_found);
            count = 0;
            buffer = BUFFER_SUCCES;
            if (maze.number_of_mines_found == MAX_NUMBER_OF_MINES)
                buffer = 0xFF;
        } if (buffer == BUFFER_NO_MINE) {
            instruction = getListData(instructions, count - 2);
            addNoMine(&maze, instruction->location); printf(" FUCKIN DAAN - NOMINE ADDED AT %d %d\n", instruction->location.i, instruction->location.j);
            //removeIfEqual(places, &instruction->location);
//             //setList(places, 0, &instruction->location);
//             temp_places = places;
//             places = getPlacesC(&maze, temp_places);
//             deleteList(temp_places);

//             state = instruction->state;
//             instruction = getListData(instructions, count - 1);
//             setList(places, 0, &instruction->location);

// TEST = getListData(places, 0);
// printf("LOCATION: %d %d\n", TEST->i, TEST->j);

//             deleteList(instructions);
//             instructions = approximateInstructions(maze, state, places); printf("RECOMPUTE STATE: %d, LOCATION: %d %d\n", state, TEST->i, TEST->j);
//             printInstructions(instructions);

//             count = 0;

            if (count >= instructions->length - 2) {
                printf("KURWA\n");

                temp_places = places;
                places = getPlacesC(&maze, temp_places);
                deleteList(temp_places);

                instruction_temp = getListData(instructions, instructions->length - 2);
                setList(places, 0, &instruction_temp->location);
                state = instruction_temp->state;
                deleteList(instructions);
                printf("FACKING PLACES %d\n", places->length);
                instructions = approximateInstructions(maze, state, places);
                printInstructions(instructions);
                count = 0;
            }

            buffer = BUFFER_SUCCES;
        } if (buffer == BUFFER_SUCCES) {
            printf("count: %d instructions length: %d\n", count, instructions->length);
            instruction = getListData(instructions, count);
            buffer = instruction->code;

            writeByte(hSerial, &buffer);

            count += 2;
        }
        readByte(hSerial, &buffer);
    }
    printf("DONE, number_of_mines_found: %d\n", maze.number_of_mines_found);

    /* Saving maze */
    saveMaze(&maze, SAVEFILE);

    /* clean up */
    deleteList(instructions);
    deleteList(places);

    return;
}

void challengeC_part_2 ()
{
    Maze maze = loadMaze(SAVEFILE);
    maze.number_of_mines_found = 0;


    printMaze(maze);

    State state = setState(START);
    Location start = setLocation(START);
    List *temp_places = initList(sizeof(Location));
    addList(temp_places, &start);
    List *places = getPlacesC(&maze, temp_places);
    deleteList(temp_places);

    //XBEE STUFF
    HANDLE hSerial;
    hSerial = CreateFile(COMPORT,
    GENERIC_READ | GENERIC_WRITE,
    0,
    0,
    OPEN_EXISTING,
    FILE_ATTRIBUTE_NORMAL,
    0
    );
    initSio(hSerial);

    List *instructions = approximateInstructions(maze, state, places);
    printInstructions(instructions);
    int count = 1;
    unsigned char buffer = BUFFER_SUCCES;
    Instruction *instruction;
    bool treassure_found = false;
    while (treassure_found == false) {
        if (buffer == BUFFER_MINE) {
            treassure_found = true;
            buffer = 0xFF;
        } if (buffer == BUFFER_NO_MINE) {

            buffer = BUFFER_SUCCES;
        } if (buffer == BUFFER_SUCCES) {

            instruction = getListData(instructions, count);
            buffer = instruction->code;

            writeByte(hSerial, &buffer);

            count += 2;
        }
        readByte(hSerial, &buffer);
    }

    /* CLEANING UP */
    deleteList(instructions);
    deleteList(places);
}
