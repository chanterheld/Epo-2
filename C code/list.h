#ifndef LIST_H
#define LIST_H

typedef struct Node
{
    void *data;
    struct Node *next;
} Node;

typedef struct List
{
    int length;
    int data_size;
    Node *head;
    Node *add_node;
    Node *data_node;
    int data_index;

} List;

List *initList(int data_size);
void addList(List *list, void *data);
void removeIndex(List *list, int index);
void setList(List *list, int index, void *data);
void *getListData(List *list, int index);
void **convertListToArray(List *list);
List *copyList(List *list);
void deleteList(List *list);

#endif /* LIST_H */
