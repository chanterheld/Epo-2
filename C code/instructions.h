#ifndef INSTRUCTIONS_H
#define INSTRUCTIONS_H

#include "state.h"
#include "location.h"
#include "list.h"
#include "maze.h"

typedef struct Instruction
{
    unsigned char code;
    State state;
    Location location;
} Instruction;

List *bruteforceInstructions(Maze maze, State state, List *places);
List *approximateInstructions(Maze maze, State state, List *places);

#endif /* INSTRUCTIONS_H */
