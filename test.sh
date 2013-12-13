#!/bin/bash
## Erstmal ein paar Variablen
file=$(basename "$1" .pdf)
echo "$file"
read -p "Geben sie bitte die Textsprache ein (deu/fra/eng):" lang
read -p "Wieviele Seiten befinden sich auf einer gescannten Seite (1/2)?" pages
if [ "$pages" == 1 ]
        then
                layout=single
        else
                layout=double
fi

## Jetzt ein paar tempaere Ordner
mkdir "$file"_tmp
mv "$file".pdf "$file"_tmp/"$file".pdf
cd "$file"_tmp
mkdir "$file"_s1 "$file"_s2 "$file"_s3 "$file"_s4
mv "$file".pdf "$file"_s1/"$file".pdf
cd "$file"_s1

## Das PDF in einzelteile zerlegen
pdftk "$file".pdf burst
rm "$file".pdf

##PDFs in PGMs kovertieren ###
/usr/local/bin/parallel -v gs -sDEVICE=pgmraw -dNOPAUSE -dBATCH -r270 -sOutputFile=../"$file"_s2/{.}.pgm {} -- *.pdf
cd ..
rm -r "$file"_s1
cd "$file"_s2

## Unpaper! ###
/usr/local/bin/parallel -v unpaper --layout "$layout" -op "$pages" {} ../"$file"_s3/{.}%02d.pgm -- *.pgm

cd ..
rm -r "$file"_s2

# Komprimieren (verlustfrei) #
cd "$file"_s3
/usr/local/bin/parallel -v convert {} ../"$file"_s4/{.}.jpg -- *.pgm
cd ..
rm -r "$file"_s3
cd "$file"_s4
/usr/local/bin/parallel -v jbig2 -v -b J -d -p -s -2 -O {.}.png {} -- *.jpg
rm *.jpg

# OCR und Einzelpdf
/usr/local/bin/parallel -v hocrbash {} {.} -- *.png

# Einzelzeite auf a5 skalieren (repaperize)
/usr/local/bin/parallel -v gs -sDEVICE=pdfwrite -sPAPERSIZE=a5 -r600 -dCompatibilityLevel=1.3 -dEmbedAllFonts=true -dSubsetFonts=true -dMonoImageDownsampleType=/Bicubic -dNOPAUSE -dBATCH -sOutputFile={.}-compressed.pdf {} -- *.pdf
# Ausgabe
pdftk *-compressed.pdf output ../../"$file"_opti.pdf
cd ..
cd ..
rm -r "$file"_tmp

exit
