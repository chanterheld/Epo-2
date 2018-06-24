#include "menu.h"
#include <stdio.h>
#include "challenge.h"
#include <windows.h>

void menu()
{
    char challenge;
    int a, b, c, d;

    printf("Enter the challenge (A, B, C)\n");
    scanf("%c", &challenge);

    switch (challenge) {
    case ('a'):
    case ('A'):
        printf("Enter staring location followed by three destinations\n");
        scanf("%d %d %d %d", &a, &b, &c, &d);
        if (a < 1 || a > 12 || b < 1 || b > 12 || c < 1 || c > 12 || d < 1 || d > 12) {
            printf("Illegal location/destination, exiting\n");
            return;
        }
        challengeA(a, b, c, d);
        break;
    case ('b'):
    case ('B'):
        printf("Enter staring location followed by three destinations\n");
        scanf("%d %d %d %d", &a, &b, &c, &d);
        if (a < 1 || a > 12 || b < 1 || b > 12 || c < 1 || c > 12 || d < 1 || d > 12) {
            printf("Illegal location/destination, exiting\n");
            return;
        }
        challengeB(a, b, c, d);
        break;
    case ('c'):
    case ('C'):
        printf("Enter 1 for part one and 2 for part 2\n");
        scanf("%d", &a);
        if (a == 1)
            challengeC_part_1();
        else if (a == 2)
            challengeC_part_2();
        else
            printf("Wrong part entered\n");
        break;
    default:
        printf("Wrong challenge Entered\n");
        return;
        break;
    }

    printf("Exiting");
    for (int i = 0; i < 3; ++i) {
        putchar('.');
        Sleep(500);
    }
    putchar('\n');
}