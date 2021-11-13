#include <stdlib.h>
#include <stdio.h>
#include <omp.h>
#include <sys/time.h>

// #ifndef N
// #define N 5
// #endif
#ifndef FS
#define FS 38
#endif

struct node {
   int data;
   int fibdata;
   struct node* next;
};

int fib(int n) {
   int x, y;
   if (n < 2) {
      return (n);
   } else {
      x = fib(n - 1);
      y = fib(n - 2);
	  return (x + y);
   }
}

int fib_loop(int n) {
   int nth;
   int n1 = 0, n2 = 1;
   int count = 0;
   if (n > 1) {
      while (count < n){
         nth = n1 + n2;
         n1 = n2;
         n2 = nth;
         count += 1;
      }
   }
   return (n1);
}

void processwork(struct node* p) 
{
   p->fibdata = fib_loop(p->data);
}

struct node* init_list(int N, struct node* p) {
   int i;
   struct node* head = NULL;
   struct node* temp = NULL;
   
   head = (struct node*)malloc(sizeof(struct node));
   p = head;
   p->data = FS;
   p->fibdata = 0;
   for (i=0; i< N; i++) {
      temp  =  (struct node*)malloc(sizeof(struct node));
      p->next = temp;
      p = temp;
      p->data = FS + i + 1;
      p->fibdata = i+1;
   }
   p->next = NULL;
   return head;
}

int main(int argc, char *argv[]) {

   if (argc != 3) {
      printf("Run ./linked_omp_for <N> <runs>\n");
      exit(0);
   }

   int N = atoi(argv[1]);
   int runs = atoi(argv[2]);

   double start, end;
   struct node *p=NULL;
   struct node *temp=NULL;
   struct node *head=NULL;

   struct timeval tstart, tend;
   double total_execution_time = 0.0;

   // printf("Processar linked list\n");
   // printf("  Cada no da linked list sera processado pela funcao 'processwork()'\n");
   // printf("  Cada no ira computar %d numeros de fibonacci comecando por %d\n",N,FS);      

   for(int i=0; i<runs; i++) {
      p = init_list(N, p);
      head = p;

      gettimeofday(&tstart, NULL);
      
      #ifdef _OPENMP
      #pragma omp parallel 
      #endif
      {
         #ifdef _OPENMP
         #pragma omp single
         #endif
         {
            while (p != NULL) {
               #ifdef _OPENMP
               #pragma omp task firstprivate(p)
               #endif
               {
               processwork(p);
               }
               
               p = p->next;
            }
         }
      }

      gettimeofday(&tend, NULL);

      p = head;
      while (p != NULL) {
         // printf("%d : %d\n",p->data, p->fibdata);
         temp = p->next;
         free (p);
         p = temp;
      }  
      free (p);
      
      total_execution_time += (tend.tv_sec - tstart.tv_sec) + (tend.tv_usec - tstart.tv_usec) / 1000000.0;
   }

   printf("linked_task,%d,%f\n",N,total_execution_time/runs);


   return 0;
}

