#include "list.h"
#include <stdlib.h>
#include <string.h>
#include <stdio.h> //debugging

// NOTE: THIS IS NOT CORRECT ATM! FULL OFF BUGS

List *initList(int data_size)
{
    List *list = malloc(sizeof(List));
    list->data_size = data_size;
    list->head = malloc(sizeof(Node));
    list->head->next = NULL;
    list->length = 0;
    list->add_node = list->head;
    list->data_node =  list->head;
    list->data_index = 0;

    return list;
}

void addList(List *list, void *data)
{
    while (list->add_node->next != NULL) {
        list->add_node = list->add_node->next;
    }
    list->add_node->data = malloc(list->data_size);
    memcpy(list->add_node->data, data, list->data_size);
    list->add_node->next = malloc(sizeof(Node));
    list->add_node->next->next = NULL;
    list->add_node->next->data = NULL;
    list->add_node = list->add_node->next;
    list->length++;
}

void removeIndex(List *list, int index)
{
    if (index == 0) {
        Node *temp = list->head->next;
        free(list->head->data);
        free(list->head);
        list->head = temp;
    } else {
        Node *current = list->head;
        for (int i = 1; i < index; ++i) {
            current = current->next;
        }
        Node *temp = current->next->next;
        free(current->next->data);
        free(current->next);
        current->next = temp;
    }

    list->length--;
    list->data_index = 0;
    list->data_node = list->head;
    list->add_node = list->head;
}

void setList(List *list, int index, void *data)
{
    Node *current = list->head;
    for (int i = 0;i < index; ++i) {
        current = current->next;
    }
    memcpy(current->data, data, list->data_size);
}

void *getListData(List *list, int index)
{
    if (index == list->data_index) {
        //printf("getting next data fast, index: %d, data_index: %d\n", index, list->data_index); // debugging
        void *data = list->data_node->data;
        list->data_node = list->data_node->next;
        list->data_index++;
        return data;
    }
    Node *current = list->head;
    for (int i = 0; i < index; ++i) {
        current = current->next;
    }
    if (list->data_node->next != NULL) {
        list->data_node = current->next;
        list->data_index = index + 1;
    } else {
        list->add_node = current;
    }
    return current->data;
}

void **convertListToArray(List *list)
{
    void **array = malloc(list->length * sizeof(void*));
    for (int i = 0; i < list->length; ++i) {
        array[i] = getListData(list, i);
    }

    return array;
}

List *copyList(List *list)
{
    List *copy_list = initList(list->data_size);
    void *data;
    for (int i = 0; i < list->length; ++i) {
        data = getListData(list, i);
        addList(copy_list, data);
    }
    return copy_list;
}

// can't delete empty list
void deleteList(List *list)
{
    Node *current = list->head;
    Node *tmp;
    while (current != NULL)
    {
        tmp = current->next;
        free(current->data);
        free(current);
        current = tmp;
    }
    free(current);
    free(list);
}
