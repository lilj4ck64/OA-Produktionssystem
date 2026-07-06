#!/bin/sh

echo "--------------------------------------------"
echo "Generiere elektronische Dokumente für Projekt: $1"
echo "--------------------------------------------"

echo "Transformiere BITS nach XHTML"
#Java -jar Werkzeuge/Transformationstool/saxon_he_10.5/saxon-he-10.5.jar -s:Projekte/$1/Strukturierte_Daten/$1.xml -xsl:Stylesheets/XMLtoEPUB.xsl Projekt=$1

java -jar Werkzeuge/Transformationstool/saxon-he-12.0/saxon-he-12.0.jar -s:Projekte/$1/Strukturierte_Daten/$1.xml -xsl:Stylesheets/XMLtoEPUB.xsl Projekt=$1

echo "--------------------------------------------"
echo "Kopiere Bilddateien"
echo "--------------------------------------------"

echo "--------------------------------------------"
echo "Arbeitsverzeichnis: "; pwd
echo "--------------------------------------------"

echo "--------------------------------------------"
echo "Verzeichnisse anlegen: "
#mkdir Projekte/$1/Outputs/E-Formate/
#mkdir Projekte/$1/Outputs/E-Formate/OEBPS
#mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Images

mkdir Projekte/$1/Outputs/E-Formate/ -p
mkdir Projekte/$1/Outputs/E-Formate/OEBPS -p
mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Images -p
echo "--------------------------------------------"

echo "--------------------------------------------"
echo "Struktur E-Formate angelegt"
ls Projekte/$1/Outputs 
echo "--------------------------------------------"


cp Projekte/$1/Media/Images/* Projekte/$1/Outputs/E-Formate/OEBPS/Images

echo "Kopiere Stylesheets"
#mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Styles

mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Styles -p
cp Stylesheets/HTWK-OAVerlag.css Projekte/$1/Outputs/E-Formate/OEBPS/Styles

echo "Kopiere Schriften"
#mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Fonts

mkdir Projekte/$1/Outputs/E-Formate/OEBPS/Fonts -p
cp -R Fonts/* Projekte/$1/Outputs/E-Formate/OEBPS/Fonts

echo "Zippe EPUB-Format"

cd Projekte/$1/Outputs/E-Formate

<<comment 
zip -r -mx=0 $1.epub mimetype
zip -r $1.epub META-INF/*
zip -r $1.epub OEBPS/*

zip -rn $1.epub mimetype !mimetype
unzip $1.epub !mimetype
zip -d $1.epub !mimetype
zip $1.epub !mimetype
zip -rn $1.epub !mimetype mimetype
rm !mimetype
comment

zip -0 -X "$1.epub" mimetype
zip -r "$1.epub" META-INF/* OEBPS/* -x mimetype
rm mimetype

#echo "Prüfe EPUB mit EPUB-Checker"
#../../../../Werkzeuge/EPUB-Checker/EPUB-Checker.app


cd ../../../..