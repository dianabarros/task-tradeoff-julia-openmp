#include <stdlib.h>
#include <stdio.h>
#include <omp.h>
#include <sys/time.h>

// #ifndef N
// #define N 30
// #endif
#ifndef FS
#define FS 50
#endif

struct node {
   int data;
   int fibdata;
   struct node* next;
};

void print_double_matrix(int m, double *A){
   for(int i = 0; i < m; i++){
      printf("%f ", A[i]);
   } 
   printf("\n");
}

void zero_double_matrix(int m, double *M){
    for(int i = 0; i < m; i++){
        M[i] = 0.0;
    }
}

double get_mean(int m, double *M){
   double cum_sum = 0.0;
   for(int i = 0; i < m; i++){
      cum_sum += M[i];
   }
   return cum_sum/m;
}

double get_max(int m, double *M){
   double max = 0.0;
   for(int i = 0; i < m; i++){
      if(M[i] > max){
         max = M[i];
      }
   }
   return max;
}

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

struct node* init_list(int N,struct node* p) {
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
      p->data = FS + i * 10;
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
   int N_THREADS;
   #pragma omp parallel 
   {
      N_THREADS = omp_get_num_threads();
   }

   struct node *p=NULL;
   struct node *temp=NULL;
   struct node *head=NULL;

   struct timeval tstart, tend;
   double total_execution_time = 0.0;

   // printf("Processar linked list\n");
   // printf("  Cada no da linked list sera processado pela funcao 'processwork()'\n");
   // printf("  Cada no ira computar %d numeros de fibonacci comecando por %d\n",N,FS);      

   double task_start, task_end;
   double task_number;
   double max_task_time;
   double mean_task_time;
   double task_time;
   double imbalance;
   double task_times[N_THREADS];
   double max_task_times[N_THREADS];

   zero_double_matrix(N_THREADS,task_times);
   zero_double_matrix(N_THREADS, max_task_times);
   for(int i=0; i<runs; i++) {
      p = init_list(N, p);
      head = p;
      struct node *vetor_aux[N];

      task_number = 0.0;
      max_task_time = 0.0;

      gettimeofday(&tstart, NULL);
      for (int i = 0; i < N; i++) {
         vetor_aux[i] = p;
         p = p->next;
      }
      #ifdef _OPENMP
         #pragma omp parallel
         #pragma omp for
      #endif
      for (int i = 0; i < N; i++) { 
         task_number++;
         task_start = omp_get_wtime(); 

         processwork(vetor_aux[i]);

         task_end = omp_get_wtime(); 
         task_time = (task_end - task_start) * 1000000.0;
         if (task_time > max_task_times[omp_get_thread_num()]){
            max_task_times[omp_get_thread_num()] = task_time;
         }
         task_times[omp_get_thread_num()] += task_time;
      }   
      gettimeofday(&tend, NULL);

      mean_task_time = get_mean(N_THREADS, task_times); 
      max_task_time = get_max(N_THREADS, task_times);
      imbalance = (max_task_time/mean_task_time - 1.0) * 100.0;
      p = head;
      while (p != NULL) {
         temp = p->next;
         free (p);
         p = temp;
      }  
      free (p);

      total_execution_time += (tend.tv_sec - tstart.tv_sec) + (tend.tv_usec - tstart.tv_usec) / 1000000.0;
   }

   printf("linked_for,%d,%f,%f\n",N,total_execution_time/runs,imbalance);

   return 0;
}

