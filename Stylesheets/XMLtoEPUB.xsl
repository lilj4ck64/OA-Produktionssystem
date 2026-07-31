<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Transformationsstylesheet für EPUB-Erstellung
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0" 	
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xlink="http://www.w3.org/1999/xlink">
								
<xsl:output method="xhtml"
			encoding="utf-8"/>
<xsl:param name="Projekt"/>
<xsl:param name="OutputRoot"/>

<xsl:include href="config.xsl"/>
<xsl:include href="XMLtoEPUB_Content.xsl"/>
<xsl:include href="XMLtoEPUB_META-INF.xsl"/>
<xsl:include href="XMLtoEPUB_mimetype.xsl"/>
<xsl:include href="XMLtoEPUB_OEBPS.xsl"/>
<xsl:include href="XMLtoEPUB_nav.xsl"/>

<xsl:template match="book">
	<!-- mimetype -->
	<xsl:call-template name="mimetype"/>
	
	<!-- container.xml-->
	<xsl:call-template name="container"/>
	
	<!-- Contentpfad anlegen  -->
	<xsl:call-template name="oebps"/>
	
	<!-- HTML-Files schreiben  -->
	<xsl:call-template name="content"/>
	
	<!-- nav-Datei schreiben  -->
	<xsl:call-template name="navhtml"/>
</xsl:template>

<!-- Default-Template -->
<xsl:template match="*">
	<p style="color:red">
		[<xsl:value-of select="name()"/>]
	</p>
</xsl:template>
	
</xsl:stylesheet>
