#ifndef LOCATION_H
#define LOCATION_H

typedef struct Location
{
    int i;
    int j;
} Location;

Location setLocation(int code);
void swapLocation(Location **a , Location **b);

#endif /* LOCATION_H */
