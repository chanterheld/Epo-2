#include "state.h"

State setState(int code)
{
    switch (code)
    {
        case(1):
        case(2):
        case(3):
            return FORWARD_NORTH;
            break;
        case(4):
        case(5):
        case(6):
            return FORWARD_WEST;
            break;
        case(7):
        case(8):
        case(9):
            return FORWARD_SOUTH;
            break;
        case(10):
        case(11):
        case(12):
            return FORWARD_EAST;
            break;
        default:
        // this should never happen but removes warning
            return FORWARD_NORTH;
    }
}
