set term pdf font 'Helvetica,15' linewidth 2

# margins
set tmargin 0.5
set rmargin 0.5

# labels and tics
set xlabel font ",24" offset 0,0.5
set ylabel font ",24"
set xtics font ",18" offset 0,0.25 nomirror
set ytics font ",18" offset 0.5,0 nomirror
set tics scale 0

# key configuration
set key font ",18"
set key samplen 2
set key width 0.15
set key spacing 0.75
set key nobox

set grid xtics ytics

set datafile separator ","

set style line 1 lc rgb "#006195C5"    # blue
set style line 2 lc rgb "#00CE6562"    # red
set style line 3 lc rgb "#00A000FF"    # purple
set style line 4 lc rgb "orange"
set style line 5 lc rgb "black"

