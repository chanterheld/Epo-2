#include "math.h"
#include <string.h>
#include "location.h"

int factorial (int x)
{
    if (x == 0)
        return 1;
    return (x * factorial(x - 1));
}

//http://www.quickperm.org; modified version 
void permute(Location ***route, int number_of_places)
{
    const int N = number_of_places - 1;
    int permute[N + 1];
    int i = 1;
    int j;
    int count = 0;
    for (int i = 0; i < N + 1; i++) {
        permute[i] = i;
    }
    while (i < N) {
        --permute[i];
        j = (i & 1) * permute[i];
		memcpy(route[count + 1], route[count], number_of_places * sizeof(Location*));
        ++count;
        swapLocation(&route[count][j + 1], &route[count][i + 1]);
        i = 1;
        while(permute[i] == 0) {
            permute[i] = i;
            ++i;
        }
    }
}
