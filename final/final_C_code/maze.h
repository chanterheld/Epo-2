#ifndef MAZE_H
#define MAZE_H

#include <stdbool.h>
#include "location.h"
#include "list.h"

typedef struct Maze
{
    char map[11][11];
    bool mines_possible[11][11];
    char number_of_mines_found;
    char number_of_mines_possible_locations;
} Maze;

Maze initMaze(bool mines_possible);
void printMaze(Maze maze);
void copyMap(char map[11][11], char copy_map[11][11]);
void calculateRoad(char map[11][11], Location *location, Location *destination);
void calculateRoads(Maze maze, Location location, Location destination, List *mazes, char run);
void addMine(Maze *maze, Location location);
void addNoMine(Maze *maze, Location location);
void checkMinesNotPossible(Maze *maze, List *places);
void saveMaze(Maze *maze, char filename[32]);
Maze loadMaze(char filename[32]);

#endif /* MAZE_H */
