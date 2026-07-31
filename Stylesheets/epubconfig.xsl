<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Konfigurationsstylesheet für EPUB-Erstellung
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:oa="urn:oa-satzsystem"
	exclude-result-prefixes="oa">

<!-- *****************************************************
  Variablen für die HTML- und EPUB-Produktion
********************************************************* -->
<!-- Debug-Level
0 -> kein Debugging
1 -> nur Fehler
2 -> Fehler und Warnungen
3 -> Fehler, Warnungen und Testausschriften -->
<xsl:variable name="HTML-Debuglevel">3</xsl:variable>

<!-- Projektnamen der Publikation angeben! -->
<xsl:variable name="Projektname">
	<xsl:value-of select="$Projekt"/>
</xsl:variable>

<xsl:function name="oa:safe-name">
	<xsl:param name="value"/>
	<xsl:variable name="mapped" select="replace(normalize-space(string($value)), '[^A-Za-z0-9._-]', '_')"/>
	<xsl:sequence select="if ($mapped = ('', '.', '..')) then 'unnamed' else $mapped"/>
</xsl:function>
	
<!-- *****************************************************
  Pfade für die HTML- und EPUB-Produktion
********************************************************* -->
	
<xsl:variable name="EPUB_Content_Pfad">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/Content')"/>
</xsl:variable>
<xsl:variable name="EPUB_Fonts_Pfad">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/Fonts')"/>
</xsl:variable>
<xsl:variable name="EPUB_Styles_Pfad">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/Styles')"/>
</xsl:variable>
<xsl:variable name="EPUB_Images_Pfad">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/Images')"/>
</xsl:variable>
<xsl:variable name="EPUB_Container_XML">
	<xsl:value-of select="concat($OutputRoot, '/META-INF/container.xml')"/>
</xsl:variable>
<xsl:variable name="EPUB_mimetype">
	<xsl:value-of select="concat($OutputRoot, '/mimetype')"/>
</xsl:variable>
<xsl:variable name="EPUB_content">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/content.opf')"/>
</xsl:variable>
<xsl:variable name="EPUB_tocncx">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/toc.ncx')"/>
</xsl:variable>
<xsl:variable name="EPUB_navhtml">
	<xsl:value-of select="concat($OutputRoot, '/OEBPS/nav.xhtml')"/>
</xsl:variable>

<!-- *****************************************************
  Standard-Dateien für die HTML- und EPUB-Produktion
********************************************************* -->

<!-- Einzelkapitel = book-parts (Einzelinstanzen in OEBPS/Content)-->
<xsl:variable name="Kapitel">
	<xsl:text>Kapitel</xsl:text>
</xsl:variable>
	
<!-- Literaturverzeichnis -->
<xsl:variable name="Literaturverzeichnis">
	<xsl:text>Literaturverzeichnis</xsl:text>
</xsl:variable>
	
<!-- Anhang -->
<xsl:variable name="Anhang">
	<xsl:text>Anhang</xsl:text>
</xsl:variable>
	
<!-- Angabe des Content-Ausgabeformats -->
<xsl:variable name="Contentausgabeformat">
	<xsl:text>.xhtml</xsl:text>
</xsl:variable>
	
<!-- Name des CSS-Stylesheets; wird vom Go-Buildkern übergeben. -->
<xsl:param name="CSSStylesheet"/>
<xsl:variable name="CSS-Stylesheet" select="$CSSStylesheet"/>

<!-- DOI des Werkes -->
<xsl:variable name="DOI">
	<xsl:value-of select="//book-meta/book-id[@book-id-type='doi']"/>
</xsl:variable>

</xsl:stylesheet>
