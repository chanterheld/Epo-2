#include "instructions.h"
#include <stdlib.h>
#include <string.h>
#include <pthread.h>
#include "list.h"
#include "maze.h"
#include "state.h"
#include "location.h"
#include "config.h"
#include "math.h"

#include <stdio.h> // debugging

typedef struct Thread_struct
{
    Maze maze;
    List *roads;
    Location **route;
    int number_of_destinations;
    State state;
    float estimated_time;
} Thread_struct;

static float getEstimatedTime(Maze maze, State state, const int number_of_destinations, Location location, Maze *roads[])
{ // add boundery checkking!!!!!!!!!!!!!!!!!!!
    float estimated_time = 0;
    for (int x = 0; x < number_of_destinations; ++x) {
        for (char score = roads[x]->map[location.i][location.j] - 1; score > 0; --score) {
            switch (state) {
            case (FORWARD_NORTH):
                if (roads[x]->map[location.i - 1][location.j] == score) {
                    location.i--;
                    estimated_time += RECHTDOOR_TIME;
                } else if (roads[x]->map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (roads[x]->map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.i++;
                    state = BACKWARD_NORTH;
                    estimated_time += ACHTERUIT_TIME;
                }
                break;
            case (FORWARD_EAST):
                if (roads[x]->map[location.i][location.j + 1] == score) {
                    location.j++;
                    estimated_time += RECHTDOOR_TIME;
                } else if (roads[x]->map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (roads[x]->map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.j--;
                    state = BACKWARD_EAST;
                    estimated_time += ACHTERUIT_TIME;
                }
                break;
            case (FORWARD_SOUTH):
                if (roads[x]->map[location.i + 1][location.j] == score) {
                    location.i++;
                    estimated_time += RECHTDOOR_TIME;
                } else if (roads[x]->map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (roads[x]->map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.i--;
                    state = BACKWARD_SOUTH;
                    estimated_time += ACHTERUIT_TIME;
                }
                break;
            case (FORWARD_WEST):
                if (roads[x]->map[location.i][location.j - 1] == score) {
                    location.j--;
                    estimated_time += RECHTDOOR_TIME;
                } else if (roads[x]->map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (roads[x]->map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    if (maze.mines_possible[location.i][location.j] == true || (roads[x]->map[location.i][location.j] == 1 && x != number_of_destinations - 1))
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.j++;
                    state = BACKWARD_WEST;
                    estimated_time += ACHTERUIT_TIME;
                }
                break;
            case (BACKWARD_NORTH):
                if (roads[x]->map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x]->map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += LINKSAF_90_TIME;
                } else {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += KEREN_TIME;
                }
                break;
            case (BACKWARD_EAST):
                if (roads[x]->map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x]->map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += LINKSAF_90_TIME;
                } else {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += KEREN_TIME;
                }
                break;
            case (BACKWARD_SOUTH):
                if (roads[x]->map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x]->map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += LINKSAF_90_TIME;
                } else {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += KEREN_TIME;
                }
                break;
            case (BACKWARD_WEST):
                if (roads[x]->map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x]->map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += LINKSAF_90_TIME;
                } else {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += KEREN_TIME;
                }
                break;

            }
            if (maze.mines_possible[location.i][location.j] == true)
                estimated_time += MINES_POSSIBLE_TIME;
            addNoMine(&maze, location);
        }
    }
    return estimated_time;
}


static void three(Thread_struct *ts, List *mazes[])
{
    float best_estimated_time = INFINITE_FLOAT;
    float estimated_time;
    int best[3];
    Maze *temp_roads[3];
    Maze *temp_maze;

    for (int i = 0; i < mazes[0]->length; ++i) {
        temp_maze = getListData(mazes[0], i);
        temp_roads[0] = temp_maze;
        for (int j = 0; j < mazes[1]->length; ++j) {
            temp_maze = getListData(mazes[1], j);
            temp_roads[1] = temp_maze;
            for (int k = 0; k < mazes[2]->length; ++k) {
                temp_maze = getListData(mazes[2], k);
                temp_roads[2] = temp_maze;
                estimated_time = getEstimatedTime(ts->maze, ts->state, 3, *ts->route[0], temp_roads);
                if (estimated_time < best_estimated_time) {
                    best_estimated_time = estimated_time;
                    best[0] = i;
                    best[1] = j;
                    best[2] = k;
                }
            }
        }
    }

    /* Add best road combination to road list */
    for (int i = 0; i < 3; ++i) {
        temp_maze = getListData(mazes[i], best[i]);
        addList(ts->roads, temp_maze);
    }
    ts->estimated_time = best_estimated_time;
}

static void two(Thread_struct *ts, List *mazes[])
{
    float best_estimated_time = INFINITE_FLOAT;// config infinite float
    float estimated_time;
    int best[2];
    Maze *temp_roads[2];
    Maze *temp_maze;

    for (int i = 0; i < mazes[0]->length; ++i) {
        temp_maze = getListData(mazes[0], i);
        temp_roads[0] = temp_maze;
        for (int j = 0; j < mazes[1]->length; ++j) {
            temp_maze = getListData(mazes[1], j);
            temp_roads[1] = temp_maze;
            estimated_time = getEstimatedTime(ts->maze, ts->state, 2, *ts->route[0], temp_roads);
            if (estimated_time < best_estimated_time) {
                best_estimated_time = estimated_time;
                best[0] = i;
                best[1] = j;
            }
        }
    }

    /* Add best road combination to road list */
    for (int i = 0; i < 2; ++i) {
        temp_maze = getListData(mazes[i], best[i]);//printf("i: %d, BEST i: %d IF THIS HAPPENDS TELL ME\n", mazes[i]->length, best[i]);
        addList(ts->roads, temp_maze);
    }
    ts->estimated_time = best_estimated_time;
}

static void one(Thread_struct *ts, List *mazes)
{
    float best_estimated_time = INFINITE_FLOAT;
    float estimated_time;
    int best;
    Maze *temp_maze;
    for (int i = 0; i < mazes->length; ++i) {
        temp_maze = getListData(mazes, i);
        estimated_time = getEstimatedTime(ts->maze, ts->state, 1, *ts->route[0], &temp_maze);
        if (estimated_time < best_estimated_time) {
            best_estimated_time = estimated_time;
            best = i;
        }
    }
    temp_maze = getListData(mazes, best);//printf("i: %d, BEST i: %d IF THIS HAPPENDS TELL ME\n", mazes[i]->length, best[i])
    addList(ts->roads, temp_maze);
    ts->estimated_time = best_estimated_time;
}

static void *threadFunction(void *thread_data)
{
    /* Setting up */
    Thread_struct *thread_struct = thread_data;

    /* Calculate all possible roads */
    Location *destination;
    List *mazes[thread_struct->number_of_destinations];
    for (int i = 0; i < thread_struct->number_of_destinations; ++i) {
        mazes[i] = initList(sizeof(Maze));
        destination = thread_struct->route[i + 1];
        thread_struct->maze.map[destination->i][destination->j] = 1;
        calculateRoads(thread_struct->maze, *thread_struct->route[i], *destination, mazes[i], 2);
        thread_struct->maze.map[destination->i][destination->j] = 0;
    }


    /* Filter out mazes that probably won't be the best option - not sure if needed atm*/
    int lowest_distance;
	Maze *temp_maze;
    for (int j = 0; j < thread_struct->number_of_destinations; ++j) {
        lowest_distance = INFINITE_INT;
        for (int i = 0; i < mazes[j]->length; ++i) {
            temp_maze = getListData(mazes[j], i);
            if (temp_maze->map[thread_struct->route[j]->i][thread_struct->route[j]->j] < lowest_distance) {
                lowest_distance = temp_maze->map[thread_struct->route[j]->i][thread_struct->route[j]->j];
            }
        }

        for (int i = 0; i < mazes[j]->length;) {
            temp_maze = getListData(mazes[j], i);
            if (temp_maze->map[thread_struct->route[j]->i][thread_struct->route[j]->j] > lowest_distance * MAX_DISTANCE_MULTIPLIER) {
                removeIndex(mazes[j], i);
            } else {
                ++i;
            }
        }
    }

    /* Get the best roads - calculated different dependend on number_of_destinations */
    switch (thread_struct->number_of_destinations) {
    case (3):
        three(thread_struct, mazes);
        break;
    case (2):
        two(thread_struct, mazes);
        break;
    case (1):
        one(thread_struct, mazes[0]);
        break;
    }
    return NULL;
}

static List *createInstructions(Maze maze, List *roads, State state, Location *location, const int number_of_destinations)
{
    List *instructions = initList(sizeof(Instruction));

    Instruction instruction;
    instruction.location = *location;
    instruction.state = state;
    Maze *road;
    for (int x = 0; x < number_of_destinations; ++x) {
        road = getListData(roads, x);
        for (char score = road->map[instruction.location.i][instruction.location.j] - 1; score > 0; --score) {
            switch (instruction.state) {
            case (FORWARD_NORTH):
                if (road->map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.code = RECHTDOOR;
                } else if (road->map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (road->map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.i++;
                    instruction.state = BACKWARD_NORTH;
                    instruction.code = ACHTERUIT;
                }
                break;
            case (FORWARD_EAST):
                if (road->map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.code = RECHTDOOR;
                } else if (road->map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (road->map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.j--;
                    instruction.state = BACKWARD_EAST;
                    instruction.code = ACHTERUIT;
                }
                break;
            case (FORWARD_SOUTH):
                if (road->map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.code = RECHTDOOR;
                } else if (road->map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (road->map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.i--;
                    instruction.state = BACKWARD_SOUTH;
                    instruction.code = ACHTERUIT;
                }
                break;
            case (FORWARD_WEST):
                if (road->map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.code = RECHTDOOR;
                } else if (road->map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (road->map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true || (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1))
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.j++;
                    instruction.state = BACKWARD_WEST;
                    instruction.code = ACHTERUIT;
                }
                break;
            case (BACKWARD_NORTH):
                if (road->map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = RECHTSAF_90;
                } else if (road->map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = LINKSAF_90;
                } else {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = KEREN;
                }
                break;
            case (BACKWARD_EAST):
                if (road->map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = RECHTSAF_90;
                } else if (road->map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = LINKSAF_90;
                } else {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = KEREN;
                }
                break;
            case (BACKWARD_SOUTH):
                if (road->map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = RECHTSAF_90;
                } else if (road->map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = LINKSAF_90;
                } else {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = KEREN;
                }
                break;
            case (BACKWARD_WEST):
                if (road->map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = RECHTSAF_90;
                } else if (road->map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = LINKSAF_90;
                } else {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = KEREN;
                }
                break;

            }
            if (road->map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1) {
                instruction.code += CHECKPOINT;
            }
            addNoMine(&maze, instruction.location);
            addList(instructions, &instruction);
        }
    }

    return instructions;
}

List *bruteforceInstructions(Maze maze, State state, List *places)
{
    /* Setting up */
    const int number_of_destinations = places->length - 1;
    const int runs = factorial(number_of_destinations);


    /* Creating array with every possible route */
    Location ***routes = malloc(runs * sizeof(Location**));
    routes[0] = (Location**)convertListToArray(places);
    for (int i = 1; i < runs; ++i) {
        routes[i] = (Location**)convertListToArray(places);//malloc(places->length * sizeof(Location*));
    }
    permute(routes, places->length);

    /* For every possible route, get the estimated_time and best roads */
    pthread_t *threads = malloc(runs * sizeof(pthread_t));
	Thread_struct **thread_structs = malloc(runs * sizeof(Thread_struct*));
	for (int i = 0; i < runs; ++i) {
		thread_structs[i] = malloc(sizeof(Thread_struct));
		thread_structs[i]->maze = maze;
        thread_structs[i]->roads = initList(sizeof(Maze));
		thread_structs[i]->route = routes[i];
		thread_structs[i]->number_of_destinations = number_of_destinations;
		thread_structs[i]->state = state;
		thread_structs[i]->estimated_time = 0;
		pthread_create (&threads[i], NULL, &threadFunction, thread_structs[i]);
	}

    // wait till every thread is done
	for (int i = 0; i < runs; ++i) {
		pthread_join(threads[i], NULL);
	}


    /* Choose the best route */
    int best_struct = 0;
    for (int i = 1; i < runs; ++i) {
        if (thread_structs[i]->estimated_time < thread_structs[best_struct]->estimated_time) {
            best_struct = i;
        }
    }


    /* Create instructions for the best route */
    Location *location = getListData(places, 0);
    List *instructions = createInstructions(maze, thread_structs[best_struct]->roads, state, location, number_of_destinations);


    /* Cleaning up */
    for (int i = 0; i < runs; ++i) {
        free(routes[i]);
        deleteList(thread_structs[i]->roads);
        free(thread_structs[i]);
    }
    free(routes);
    free(thread_structs);
    free(threads);


    /* returning the instructions list */
    return instructions;
}
