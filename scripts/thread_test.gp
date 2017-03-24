reset
set terminal png size 2000
set ylabel 'time(sec)'
set style fill solid
set title 'Different thread append() perfomance comparision (from 1 to 128 thread)'
set term png enhanced font 'Verdana,10'
set output 'thread_test_append.png'

plot [:][:0.02]'opt.txt' using 4:xtic(1) with histogram title 'optimized'

set title 'Different thread findName() perfomance comparision (from 1 to 128 thread)'
set output 'thread_test_findName.png'

plot [:][:0.02]'opt.txt' using 5:xtic(1) with histogram title 'optimized'
