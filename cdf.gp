load 'config-output-pdf.gp'

set ylabel "Cumulative Fraction"
set yrange [0:1]
set key right bottom

plot for [i=1:words(datafiles)] word(datafiles,i) u 2:1 w l ls i t word(titles, i)
