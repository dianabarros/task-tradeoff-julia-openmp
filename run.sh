start_time=$(date +%s);
echo "Compiling...";
gcc linked_omp.c -o linked &&
gcc linked_omp_for.c -o linked_for -fopenmp && 
gcc linked_omp_task.c -o linked_task -fopenmp && 
for i in 2 4 8 16; do
    echo "Running Julia Linked List with $i threads.";
    julia -t $i linked_list.jl;
    echo "Running C Linked List with $i threads.";
    OMP_NUM_THREADS=$i ./linked 1000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked 10000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked 100000 10 >> c_executions_t${i}.csv;
    echo "Running OpenMP For Linked List with $i threads.";
    OMP_NUM_THREADS=$i ./linked_for 1000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked_for 10000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked_for 100000 10 >> c_executions_t${i}.csv;
    echo "Running OpenMP Task Linked List with $i threads.";
    OMP_NUM_THREADS=$i ./linked_task 1000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked_task 10000 10 >> c_executions_t${i}.csv;
    OMP_NUM_THREADS=$i ./linked_task 100000 10 >> c_executions_t${i}.csv;
done;
end_time=$(date +%s);
elapsed=$(( end_time - start_time ));
eval "echo Elapsed time: $(date -ud "@$elapsed" +'$((%s/3600/24)) days %H hr %M min %S sec')";