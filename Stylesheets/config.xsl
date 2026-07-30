<?xml version="1.0" encoding="UTF-8"?>

<!--  
Konfigurationsstylesheet für PDF-Erstellung
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet 	version="2.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:fo="http://www.w3.org/1999/XSL/Format">

<!-- Welches Druckformat soll ausgegeben werden?
	 Druckformate:  F1 = 15,5 x 22 cm   F2 = 17 x 24 cm -->
	 
<xsl:variable name="Druckformat">F2</xsl:variable>

<!-- Welches Ausgabeformat soll ausgegeben werden?
	 Ausgabeformate:  PDF / Hardcover / Softcover / ePub -->
	 
<xsl:variable name="Ausgabeformat">Hardcover</xsl:variable>

<!-- Logo-Dateiname -->
<xsl:variable name="Logo">HTWK_Logo.jpg</xsl:variable>

<!-- *****************************************************
  Format und Stege
********************************************************* -->

<!-- Definition Seitenhöhe -->
<xsl:variable name="Seitenhoehe">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">220mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">240mm</xsl:when>
		<xsl:otherwise>240mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Definition Seitenbreite -->
<xsl:variable name="Seitenbreite">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">155mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">170mm</xsl:when>
		<xsl:otherwise>170mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Definition Satzspiegelhöhe -->
<xsl:variable name="Satzspiegelhoehe">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">174mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">191mm</xsl:when>
		<xsl:otherwise>191mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Definition Satzspiegelbreite -->
<xsl:variable name="Satzspiegelbreite">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">114mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">124mm</xsl:when>
		<xsl:otherwise>124mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
  
<!-- Definition Stege -->
<xsl:variable name="Kopfsteg">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">13mm</xsl:when>
		<xsl:otherwise>13mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Fusssteg">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">18mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">20mm</xsl:when>
		<xsl:otherwise>20mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Bundsteg">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">19mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">22mm</xsl:when>
		<xsl:otherwise>22mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Aussensteg">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">22mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">24mm</xsl:when>
		<xsl:otherwise>24mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Überschriften
********************************************************* -->

<xsl:variable name="Abstand_Label_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">4mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">4mm</xsl:when>
		<xsl:otherwise>4mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift 1. Ordnung -->
<xsl:variable name="Schriftart_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">16.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">18pt</xsl:when>
		<xsl:otherwise>18pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">20pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">20.5pt</xsl:when>
		<xsl:otherwise>20.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0mm</xsl:when>
		<xsl:otherwise>0mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">10mm</xsl:when>
		<xsl:otherwise>10mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Liniendicke_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.75pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.75pt</xsl:when>
		<xsl:otherwise>0.75pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Linienlaenge_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">39mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">41mm</xsl:when>
		<xsl:otherwise>41mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h1">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">9mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">9mm</xsl:when>
		<xsl:otherwise>9mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h1_ohneLabel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0mm</xsl:when>
		<xsl:otherwise>0mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h1_ohneLabel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0mm</xsl:when>
		<xsl:otherwise>0mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift 2. Ordnung -->
<xsl:variable name="Schriftart_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">13pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">14pt</xsl:when>
		<xsl:otherwise>14pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">16pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">17pt</xsl:when>
		<xsl:otherwise>17pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h2_nach_h">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">12mm</xsl:when>
		<xsl:otherwise>12mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift 3. Ordnung -->
<xsl:variable name="Schriftart_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">15pt</xsl:when>
		<xsl:otherwise>15pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h3_nach_h">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h3">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">13mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">13mm</xsl:when>
		<xsl:otherwise>13mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift 4. Ordnung -->
<xsl:variable name="Schriftart_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBoldItalic</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBoldItalic</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBoldItalic</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">15pt</xsl:when>
		<xsl:otherwise>15pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h4_nach_h">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h4">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">16mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">16mm</xsl:when>
		<xsl:otherwise>16mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift 5. Ordnung -->
<xsl:variable name="Schriftart_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Italic</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Italic</xsl:when>
		<xsl:otherwise>Source Sans Pro Italic</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">15pt</xsl:when>
		<xsl:otherwise>15pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h5_nach_h">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h5">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">17mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">17mm</xsl:when>
		<xsl:otherwise>17mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Anhang Überschrift 2. Ordnung -->
<xsl:variable name="Label_Separation_h_A2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_h_A2">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">16mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">16mm</xsl:when>
		<xsl:otherwise>16mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Überschrift ohne Nummerierung -->
<xsl:variable name="Schriftart_h_ohneNummerierung">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Semibold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Semibold</xsl:when>
		<xsl:otherwise>Source Serif Pro Semibold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Zwischentitel -->
<xsl:variable name="Schriftart_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">23pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">26pt</xsl:when>
		<xsl:otherwise>26pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">24pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">27pt</xsl:when>
		<xsl:otherwise>27pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">25mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">25mm</xsl:when>
		<xsl:otherwise>25mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_Zwischentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">22mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">22mm</xsl:when>
		<xsl:otherwise>22mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Fließtext
********************************************************* -->
<xsl:variable name="Grundschriftart">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Regular</xsl:when>
		<xsl:otherwise>Source Serif Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Grundschriftgroesse">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">9.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">9.5pt</xsl:when>
		<xsl:otherwise>9.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Grundschrift_Zeilenabstand">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Satzart">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">justify</xsl:when>
		<xsl:when test="$Druckformat='F2'">justify</xsl:when>
		<xsl:otherwise>justify</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Fußnoten
********************************************************* -->
<xsl:variable name="Schriftgroesse_Fussnote">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">7.8pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">7.8pt</xsl:when>
		<xsl:otherwise>7.8pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Fussnote_unten">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">7pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">7pt</xsl:when>
		<xsl:otherwise>7pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Fussnote">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">10pt</xsl:when>
		<xsl:otherwise>10pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Laenge_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">39mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">41mm</xsl:when>
		<xsl:otherwise>41mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Dicke_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.75pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.75pt</xsl:when>
		<xsl:otherwise>0.75pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Muster_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">rule</xsl:when>
		<xsl:when test="$Druckformat='F2'">rule</xsl:when>
		<xsl:otherwise>rule</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Style_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">solid</xsl:when>
		<xsl:when test="$Druckformat='F2'">solid</xsl:when>
		<xsl:otherwise>solid</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">5mm</xsl:when>
		<xsl:otherwise>5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Fussnotenlinie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Baseline_shift_Fussnote">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">25%</xsl:when>
		<xsl:when test="$Druckformat='F2'">25%</xsl:when>
		<xsl:otherwise>25%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Fussnote_imText">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">70%</xsl:when>
		<xsl:when test="$Druckformat='F2'">70%</xsl:when>
		<xsl:otherwise>70%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_Fußnote_Text">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Einzug
********************************************************* -->
<xsl:variable name="Einzug">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">8mm</xsl:when>
		<xsl:otherwise>8mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="kein_Einzug">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0mm</xsl:when>
		<xsl:otherwise>0mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Satzarten, Ausrichtung
********************************************************* -->
<xsl:variable name="Blocksatz">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">justify</xsl:when>
		<xsl:when test="$Druckformat='F2'">justify</xsl:when>
		<xsl:otherwise>justify</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="linksbündig">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">left</xsl:when>
		<xsl:when test="$Druckformat='F2'">left</xsl:when>
		<xsl:otherwise>left</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="rechtsbündig">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">right</xsl:when>
		<xsl:when test="$Druckformat='F2'">right</xsl:when>
		<xsl:otherwise>right</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="zentriert">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">center</xsl:when>
		<xsl:when test="$Druckformat='F2'">center</xsl:when>
		<xsl:otherwise>center</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Silbentrennung
********************************************************* -->

<!-- Silbentrennung NEIN -->
<xsl:variable name="Silbentrennung_nein">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">false</xsl:when>
		<xsl:when test="$Druckformat='F2'">false</xsl:when>
		<xsl:otherwise>false</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Silbentrennung JA -->
<xsl:variable name="Silbentrennung_ja">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">true</xsl:when>
		<xsl:when test="$Druckformat='F2'">true</xsl:when>
		<xsl:otherwise>true</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Silbentrennungssprache -->
<xsl:variable name="Silbentrennung_deutsch">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">de</xsl:when>
		<xsl:when test="$Druckformat='F2'">de</xsl:when>
		<xsl:otherwise>de</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Auszeichnungen
********************************************************* -->
<xsl:variable name="Fließtext_Italic">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Italic</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Italic</xsl:when>
		<xsl:otherwise>Source Serif Pro Italic</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellen_Italic">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Italic</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Italic</xsl:when>
		<xsl:otherwise>Source Sans Pro Italic</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellen_Bold">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Bold</xsl:when>
		<xsl:otherwise>Source Sans Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Fließtext_Bold">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Bold</xsl:when>
		<xsl:otherwise>Source Serif Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Fließtext_Semibold">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Semibold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Semibold</xsl:when>
		<xsl:otherwise>Source Serif Pro Semibold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellen_Semibold">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Fließtext_Monospace">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Code Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Code Pro Regular</xsl:when>
		<xsl:otherwise>Source Code Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="SG_Monospace">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen Schusterjungen/Hurenkinder
********************************************************* -->
<xsl:variable name="Schusterjunge_Einstellung">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2</xsl:when>
		<xsl:when test="$Druckformat='F2'">2</xsl:when>
		<xsl:otherwise>2</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Hurenkind_Einstellung">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2</xsl:when>
		<xsl:when test="$Druckformat='F2'">2</xsl:when>
		<xsl:otherwise>2</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen hoch- und tiefgestellte Ziffern
********************************************************* -->
<xsl:variable name="hochgestellt_baseline-shift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">25%</xsl:when>
		<xsl:when test="$Druckformat='F2'">25%</xsl:when>
		<xsl:otherwise>25%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="tiefgestellt_baseline-shift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">-15%</xsl:when>
		<xsl:when test="$Druckformat='F2'">-15%</xsl:when>
		<xsl:otherwise>-15%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="hoch-tiefgestellt_Schriftgroesse">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">60%</xsl:when>
		<xsl:when test="$Druckformat='F2'">60%</xsl:when>
		<xsl:otherwise>60%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="hoch-tiefgestellt_Einzug_Ziffer">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">-3.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">-3.5pt</xsl:when>
		<xsl:otherwise>-3.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für Tabellen
********************************************************* -->

<xsl:variable name="Schriftart_Kopfzelle">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Bold</xsl:when>
		<xsl:otherwise>Source Sans Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Koerperzelle">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Regular</xsl:when>
		<xsl:otherwise>Source Sans Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Tabelle">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Tabelle">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Tabellenueberschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Tabellenlabel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Bold</xsl:when>
		<xsl:otherwise>Source Serif Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenueberschrift_Abstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2mm</xsl:when>
		<xsl:otherwise>2mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_Tabellenueberschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_Tabellenueberschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">15mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">15mm</xsl:when>
		<xsl:otherwise>15mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenkoerper_Linie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.25pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.25pt</xsl:when>
		<xsl:otherwise>0.25pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenkoerper_Innenabstand_oben">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenkoerper_Innenabstand_unten">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1mm</xsl:when>
		<xsl:otherwise>1mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenkoerper_Innenabstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">5mm</xsl:when>
		<xsl:otherwise>5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabellenkopf_Linie">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.5pt</xsl:when>
		<xsl:otherwise>0.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabelle_Abstand_davor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Tabelle_Abstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für Abbildungen
********************************************************* -->

<xsl:variable name="Schriftgroesse_Abbildung">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Abbildungsunterschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12pt</xsl:when>
		<xsl:otherwise>12pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildungsunterschrift_Abstand_davor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2mm</xsl:when>
		<xsl:otherwise>2mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildungsunterschrift_Abstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildungsunterschrift_Einzug">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">-30mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">-30mm</xsl:when>
		<xsl:otherwise>-30mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildung_Abstand_davor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildung_Abstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abbildung_max_Hoehe">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">174mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">180mm</xsl:when>
		<xsl:otherwise>180mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Separation_Abbildungsunterschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Label_Start_Abbildungsunterschrift">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">15mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">15mm</xsl:when>
		<xsl:otherwise>15mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für Formeln als Grafiken
********************************************************* -->

<xsl:variable name="Formelgrafik_Abstand_danach">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Formelgrafik_Skalierung">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">60%</xsl:when>
		<xsl:when test="$Druckformat='F2'">60%</xsl:when>
		<xsl:otherwise>60%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Formellabel_Einzug">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">-40mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">-40mm</xsl:when>
		<xsl:otherwise>-40mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
 Variablen für Listen
********************************************************* -->

<xsl:variable name="Abstand_danach_Listen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Listen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_Listenlabel_Listentext">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">5.6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">5.6mm</xsl:when>
		<xsl:otherwise>5.6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Einzug_verschachtelte_Liste">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für Quellcode
********************************************************* -->

<xsl:variable name="Schriftart_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Code Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Code Pro Regular</xsl:when>
		<xsl:otherwise>Source Code Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Ueberschrift_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Code Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Code Pro Bold</xsl:when>
		<xsl:otherwise>Source Code Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Quellcode">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für Textboxen
********************************************************* -->

<xsl:variable name="Schriftgroesse_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">10pt</xsl:when>
		<xsl:otherwise>10pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">4mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">4mm</xsl:when>
		<xsl:otherwise>4mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">4mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">4mm</xsl:when>
		<xsl:otherwise>4mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_innen_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Hintergrundfarbe_Textboxen">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">#e5e5e5</xsl:when>
		<xsl:when test="$Druckformat='F2'">#e5e5e5</xsl:when>
		<xsl:otherwise>#e5e5e5</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für den lebenden Kolumnentitel
********************************************************* -->

<xsl:variable name="Abstand_Pagina_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">3mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">3mm</xsl:when>
		<xsl:otherwise>3mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_Label_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1.5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1.5mm</xsl:when>
		<xsl:otherwise>1.5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Text Kolumnentitel -->
<xsl:variable name="Schriftart_lebender_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Regular</xsl:when>
		<xsl:otherwise>Source Sans Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_lebender_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.0pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.0pt</xsl:when>
		<xsl:otherwise>8.0pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Breite_Text_lebender_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10.7cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.7cm</xsl:when>
		<xsl:otherwise>11.7cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_lebender_Kolumnentitel_Satzspiegel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">11.8mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.8mm</xsl:when>
		<xsl:otherwise>11.8mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_DOI_Satzspiegel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">5mm</xsl:when>
		<xsl:otherwise>5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Pagina Kolumnentitel -->
<xsl:variable name="Schriftart_Kolumnentitel_Pagina">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Bold</xsl:when>
		<xsl:otherwise>Source Sans Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Kolumnentitel_Pagina">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Breite_Pagina_lebender_Kolumnentitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.7cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.7cm</xsl:when>
		<xsl:otherwise>0.7cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für den Schmutztitel
********************************************************* -->

<xsl:variable name="Textausrichtung_Schmutztitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">right</xsl:when>
		<xsl:when test="$Druckformat='F2'">right</xsl:when>
		<xsl:otherwise>right</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<xsl:variable name="Sperrung_Autor_Schmutztitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1.2pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">1.275pt</xsl:when>
		<xsl:otherwise>1.275pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Autor im Schmutztitel-->
<xsl:variable name="Schriftgroesse_Schmutztitel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.5pt</xsl:when>
		<xsl:otherwise>8.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Schmutztitel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Schmutztitel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Schmutztitel_mehrereAutoren">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">4.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">4.5pt</xsl:when>
		<xsl:otherwise>4.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Schmutztitel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1.5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1.5mm</xsl:when>
		<xsl:otherwise>1.5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Titel im Schmutztitel -->
<xsl:variable name="Schriftgroesse_Schmutztitel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.5pt</xsl:when>
		<xsl:otherwise>11.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Schmutztitel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Regular</xsl:when>
		<xsl:otherwise>Source Sans Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Schmutztitel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">14.5pt</xsl:when>
		<xsl:otherwise>14.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Schmutztitel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0mm</xsl:when>
		<xsl:otherwise>0mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Untertitel im Schmutztitel -->
<xsl:variable name="Schriftgroesse_Schmutztitel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">9pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">9pt</xsl:when>
		<xsl:otherwise>9pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Schmutztitel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Light</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Light</xsl:when>
		<xsl:otherwise>Source Sans Pro Light</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Schmutztitel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">14pt</xsl:when>
		<xsl:otherwise>14pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für den Titel
********************************************************* -->

<!-- Variablen für HTWK-Logo im Titel -->
<xsl:variable name="Skalierung_Logo_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">32%</xsl:when>
		<xsl:when test="$Druckformat='F2'">32%</xsl:when>
		<xsl:otherwise>32%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Logo_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">162.5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">178.5mm</xsl:when>
		<xsl:otherwise>174.5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Autor im Titel -->
<xsl:variable name="Schriftgroesse_Titel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">11pt</xsl:when>
		<xsl:otherwise>11pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Titel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro SemiBold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro SemiBold</xsl:when>
		<xsl:otherwise>Source Sans Pro SemiBold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Titel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Sperrung_Titel_Autor">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">1.65pt</xsl:when>
		<xsl:otherwise>1.65pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Titel im Titel -->
<xsl:variable name="Schriftgroesse_Titel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">21pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">22pt</xsl:when>
		<xsl:otherwise>22pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Titel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Regular</xsl:when>
		<xsl:otherwise>Source Sans Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Titel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">26pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">27pt</xsl:when>
		<xsl:otherwise>27pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Titel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">7mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">7mm</xsl:when>
		<xsl:otherwise>7mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Titel_Titel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">4mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">4mm</xsl:when>
		<xsl:otherwise>4mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für Untertitel im Titel -->
<xsl:variable name="Schriftgroesse_Titel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">14pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">15pt</xsl:when>
		<xsl:otherwise>15pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Titel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Sans Pro Light</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Sans Pro Light</xsl:when>
		<xsl:otherwise>Source Sans Pro Light</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Titel_Untertitel">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">20pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">21pt</xsl:when>
		<xsl:otherwise>21pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für das Impressum
********************************************************* -->

<xsl:variable name="Skalierung_CC-Hinweis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">53%</xsl:when>
		<xsl:when test="$Druckformat='F2'">53%</xsl:when>
		<xsl:otherwise>53%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Spaltenbreite_CC-Hinweis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">25mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">25mm</xsl:when>
		<xsl:otherwise>25mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Skalierung_QR-Code">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">13%</xsl:when>
		<xsl:when test="$Druckformat='F2'">13%</xsl:when>
		<xsl:otherwise>13%</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Spaltenbreite_QR-Code">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">13mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">13mm</xsl:when>
		<xsl:otherwise>13mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Regular</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Regular</xsl:when>
		<xsl:otherwise>Source Serif Pro Regular</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">7.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">7.5pt</xsl:when>
		<xsl:otherwise>7.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">10pt</xsl:when>
		<xsl:otherwise>10pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_Ueberschrift_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Semibold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Semibold</xsl:when>
		<xsl:otherwise>Source Serif Pro Semibold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_Ueberschrift_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">10pt</xsl:when>
		<xsl:otherwise>10pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_untererBlock_Impressum">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">73.5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">95.5mm</xsl:when>
		<xsl:otherwise>174.5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für das Inhaltsverzeichnis
********************************************************* -->

<xsl:variable name="Breite_Pagina_TOC">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">0.7cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">0.7cm</xsl:when>
		<xsl:otherwise>0.7cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Breite_Text_TOC">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10.7cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">11.7cm</xsl:when>
		<xsl:otherwise>11.7cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_IHV">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.8pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8.8pt</xsl:when>
		<xsl:otherwise>8.8pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_Label_Title">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2mm</xsl:when>
		<xsl:otherwise>2mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Muster_Linie_IHV">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">dots</xsl:when>
		<xsl:when test="$Druckformat='F2'">dots</xsl:when>
		<xsl:otherwise>dots</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für das Abbildungs- und Tabellenverzeichnis
********************************************************* -->

<xsl:variable name="Breite_label_Tab.Abb.Verzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">1.58cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">1.58cm</xsl:when>
		<xsl:otherwise>1.58cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Breite_caption_Tab.Abb.Verzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">9.15cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">10.13cm</xsl:when>
		<xsl:otherwise>10.13cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftart_label_Tab.Abb.Verzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Bold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Bold</xsl:when>
		<xsl:otherwise>Source Serif Pro Bold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Abkürzungsverzeichnis
********************************************************* -->

<xsl:variable name="Breite_kuerzel_Abkürzungsverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2.6cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2.6cm</xsl:when>
		<xsl:otherwise>2.6cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Breite_name_Abkürzungsverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8.8cm</xsl:when>
		<xsl:when test="$Druckformat='F2'">9.8cm</xsl:when>
		<xsl:otherwise>9.8cm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für das Literaturverzeichnis
********************************************************* -->

<xsl:variable name="Schriftgroesse_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">8pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">8pt</xsl:when>
		<xsl:otherwise>8pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">10pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">10pt</xsl:when>
		<xsl:otherwise>10pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2mm</xsl:when>
		<xsl:otherwise>2mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Einzug_start_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Einzug_text_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">-6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">-6mm</xsl:when>
		<xsl:otherwise>-6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- Variablen für die Zwischenüberschrift im Literaturverzeichnis -->
<xsl:variable name="Schriftart_h1_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">Source Serif Pro Semibold</xsl:when>
		<xsl:when test="$Druckformat='F2'">Source Serif Pro Semibold</xsl:when>
		<xsl:otherwise>Source Serif Pro Semibold</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Schriftgroesse_h1_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">9.5pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">9.5pt</xsl:when>
		<xsl:otherwise>9.5pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Zeilenabstand_h1_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">12.3pt</xsl:when>
		<xsl:when test="$Druckformat='F2'">12.3pt</xsl:when>
		<xsl:otherwise>12.3pt</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_danach_h1_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">2mm</xsl:when>
		<xsl:otherwise>2mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Abstand_davor_h1_Literaturverzeichnis">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">5mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">5mm</xsl:when>
		<xsl:otherwise>5mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

<!-- *****************************************************
  Variablen für den Index
********************************************************* -->

<xsl:variable name="Index_Spaltenanzahl">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">2</xsl:when>
		<xsl:when test="$Druckformat='F2'">2</xsl:when>
		<xsl:otherwise>2</xsl:otherwise>
	</xsl:choose>
</xsl:variable>
<xsl:variable name="Index_Spaltenabstand">
	<xsl:choose>
		<xsl:when test="$Druckformat='F1'">6mm</xsl:when>
		<xsl:when test="$Druckformat='F2'">6mm</xsl:when>
		<xsl:otherwise>6mm</xsl:otherwise>
	</xsl:choose>
</xsl:variable>

</xsl:stylesheet>