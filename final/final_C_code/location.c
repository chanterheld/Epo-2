#include "location.h"

Location setLocation(int code)
{
    Location location;

	switch (code)
	{
		case (1):
			location.i = 10;
			location.j = 3;
			break;
		case (2):
			location.i = 10;
			location.j = 5;
			break;
		case (3):
			location.i = 10;
			location.j = 7;
			break;
		case (4):
			location.i = 7;
			location.j = 10;
			break;
		case (5):
			location.i = 5;
			location.j = 10;
			break;
		case (6):
			location.i = 3;
			location.j = 10;
			break;
		case (7):
			location.i = 0;
			location.j = 7;
			break;
		case (8):
			location.i = 0;
			location.j = 5;
			break;
		case (9):
			location.i = 0;
			location.j = 3;
			break;
		case (10):
			location.i = 3;
			location.j = 0;
			break;
		case (11):
			location.i = 5;
			location.j = 0;
			break;
		case (12):
			location.i = 7;
			location.j = 0;
			break;
	}

    return location;
}

void swapLocation(Location **a , Location **b)
{
	Location *temp = *a;
	*a = *b;
	*b = temp;
}
