export OMP_NUM_THREADS=4;

echo "func,size,time";
./linked_omp 100 10;
./linked_omp 1000 10;
./linked_omp 10000 10;
./linked_omp_for 100 10;
./linked_omp_for 1000 10;
./linked_omp_for 10000 10;
./linked_omp_task 100 10;
./linked_omp_task 1000 10;
./linked_omp_task 10000 10;