#ifndef STATE_H
#define STATE_H

typedef enum State
{
    FORWARD_NORTH   = 1,
    FORWARD_EAST    = 2,
    FORWARD_SOUTH   = 3,
    FORWARD_WEST    = 4,
    BACKWARD_NORTH  = -1,
    BACKWARD_EAST   = -2,
    BACKWARD_SOUTH  = -3,
    BACKWARD_WEST   = -4
} State;

State setState(int code);

#endif /* STATE_H */
