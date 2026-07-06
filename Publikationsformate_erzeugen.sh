#!/bin/sh

clear


echo "Projektname: $1";

#mkdir Projekte/$1/Outputs

mkdir Projekte/$1/Outputs -p

echo "Output-Ordner des Projekts leeren"
#rm Projekte/$1/Outputs/* /F /Q
#rmdir Projekte/$1/Outputs/E-Formate /S /Q
rm -rf Projekte/$1/Outputs/*
rm -rf Projekte/$1/Outputs/E-Formate

#echo "Erstellung eines highres PDF mit Apache FOP"
bash 02_pdf-print.sh $1

#echo "Erstellung eines lowres PDF mit Apache FOP"
bash 03_pdf-web.sh $1

echo "EPUB-Ausgabeformat generieren"
bash 04_epub.sh $1

/*
Wenn der Kindle-Previewer auf dem System installiert ist,
Kann der Workflow erweitert werden, indem auch eine Ausgabe
Als MOBI aus dem EPUB-File erzeugt wird. Dazu bitte die
Kommentare um den nachfolgenden Aufruf entfernen
*/
/*
echo "Erstellung des MOBI-Formats aus EPUB"
bash 05_mobi.sh
*/

cd Projekte/$1/Outputs/
open .