#include "maze.h"
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "config.h"
#include "list.h"

Maze initMaze(bool mines_possible)
{
    Maze maze;

    for (int i = 0; i < 11; ++i) {
        for (int j = 0; j < 11; ++j) {
            maze.map[i][j] = -1;
            maze.mines_possible[i][j] = false;
        }
    }

    for (int i = 1; i < 10; ++i) {
        if (i & 1) {
            for (int j = 1; j < 10; ++j) {
                maze.map[i][j] = 0;
                if ((j & 1) == false)
                    maze.mines_possible[i][j] = true;
            }
        } else {
            for (int j = 1; j < 10; j += 2) {
                maze.map[i][j] = 0;
                maze.mines_possible[i][j] = true;
            }
        }
    }

    for (int i = 3; i < 8; i += 2) {
        maze.map[i][0] = 0;
    }
    for (int i = 3; i < 8; i += 2) {
        maze.map[i][10] = 0;
    }
    for (int j = 3; j < 8; j += 2) {
        maze.map[0][j] = 0;
    }
    for (int j = 3; j < 8; j += 2) {
        maze.map[10][j] = 0;
    }

    if (mines_possible == false) {
        for (int i = 0; i < 11; ++i) {
            for (int j = 0; j < 11; ++j) {
                maze.mines_possible[i][j] = false;
            }
        }
    }

    maze.number_of_mines_found = 0;
    maze.number_of_mines_possible_locations = NUMBER_OF_MINES_POSSIBLE_LOCATIONS;

    return maze;
}

void printMaze(Maze maze)
{
    for (int i = 0; i < 11; ++i) {
        for (int j = 0; j < 11; ++j) {
            if (maze.map[i][j] == 0) {
                if (maze.mines_possible[i][j] == true)
                    printf(BLUE"%3d"CLEAR, maze.map[i][j]);
                else
                    printf("%3d", maze.map[i][j]);
            } else if (maze.map[i][j] > 0)
                printf(GREEN"%3d"CLEAR, maze.map[i][j]);
            else if (maze.map[i][j] == -1)
                printf(RED"%3d"CLEAR, maze.map[i][j]);
            else if (maze.map[i][j] == -2)
                printf(YELLOW"%3d"CLEAR, maze.map[i][j]);
        }
        putchar('\n');
    }
    putchar('\n');
}

void copyMap(char map[11][11], char copy_map[11][11])
{
    for (int i = 0; i < 11; ++i) {
		memcpy(&copy_map[i], &map[i], sizeof(map[0]));
	}
}

void calculateRoad(char map[11][11], Location *location, Location *destination)
{
	map[destination->i][destination->j] = 1;
	for (int run = 1; map[location->i][location->j] == 0; ++run) {
		for (int i = 0; i < 11; ++i) {
			for (int j = 0; j < 11; ++j) {
				if (map[i][j] == run) {
                    if (i < 10 && map[i + 1][j] == 0)
                        map[i + 1][j] = run + 1;
					if (i > 0  && map[i - 1][j] == 0)
                        map[i - 1][j] = run + 1;
					if (j < 10 && map[i][j + 1] == 0)
                        map[i][j + 1] = run + 1;
					if (j > 0  && map[i][j - 1] == 0)
                        map[i][j - 1] = run + 1;
				}
			}
		}
	}
}

void calculateRoads(Maze maze, Location location, Location destination, List *mazes, char run)
{
    if (maze.map[location.i][location.j] != 0) {
        addList(mazes, &maze);
        return;
    }

    Location copy_destination;
    Maze copy_maze;
    if (destination.i < 10 && maze.map[destination.i + 1][destination.j] == 0) {
        copy_destination = destination;
        copy_destination.i++;
        copy_maze = maze;
        copy_maze.map[copy_destination.i][copy_destination.j] = run;
        calculateRoads(copy_maze, location, copy_destination, mazes, run + 1);
    } if (destination.i > 0 && maze.map[destination.i - 1][destination.j] == 0) {
        copy_destination = destination;
        copy_destination.i--;
        copy_maze = maze;
        copy_maze.map[copy_destination.i][copy_destination.j] = run;
        calculateRoads(copy_maze, location, copy_destination, mazes, run + 1);
    } if (destination.j < 10 && maze.map[destination.i][destination.j + 1] == 0) {
        copy_destination = destination;
        copy_destination.j++;
        copy_maze = maze;
        copy_maze.map[copy_destination.i][copy_destination.j] = run;
        calculateRoads(copy_maze, location, copy_destination, mazes, run + 1);
    } if (destination.j > 0 && maze.map[destination.i][destination.j - 1] == 0) {
        copy_destination = destination;
        copy_destination.j--;
        copy_maze = maze;
        copy_maze.map[copy_destination.i][copy_destination.j] = run;
        calculateRoads(copy_maze, location, copy_destination, mazes, run + 1);
    }
}

void addMine(Maze *maze, Location location)
{
    maze->map[location.i][location.j] = -2;
    maze->number_of_mines_found++;
    maze->mines_possible[location.i][location.j] = false;
    maze->number_of_mines_possible_locations--;

    if (maze->number_of_mines_found == MAX_NUMBER_OF_MINES) {
        for (int i = 0; i < 11; ++i) {
            for (int j = 0; j < 11; j++) {
                maze->mines_possible[i][j] = false;
            }
        }
        maze->number_of_mines_possible_locations = 0;
    }
}
void addNoMine(Maze *maze, Location location)
{
    if (maze->mines_possible[location.i][location.j] == false)
        return;

    maze->mines_possible[location.i][location.j] = false;
    maze->number_of_mines_possible_locations--;

    if (MAX_NUMBER_OF_MINES - maze->number_of_mines_found == maze->number_of_mines_possible_locations) {
        for (int i = 0; i < 11; ++i) {
            for (int j = 0; j < 11; j++) {
                if (maze->mines_possible[i][j] == true) {
                    maze->map[i][j] = -2;
                    maze->mines_possible[i][j] = false;
                }
            }
        }
        maze->number_of_mines_possible_locations = 0;
    }
}

static bool isRoadPossible(Maze maze, List *places)
{
    Location *location;
    Location *destination;
    char copy_map[11][11];
    for (int x = 0; x < places->length - 1; ++x) {
        location = getListData(places, x);
        destination = getListData(places, x + 1);
        copyMap(maze.map, copy_map);
        copy_map[destination->i][destination->j] = 1;

        for (int run = 1; copy_map[location->i][location->j] == 0; ++run) {
            if (run > MAX_RUN)
                return false;

            for (int i = 0; i < 11; ++i) {
                for (int j = 0; j < 11; ++j) {
                    if (copy_map[i][j] == run) {
                        if (i < 10 && maze.map[i + 1][j] == 0)
                            copy_map[i + 1][j] = run + 1;
                        if (i > 0  && maze.map[i - 1][j] == 0)
                            copy_map[i - 1][j] = run + 1;
                        if (j < 10 && maze.map[i][j + 1] == 0)
                            copy_map[i][j + 1] = run + 1;
                        if (j > 0  && maze.map[i][j - 1] == 0)
                            copy_map[i][j - 1] = run + 1;
                    }
                }
            }
        }
    }
    return true;
}

void checkMinesNotPossible(Maze *maze, List *places)
{
    Maze temp_maze = *maze;

    for (int i = 0; i < 11; ++i) {
        for (int j = 0; j < 11; ++j) {
            if (maze->mines_possible[i][j] == false || maze->map[i][j] < 0)
                continue;

            temp_maze.map[i][j] = -2;
            if (isRoadPossible(temp_maze, places) == false) {
                maze->mines_possible[i][j] = false;
                maze->number_of_mines_possible_locations--;
                printf("%d %d - MINES NOT POSSIBLE HERE\n", i, j);
            }
            temp_maze.map[i][j] = 0;
        }
    }
    if (MAX_NUMBER_OF_MINES - maze->number_of_mines_found == maze->number_of_mines_possible_locations) {
        for (int i = 0; i < 11; ++i) {
            for (int j = 0; j < 11; j++) {
                if (maze->mines_possible[i][j] == true) {
                    maze->map[i][j] = -2;
                    maze->number_of_mines_found++;
                    maze->mines_possible[i][j] = false;
                }
            }
        }
        maze->number_of_mines_possible_locations = 0;
    }
}

void saveMaze(Maze *maze, char filename[32])
{
    FILE *fp = fopen(filename, "w");
    for (int i = 0; i < 11; i++) {
        for (int j = 0; j < 11; j++) {
            fprintf(fp, "%3d", maze->map[i][j]);
        }
        fprintf(fp, "\n");
    }
    fclose(fp);
}

Maze loadMaze(char filename[32])
{
    int a;
    Maze maze = initMaze(true);
    FILE *fp = fopen(filename, "r");
    for (int i = 0; i < 11; ++i) {
        for (int j = 0; j < 11; ++j) {
            fscanf(fp, "%d", &a);
            maze.map[i][j] = (char)a;
            if (maze.map[i][j] == -2) {
                maze.mines_possible[i][j] = false;
                maze.number_of_mines_possible_locations--;
                maze.number_of_mines_found++;
            }
        }
    }
    fclose(fp);

    return maze;
}