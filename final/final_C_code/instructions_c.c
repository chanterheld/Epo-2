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

#include <stdio.h> //debugging

typedef struct Thread_data
{
    Maze maze;
    Maze *mazes;
    Location **route;
    int number_of_destinations;
    State state;
    int estimated_time;
    int thread_runs;
} Thread_data;

static int getEstimatedTime(Maze maze, State state, const int number_of_destinations, Location location, Maze roads[])
{
    int estimated_time = 0;
    for (int x = 0; x < number_of_destinations; ++x) {
        for (char score = roads[x].map[location.i][location.j] - 1; score > 0; --score) {
            switch (state) {
            case (FORWARD_NORTH):
                if (location.i < 10 && roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = BACKWARD_NORTH;
                    estimated_time += ACHTERUIT_TIME;
                } else if (location.j < 10 && roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (location.j > 0 && roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.i--;
                    estimated_time += RECHTDOOR_TIME;
                }
                break;
            case (FORWARD_EAST):
                if (location.j > 0 && roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = BACKWARD_EAST;
                    estimated_time += ACHTERUIT_TIME;
                } else if (location.i < 10 && roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (location.i > 0 && roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.j++;
                    estimated_time += RECHTDOOR_TIME;
                }
                break;
            case (FORWARD_SOUTH):
                if (location.i > 0 && roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = BACKWARD_SOUTH;
                    estimated_time += ACHTERUIT_TIME;
                } else if (location.j > 0 && roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (location.j < 10 && roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.i++;
                    estimated_time += RECHTDOOR_TIME;
                }
                break;
            case (FORWARD_WEST):
                if (location.j < 10 && roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = BACKWARD_WEST;
                    estimated_time += ACHTERUIT_TIME;
                } else if (location.i > 0 && roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += RECHTSAF_90_TIME;
                    else
                        estimated_time += RECHTSAF_TIME;
                } else if (location.i < 10 && roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    if (maze.mines_possible[location.i][location.j] == true)
                        estimated_time += LINKSAF_90_TIME;
                    else
                        estimated_time += LINKSAF_TIME;
                } else {
                    location.j--;
                    estimated_time += RECHTDOOR_TIME;
                }
                break;
            case (BACKWARD_NORTH):
                if (roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += LINKSAF_90_TIME;
                } else if (roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += KEREN_TIME;
                } else {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += 1000;
                }
                break;
            case (BACKWARD_EAST):
                if (roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += LINKSAF_90_TIME;
                } else if (roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += KEREN_TIME;
                } else {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += 1000;
                }
                break;
            case (BACKWARD_SOUTH):
                if (roads[x].map[location.i][location.j - 1] == score) {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += LINKSAF_90_TIME;
                } else if (roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += KEREN_TIME;
                } else {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += 1000;
                }
                break;
            case (BACKWARD_WEST):
                if (roads[x].map[location.i - 1][location.j] == score) {
                    location.i--;
                    state = FORWARD_NORTH;
                    estimated_time += RECHTSAF_90_TIME;
                } else if (roads[x].map[location.i + 1][location.j] == score) {
                    location.i++;
                    state = FORWARD_SOUTH;
                    estimated_time += LINKSAF_90_TIME;
                } else if (roads[x].map[location.i][location.j + 1] == score) {
                    location.j++;
                    state = FORWARD_EAST;
                    estimated_time += KEREN_TIME;
                } else {
                    location.j--;
                    state = FORWARD_WEST;
                    estimated_time += 1000;
                }
                break;
                
            }
            addNoMine(&maze, location);
        }
    }
    return estimated_time;
}

static int getTravelTime(Maze maze, State state, Location *location, Location *destination)
{
    calculateRoad(maze.map, location, destination);
    return getEstimatedTime(maze, state, 1, *location, &maze);
}


static void *threadFunction(void *thread_data)
{
    Thread_data *td = thread_data;
    
    Location *location;
    Location *destination;

    for (int i = 0; i < td->thread_runs; ++i) {
        for (int j = 0; j < td->number_of_destinations; ++j) {
            td[i].mazes[j] = td->maze;
            location = td[i].route[j];
            destination = td[i].route[j + 1];
            calculateRoad(td[i].mazes[j].map, location, destination);
        }
        location = td->route[0];
        td[i].estimated_time = getEstimatedTime(td->maze, td->state, td->number_of_destinations, *location, td[i].mazes);
    }

    return NULL;    
}

static List *createInstructions(Maze maze, State state, const int number_of_destinations, Location *location, Maze roads[])
{
    List *instructions = initList(sizeof(Instruction));
    Instruction instruction;
    instruction.location = *location;
    instruction.state = state;
    for (int x = 0; x < number_of_destinations; ++x) {
        for (char score = roads[x].map[instruction.location.i][instruction.location.j] - 1; score > 0; --score) {
            switch (instruction.state) {
            case (FORWARD_NORTH):
                if (instruction.location.i < 10 && roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = BACKWARD_NORTH;
                    instruction.code = ACHTERUIT;
                } else if (instruction.location.j < 10 && roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (instruction.location.j > 0 && roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.i--;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (FORWARD_EAST):
                if (instruction.location.j > 0 && roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = BACKWARD_EAST;
                    instruction.code = ACHTERUIT;
                } else if (instruction.location.i < 10 && roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (instruction.location.i > 0 && roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.j++;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (FORWARD_SOUTH):
                if (instruction.location.i > 0 && roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = BACKWARD_SOUTH;
                    instruction.code = ACHTERUIT;
                } else if (instruction.location.j > 0 && roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (instruction.location.j < 10 && roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.i++;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (FORWARD_WEST):
                if (instruction.location.j < 10 && roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = BACKWARD_WEST;
                    instruction.code = ACHTERUIT;
                } else if (instruction.location.i > 0 && roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = RECHTSAF_90;
                    else
                        instruction.code = RECHTSAF;
                } else if (instruction.location.i < 10 && roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    if (maze.mines_possible[instruction.location.i][instruction.location.j] == true)
                        instruction.code = LINKSAF_90;
                    else
                        instruction.code = LINKSAF;
                } else {
                    instruction.location.j--;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (BACKWARD_NORTH):
                if (roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = RECHTSAF_90;
                } else if (roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = LINKSAF_90;
                } else  if  (roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = KEREN;
                } else {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (BACKWARD_EAST):
                if (roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = RECHTSAF_90;
                } else if (roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = LINKSAF_90;
                } else if (roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = KEREN;
                } else {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (BACKWARD_SOUTH):
                if (roads[x].map[instruction.location.i][instruction.location.j - 1] == score) {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = RECHTSAF_90;
                } else if (roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = LINKSAF_90;
                } else if (roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = KEREN;
                } else {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = RECHTDOOR;
                }
                break;
            case (BACKWARD_WEST):
                if (roads[x].map[instruction.location.i - 1][instruction.location.j] == score) {
                    instruction.location.i--;
                    instruction.state = FORWARD_NORTH;
                    instruction.code = RECHTSAF_90;
                } else if (roads[x].map[instruction.location.i + 1][instruction.location.j] == score) {
                    instruction.location.i++;
                    instruction.state = FORWARD_SOUTH;
                    instruction.code = LINKSAF_90;
                } else if (roads[x].map[instruction.location.i][instruction.location.j + 1] == score) {
                    instruction.location.j++;
                    instruction.state = FORWARD_EAST;
                    instruction.code = KEREN;
                } else {
                    instruction.location.j--;
                    instruction.state = FORWARD_WEST;
                    instruction.code = RECHTDOOR;
                }
                break;
                
            }
            if (roads[x].map[instruction.location.i][instruction.location.j] == 1 && x != number_of_destinations - 1) {
                switch (instruction.state) {
                case (FORWARD_NORTH):
                    if (roads[x + 1].map[instruction.location.i + 1][instruction.location.j] == roads[x + 1].map[instruction.location.i][instruction.location.j] - 1)
                        instruction.code += CHECK_AND_BACK;
                    break;
                case (FORWARD_EAST):
                    if (roads[x + 1].map[instruction.location.i][instruction.location.j - 1] == roads[x + 1].map[instruction.location.i][instruction.location.j] - 1)
                        instruction.code += CHECK_AND_BACK;
                    break;
                case (FORWARD_SOUTH):
                    if (roads[x + 1].map[instruction.location.i - 1][instruction.location.j] == roads[x + 1].map[instruction.location.i][instruction.location.j] - 1)
                        instruction.code += CHECK_AND_BACK;
                    break;
                case (FORWARD_WEST):
                    if (roads[x + 1].map[instruction.location.i][instruction.location.j + 1] == roads[x + 1].map[instruction.location.i][instruction.location.j] - 1)
                        instruction.code += CHECK_AND_BACK;
                    break;
                default: // removes warning 
                    break;
                }
            }
            
            //if not cutting &&  && next location isnot a destination && next location no mine possibe
            if (((instruction.code & CUT) == false) && (roads[x].map[instruction.location.i][instruction.location.j] != 1) && (roads[x].mines_possible[instruction.location.i][instruction.location.j] == false))
                instruction.code += CUT;
            

            addNoMine(&maze, instruction.location);
            addList(instructions, &instruction);
        }
    }

    return instructions;
}

List *approximateInstructions(Maze maze, State state, List *places)
{
    Location *location = getListData(places, 0);
    List *new_places;
    int number_of_destinations;
    /* If places>length is greather than MAX PLACES, create a shorter list */
    if (places->length > MAX_DESTINATIONS + 1) {
        number_of_destinations = places->length - 1;
        Location *destination;
        int travel_time[number_of_destinations];
        for (int i = 0; i < number_of_destinations; ++i) {
            destination = getListData(places, i + 1);
            travel_time[i] = getTravelTime(maze, state, location, destination);
        }

        int lowest_travel_time;
        int best_j;
        new_places = initList(sizeof(Location));
        addList(new_places, location);
        for (int i = 1; i < MAX_DESTINATIONS + 1; ++i) {
            best_j = 0;
            lowest_travel_time = travel_time[0];
            for (int j = 1; j < number_of_destinations; ++j) {
                if (travel_time[j] < lowest_travel_time) {
                    lowest_travel_time = travel_time[j];
                    best_j = j;
                }
            }
            location = getListData(places, best_j + 1);
            addList(new_places, location);
            travel_time[best_j] = INFINITE_INT;
        }

    } else {
        new_places = copyList(places);
    }

    number_of_destinations = new_places->length - 1;
    const int runs = factorial(number_of_destinations);
    Location ***routes = malloc(runs * sizeof(Location**));
    routes[0] = (Location**)convertListToArray(new_places);
    for (int i = 1; i < runs; ++i) {
        routes[i] = malloc(places->length * sizeof(Location**));
    }
    permute(routes, new_places->length);

    Thread_data *thread_data = malloc(runs * sizeof(Thread_data));
    Maze *mazes = malloc(number_of_destinations * runs * sizeof(Maze));
    Maze *current_mazes = mazes;
    int thread_runs = runs / NUMBER_OF_THREADS;
    if (thread_runs == 0) 
        thread_runs = runs;
    for (int i = 0; i < runs; i += thread_runs)
    {
            thread_data[i].maze = maze;
            thread_data[i].state = state;
            thread_data[i].number_of_destinations = number_of_destinations;
            thread_data[i].thread_runs = thread_runs;
            thread_data[i].mazes = current_mazes + i;
            thread_data[i].route = routes[i];
    }
    for (int i = 0; i < runs; ++i) {
        thread_data[i].mazes = current_mazes;
        current_mazes = current_mazes + number_of_destinations;
        thread_data[i].route = routes[i];
    }

    if (runs % NUMBER_OF_THREADS == 0 && NUMBER_OF_THREADS != 1) {
        int thread_data_offset = 0;
        pthread_t *threads = malloc(NUMBER_OF_THREADS * sizeof(pthread_t));
        for (int i = 0; i < NUMBER_OF_THREADS; ++i) {
            pthread_create(&threads[i], NULL, &threadFunction, thread_data + thread_data_offset);
            thread_data_offset += thread_runs;
        }
        // wait till every thread is done
        for (int i = 0; i < NUMBER_OF_THREADS; ++i) {
            pthread_join(threads[i], NULL);
        }
        free(threads);
    } else {
        threadFunction(thread_data);
    }


    /* Choose best route */
    int best_i = 0;
    for (int i = 1; i < runs; ++i) {
        if (thread_data[i].estimated_time < thread_data[best_i].estimated_time)
            best_i = i;
    }
    location = getListData(places, 0);
    List *instructions = createInstructions(maze, state, number_of_destinations, location, thread_data[best_i].mazes);

    /* Cleaning up */
    for (int i = 0; i < runs; ++i) {
        free(routes[i]);
    }
    free(routes);
    free(thread_data);
    free(mazes);
    deleteList(new_places);

    /* returning the instructions list */
    return instructions;
}
