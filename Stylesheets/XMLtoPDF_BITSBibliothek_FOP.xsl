<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Element-Bibliothek für Erstellung der PDF-Formate
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="1.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns:fo="http://www.w3.org/1999/XSL/Format"
				xmlns:mml="http://www.w3.org/1998/Math/MathML">

<!-- Übernahme des aktuellen Projektnamens -->
<xsl:param name="Projektname"/>


<!-- Einbinden der Konfigurationsdatei -->
<xsl:include href="config.xsl"/>
	
<!-- *****************************************************
  Templates für den Knoten collection-meta
********************************************************* -->

<!-- Template für den Knoten collection-meta -->
<xsl:template match="collection-meta">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/collection-id">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/title-group">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/title-group/title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/volume-in-collection">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/volume-in-collection/volume-number">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/volume-in-collection/volume-title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="collection-meta/issn">
	<xsl:apply-templates/>
</xsl:template>

<!-- *****************************************************
  Templates für den Knoten book-meta
********************************************************* -->
	
<!-- Template für den Knoten book-meta -->
<xsl:template match="book-meta">
	<xsl:apply-templates/>
</xsl:template>

<!-- Templates für den Knoten book-title-group -->
<xsl:template match="book-meta/book-title-group">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="book-meta/book-title-group/book-title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="book-meta/book-title-group/subtitle">
	<xsl:apply-templates/>
</xsl:template>

<!-- Templates für den Knoten trans-title-group -->
<xsl:template match="book-meta/book-title-group/trans-title-group">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="book-meta/book-title-group/trans-title-group/trans-title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="book-meta/book-title-group/trans-title-group/trans-subtitle">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten contrib-group -->
<xsl:template match="contrib-group">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten contrib -->
<xsl:template match="contrib">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten contrib-id -->
<xsl:template match="contrib-id">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten degrees -->
<xsl:template match="degrees">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten surname -->
<xsl:template match="surname">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten given-names -->
<xsl:template match="given-names">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten name -->
<xsl:template match="name">
	<fo:block>
		<xsl:if test="prefix">
			<xsl:value-of select="prefix"/>
			<xsl:text/>
		</xsl:if>
		<xsl:for-each select="given-names">
			<xsl:apply-templates/>
			<xsl:text/>
		</xsl:for-each>
		<xsl:value-of select="surname"/>
		<xsl:if test="suffix">
			<xsl:value-of select="suffix"/>
		</xsl:if>
	</fo:block>
</xsl:template>

<!-- Template für den Knoten bio -->
<xsl:template match="bio">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten email -->
<xsl:template match="email">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten pub-date -->
<xsl:template match="pub-date">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten ISBN -->
<xsl:template match="isbn">
	<xsl:apply-templates/>
</xsl:template>

<!-- Templates für den Knoten publisher -->
<xsl:template match="publisher">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="publisher/publisher-name">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="publisher/publisher-loc">
	<xsl:apply-templates/>
</xsl:template>

<!-- Templates für den Knoten permissions -->
<xsl:template match="permissions">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="permissions/copyright-statement">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="permissions/license">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten kwd-group -->
<xsl:template match="kwd-group">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="kwd-group/title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="kwd-group/kwd">
	<xsl:apply-templates/>
</xsl:template>

<!-- *****************************************************
  Templates für den Knoten front-matter
********************************************************* -->

<!-- Template für den Knoten front-matter -->
<xsl:template match="front-matter">
	<xsl:apply-templates/>
</xsl:template>

<!-- Templates für den Knoten dedication -->
<xsl:template match="dedication">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="named-book-part-body">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten ack -->
<xsl:template match="ack">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="ack/title">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="ack/disp-quote">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten abstract -->
<xsl:template match="abstract">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="trans-abstract">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten glossary -->
<xsl:template match="glossary">
	<fo:block page-break-after="right">
		<xsl:apply-templates/>
	</fo:block>
</xsl:template>

<xsl:template match="def-list">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="def-item">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="def">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="term">
	<xsl:apply-templates/>
</xsl:template>

<!-- *****************************************************
  Templates für den Knoten book-body
********************************************************* -->

<!-- Template für den knoten book-body -->
<xsl:template match="book-body">
	<fo:block>
		<xsl:apply-templates/>
	</fo:block>
</xsl:template>

<!-- Template für den Knoten book-part -->
<xsl:template match="book-body/book-part">
	<fo:block break-before="page">
		<xsl:apply-templates/>
	</fo:block>
</xsl:template>

<!-- Template für den Knoten book-part-meta -->
<xsl:template match="book-body/book-part/book-part-meta">
	<xsl:apply-templates/>
</xsl:template>

<!-- Zwischentitel im Inhalt setzen -->
<xsl:template match="//book-part[@book-part-type = 'part']/book-part-meta/title-group">
	<!-- Marker für Kolumnentitel -->
	<fo:block id="{generate-id(.)}">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:value-of select="title"/>
		</fo:marker>
	</fo:block>
	<!-- Liste Zwischentitel -->
	<fo:block-container space-before="{$Abstand_davor_Zwischentitel}"
						font-family="{$Schriftart_Zwischentitel}"
						font-size="{$Schriftgroesse_Zwischentitel}"
						line-height="{$Zeilenabstand_Zwischentitel}"
						text-align="{$linksbündig}"
						hyphenate="{$Silbentrennung_nein}">
		<fo:block>
			<xsl:value-of select="label"/>
		</fo:block>
		<fo:block>
			<xsl:value-of select="title"/>
		</fo:block>
	</fo:block-container>
	<!-- Linie unterhalb der Überschrift 1.Grades -->
	<fo:block break-after="page">
		<fo:leader leader-pattern="{$Muster_Fussnotenlinie}"
				  leader-length="{$Linienlaenge_h1}"
				   rule-style="{$Style_Fussnotenlinie}"
				   rule-thickness="{$Liniendicke_h1}"/>
	</fo:block>
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten body -->
<xsl:template match="body">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten book-part -->
<xsl:template match="body/book-part">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten book-part-meta -->
<xsl:template match="body/book-part/book-part-meta">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für die Überschrift 1.Grades -->
<xsl:template match="//book-part[@book-part-type = 'chapter']/book-part-meta/title-group">
	<!-- Marker für Kolumnentitel -->
	<fo:block id="{generate-id(.)}">
		<fo:marker 	marker-class-name="Kapitelueberschrift_1.Grades"
					space-start="{$Abstand_Label_Kolumnentitel}">
			<fo:inline space-end="{$Abstand_Label_Kolumnentitel}">
				<xsl:value-of select="label"/>
			</fo:inline>
			<xsl:value-of select="title"/>
		</fo:marker>
	</fo:block>
	<!-- Marker für DOI -->
	<fo:block>
		<fo:marker marker-class-name="DOI">
			<xsl:value-of select="../book-part-id"/>
		</fo:marker>
	</fo:block>
	<!-- Ausgabe Überschrift 1.Grades und Abstandeinstellung für aufeinanderfolgende Überschriften -->
	<xsl:choose>
		<xsl:when test="preceding-sibling::*[1][self::title]">
			<fo:list-block 	font-family="{$Schriftart_h1}"
							font-size="{$Schriftgroesse_h1}"
							line-height="{$Zeilenabstand_h1}"
							text-align="{$linksbündig}"
							keep-with-next.within-page="always"
							hyphenate="{$Silbentrennung_nein}"
							provisional-label-separation="{$Label_Separation_h1}"
							provisional-distance-between-starts="{$Label_Start_h1}">
				<fo:list-item>
					<fo:list-item-label end-indent="label-end()">
						<fo:block>
							<xsl:value-of select="label"/>
						</fo:block>
					</fo:list-item-label>
					<fo:list-item-body start-indent="body-start()">
						<fo:block>
							<xsl:value-of select="title"/>
						</fo:block>
					</fo:list-item-body>
				</fo:list-item>
			</fo:list-block>
			<!-- Linie unterhalb der Überschrift 1.Grades -->
			<fo:block>
				<fo:leader 	leader-pattern="{$Muster_Fussnotenlinie}"
							leader-length="{$Linienlaenge_h1}"
							rule-style="{$Style_Fussnotenlinie}"
							rule-thickness="{$Liniendicke_h1}"/>
			</fo:block>
		</xsl:when>
		<xsl:otherwise>
			<fo:list-block 	font-family="{$Schriftart_h1}"
							font-size="{$Schriftgroesse_h1}"
							line-height="{$Zeilenabstand_h1}"
							text-align="{$linksbündig}"
							keep-with-next.within-page="always"
							hyphenate="{$Silbentrennung_nein}"
							provisional-label-separation="3mm"
							provisional-distance-between-starts="9mm">
				<fo:list-item>
					<fo:list-item-label end-indent="label-end()">
						<fo:block>
							<xsl:value-of select="label"/>
						</fo:block>
					</fo:list-item-label>
					<fo:list-item-body start-indent="body-start()">
						<fo:block>
							<xsl:value-of select="title"/>
						</fo:block>
					</fo:list-item-body>
				</fo:list-item>
			</fo:list-block>
			<!-- Linie unterhalb der Überschrift 1.Grades -->
			<fo:block space-after="{$Abstand_danach_h1}">
				<fo:leader 	leader-pattern="{$Muster_Fussnotenlinie}"
						    leader-length="{$Linienlaenge_h1}"
							rule-style="{$Style_Fussnotenlinie}"
							rule-thickness="{$Liniendicke_h1}"/>
			</fo:block>
		</xsl:otherwise>
	</xsl:choose>
	<xsl:apply-templates/>
</xsl:template>

	<!-- Template für die Überschrift 2.Grades -->
	<xsl:template match="sec" priority="1">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift_2.Grades">
				<fo:inline space-end="{$Abstand_Label_Kolumnentitel}">
					<xsl:value-of select="label"/>
				</fo:inline>
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Ausgabe Überschrift 2.Grades und Abstandeinstellung für aufeinanderfolgende Überschriften -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::title]">
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h2}">				
					<fo:list-block font-family="{$Schriftart_h2}"
								   font-size="{$Schriftgroesse_h2}"
								   line-height="{$Zeilenabstand_h2}"
								   text-align="{$linksbündig}"
								   space-after="{$Grundschrift_Zeilenabstand}"
								   
								   hyphenate="{$Silbentrennung_nein}"
								   provisional-label-separation="{$Label_Separation_h2}"
								   provisional-distance-between-starts="{$Label_Start_h2}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h2}"
									space-before="{$Abstand_davor_h2}">				
					<fo:list-block font-family="{$Schriftart_h2}"
								   font-size="{$Schriftgroesse_h2}"
								   line-height="{$Zeilenabstand_h2}"
								   space-before="{$Grundschrift_Zeilenabstand}"
								   text-align="{$linksbündig}"
								   space-after="{$Grundschrift_Zeilenabstand}"
								   
								   hyphenate="{$Silbentrennung_nein}"
								   provisional-label-separation="{$Label_Separation_h2}"
								   provisional-distance-between-starts="{$Label_Start_h2}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:otherwise>
		</xsl:choose>
	<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für die Überschrift 3.Grades -->
	<xsl:template match="sec/sec" priority="2">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Ausgabe Überschrift 3.Grades und Abstandeinstellung für aufeinanderfolgende Überschriften -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::title]">
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h3}"
									space-before="{$Abstand_davor_h3_nach_h}">	
					<fo:list-block font-family="{$Schriftart_h3}"
								   font-size="{$Schriftgroesse_h3}"
							       line-height="{$Zeilenabstand_h3}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h3}"
								   provisional-distance-between-starts="{$Label_Start_h3}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
									<xsl:apply-templates select="label/inline-graphic"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h3}"
									space-before="{$Abstand_davor_h3}">	
					<fo:list-block font-family="{$Schriftart_h3}"
								   font-size="{$Schriftgroesse_h3}"
								   line-height="{$Zeilenabstand_h3}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h3}"
								   provisional-distance-between-starts="{$Label_Start_h3}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
									<xsl:apply-templates select="label/inline-graphic"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:otherwise>
		</xsl:choose>
	<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für die Überschrift 4.Grades -->
	<xsl:template match="sec/sec/sec" priority="3">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Ausgabe Überschrift 4.Grades und Abstandeinstellung für aufeinanderfolgende Überschriften -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::title]">
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h4}"
									space-before="{$Abstand_davor_h4_nach_h}">
					<fo:list-block font-family="{$Schriftart_h4}"
								   font-size="{$Schriftgroesse_h4}"
								   line-height="{$Zeilenabstand_h4}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h4}"
								   provisional-distance-between-starts="{$Label_Start_h4}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block-container keep-with-next.within-page="always"
								    space-after="{$Abstand_danach_h4}"
									space-before="{$Abstand_davor_h4}">
					<fo:list-block font-family="{$Schriftart_h4}"
								   font-size="{$Schriftgroesse_h4}"
								   line-height="{$Zeilenabstand_h4}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h4}"
								   provisional-distance-between-starts="{$Label_Start_h4}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:otherwise>
		</xsl:choose>
	<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für die Überschrift 5.Grades -->
	<xsl:template match="sec/sec/sec/sec" priority="4">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Ausgabe Überschrift 5.Grades und Abstandeinstellung für aufeinanderfolgende Überschriften -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::title]">
				<fo:block-container keep-with-next.within-page="always"
									space-after="{$Abstand_danach_h5}">		
					<fo:list-block font-family="{$Schriftart_h5}"
								   font-size="{$Schriftgroesse_h5}"
								   line-height="{$Zeilenabstand_h5}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h5}"
								   provisional-distance-between-starts="{$Label_Start_h5}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block-container keep-with-next.within-page="always"
								    space-after="{$Abstand_danach_h5}"
									space-before="{$Abstand_davor_h5}">
					<fo:list-block font-family="{$Schriftart_h5}"
								   font-size="{$Schriftgroesse_h5}"
								   line-height="{$Zeilenabstand_h5}"
								   text-align="{$linksbündig}"
								   hyphenate="{$Silbentrennung_nein}"
							       provisional-label-separation="{$Label_Separation_h5}"
								   provisional-distance-between-starts="{$Label_Start_h5}">
						<fo:list-item>
							<fo:list-item-label end-indent="label-end()">
								<fo:block>
									<xsl:value-of select="label"/>
								</fo:block>
							</fo:list-item-label>
							<fo:list-item-body start-indent="body-start()">
								<fo:block>
									<xsl:value-of select="title"/>
								</fo:block>
							</fo:list-item-body>
						</fo:list-item>
					</fo:list-block>
				</fo:block-container>
			</xsl:otherwise>
		</xsl:choose>
	<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für Absätze (mit Einzug erste Zeile) -->
	<xsl:template match="p">
		<xsl:choose>
			<xsl:when test="self::p[preceding-sibling::*[1][self::p/def-list]]">
				<fo:block text-indent="0mm"><xsl:apply-templates/></fo:block>
			</xsl:when>
			<xsl:when test="self::p[preceding-sibling::*[1][self::p]]">
				<fo:block text-indent="{$Einzug}"><xsl:apply-templates/></fo:block>
			</xsl:when>
			<xsl:when test="self::p[parent::fn]">
				<fo:block space-after="0mm"><xsl:apply-templates/></fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block text-indent="0mm"><xsl:apply-templates/></fo:block>
			</xsl:otherwise>
		</xsl:choose>
		
		<xsl:if test="parent::def-list">
		<fo:block text-align="right">
			<xsl:apply-templates/>
		</fo:block>
		</xsl:if>
		
	</xsl:template>

	<!-- Template für hochgestellte Ziffern -->
	<xsl:template match="sup">
	<xsl:choose>
		<xsl:when test="preceding-sibling::sub">
			<fo:inline baseline-shift="{$hochgestellt_baseline-shift}"
					   padding-left="{$hoch-tiefgestellt_Einzug_Ziffer}"
					   font-size="{$hoch-tiefgestellt_Schriftgroesse}">
				<xsl:apply-templates/>
			</fo:inline>
		</xsl:when>
		<xsl:otherwise>
		<fo:inline baseline-shift="{$hochgestellt_baseline-shift}"
				   font-size="{$hoch-tiefgestellt_Schriftgroesse}">
			<xsl:apply-templates/>
		</fo:inline>
		</xsl:otherwise>
	</xsl:choose>
	</xsl:template>

	<!-- Template für tiefgestellte Ziffern -->
	<xsl:template match="sub">
		<xsl:choose>
		<xsl:when test="preceding-sibling::sup">
			<fo:inline baseline-shift="{$tiefgestellt_baseline-shift}"
					   padding-left="{$hoch-tiefgestellt_Einzug_Ziffer}"
					   font-size="{$hoch-tiefgestellt_Schriftgroesse}">
				<xsl:apply-templates/>
			</fo:inline>
		</xsl:when>
		<xsl:otherwise>
			<fo:inline baseline-shift="{$hoch-tiefgestellt_Einzug_Ziffer}"
					   font-size="{$hoch-tiefgestellt_Schriftgroesse}">
				<xsl:apply-templates/>
			</fo:inline>
		</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- Templates für Auszeichnungen -->
	<xsl:template match="sc">
		<fo:inline font-variant="small-caps">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	
	<xsl:template match="bold">
		<xsl:choose>
			<xsl:when test="ancestor::td">
				<fo:inline font-family="{$Tabellen_Bold}">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline font-family="{$Fließtext_Bold}">
					<xsl:apply-templates/>
				</fo:inline>	
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	
	<xsl:template match="semibold">
		<xsl:choose>
			<xsl:when test="ancestor::td">
				<fo:inline font-family="{$Tabellen_Semibold}">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline font-family="{$Fließtext_Semibold}">
					<xsl:apply-templates/>
				</fo:inline>	
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>
	
	<xsl:template match="italic">
		<xsl:choose>
			<xsl:when test="ancestor::td">
				<fo:inline font-family="{$Tabellen_Italic}">
					<xsl:apply-templates/>
				</fo:inline>
			</xsl:when>
			<xsl:otherwise>
				<fo:inline font-family="{$Fließtext_Italic}">
					<xsl:apply-templates/>
				</fo:inline>	
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template match="monospace">
		<fo:inline font-family="{$Fließtext_Monospace}" font-size="{$SG_Monospace}">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<!-- Template für Fußnoten -->
	<xsl:template match="fn">
		<fo:footnote>
			<fo:inline baseline-shift="{$Baseline_shift_Fussnote}"
					   font-size="{$Schriftgroesse_Fussnote_imText}">
				<xsl:value-of select="@symbol"/>
			</fo:inline>
			
			<fo:footnote-body  text-indent="{$kein_Einzug}" 
							   space-before="0mm"
							   padding-top="0mm"
							   padding-bottom="0mm"
							   line-height="{$Zeilenabstand_Fussnote}"
							   
							   text-align="{$linksbündig}">
				<fo:list-block provisional-distance-between-starts="{$Abstand_Fußnote_Text}"
							   start-indent="0mm">
					<fo:list-item>
						<fo:list-item-label end-indent="label-end()">
							<fo:block font-size="{$Schriftgroesse_Fussnote_unten}"
									  font-family="{$Grundschriftart}">
								<xsl:value-of select="@symbol"/>
							</fo:block>
						</fo:list-item-label>
						<fo:list-item-body start-indent="body-start()">
							<fo:block font-family="{$Grundschriftart}"
									  font-size="{$Schriftgroesse_Fussnote}">
								<xsl:apply-templates select="p"/>
							</fo:block>
						</fo:list-item-body>
					</fo:list-item>
				</fo:list-block>
			</fo:footnote-body>
		</fo:footnote>
	</xsl:template>

	<!-- Template für Zitate -->
	<xsl:template match="disp-quote">
		<fo:block space-before="{$Grundschrift_Zeilenabstand}"
				  space-after="{$Grundschrift_Zeilenabstand}"
				  font-family="{$Fließtext_Italic}">
			<xsl:apply-templates select="p"/>
		</fo:block>
	</xsl:template>

	<!-- Template für Tabellen -->
	<xsl:template match="table-wrap">
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>	
				<xsl:choose>
					<xsl:when test="label">
						<fo:block-container
							
							space-before="{$Grundschrift_Zeilenabstand}"
							space-after="{$Tabelle_Abstand_danach}">
							
							<fo:list-block
								space-after="{$Tabellenueberschrift_Abstand_danach}"
								provisional-label-separation="{$Label_Separation_Tabellenueberschrift}"
								provisional-distance-between-starts="{$Label_Start_Tabellenueberschrift}">
								<fo:list-item>
									<fo:list-item-label end-indent="label-end()">
										<fo:block font-size="{$Schriftgroesse_Tabellenueberschrift}"
											font-family="{$Schriftart_Tabellenlabel}">
											<xsl:value-of select="label"/>
										</fo:block>
									</fo:list-item-label>
									<fo:list-item-body start-indent="body-start()">
										<fo:block font-size="{$Schriftgroesse_Tabellenueberschrift}"
											text-align="{$linksbündig}">
											<xsl:for-each select="caption/title">
												<xsl:apply-templates/>
											</xsl:for-each>
											<xsl:text> </xsl:text>
											<xsl:value-of select="caption/p"/>
											<xsl:if test="label">
												<xsl:if test="object-id">
													<fo:inline>
														<!-- Einfügen der DOI für die Tabelle -->
														<xsl:text> </xsl:text>
														<xsl:text>(http://doi.org/</xsl:text>
														<xsl:value-of select="object-id"/>
														<xsl:text>)</xsl:text>
													</fo:inline>
												</xsl:if>
											</xsl:if>
										</fo:block>
									</fo:list-item-body>
								</fo:list-item>
							</fo:list-block>
							<xsl:apply-templates select="table"/>
						</fo:block-container>
					</xsl:when>
					<xsl:otherwise>
						<fo:block-container space-before="{$Grundschrift_Zeilenabstand}"
											space-after="{$Grundschrift_Zeilenabstand}">
							<xsl:apply-templates/>
						</fo:block-container>
					</xsl:otherwise>
				</xsl:choose>
	</xsl:template>

	<xsl:template match="table">
	<fo:block-container>
		<!-- Option mit dem Attribut content-type="Tabelle_zusammenhalten", um die Tabelle nicht zu trennen -->
		<xsl:choose>
			<xsl:when test="@content-type">
				<fo:table 
						  table-layout="auto"
						  width="{$Satzspiegelbreite}"
						  >
						  <xsl:apply-templates/>
				</fo:table>
			</xsl:when>
			<xsl:otherwise>
				<fo:table table-layout="auto"
						  width="{$Satzspiegelbreite}"
						  >
						  <xsl:apply-templates/>
				</fo:table>
			</xsl:otherwise>
		</xsl:choose>
	</fo:block-container>
	</xsl:template>

	<xsl:template match="thead">
		<fo:table-header>
			<xsl:apply-templates/>
		</fo:table-header>
	</xsl:template>

	<xsl:template match="tbody">
		<fo:table-body>
			<xsl:apply-templates/>
		</fo:table-body>
	</xsl:template>
	
	<xsl:template match="td/bold">
		<fo:block font-family="{$Schriftart_Kopfzelle}">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="tr">
		<fo:table-row border-after-style="solid"
					  border-width="{$Tabellenkoerper_Linie}">
			<xsl:apply-templates/>		
		</fo:table-row>
	</xsl:template>

	<xsl:template match="td">
		<fo:table-cell padding-end="{$Tabellenkoerper_Innenabstand_danach}"
					   number-columns-spanned="{@colspan}"
					   number-rows-spanned="{@rowspan}">
			<fo:block font-family="{$Schriftart_Koerperzelle}"
					  font-size="{$Schriftgroesse_Tabelle}"
					  hyphenate="{$Silbentrennung_nein}"
					  padding-top="{$Tabellenkoerper_Innenabstand_oben}"
					  padding-bottom="{$Tabellenkoerper_Innenabstand_unten}"
					  line-height="{$Zeilenabstand_Tabelle}"
					  text-align="{$linksbündig}">
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
		
	</xsl:template>

	<xsl:template match="thead/tr/th">
		<fo:table-cell number-columns-spanned="{@colspan}"
					   number-rows-spanned="{@rowspan}">
			<fo:block font-family="{$Schriftart_Kopfzelle}"
					  font-size="{$Schriftgroesse_Tabelle}"
					  hyphenate="{$Silbentrennung_ja}"
					  padding-top="{$Tabellenkoerper_Innenabstand_oben}"
					  padding-bottom="{$Tabellenkoerper_Innenabstand_unten}"
					  line-height="{$Zeilenabstand_Tabelle}"
					  text-align="{$linksbündig}">
				<xsl:apply-templates/>
			</fo:block>
		</fo:table-cell>
	</xsl:template>
	
	<xsl:template match="break">
		<fo:block break-after="column">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>
	
	<xsl:template match="object-id">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- Template für Bilder -->
	<xsl:template match="graphic">
		<fo:block>
			<fo:external-graphic scaling="uniform"
								 src="{$Projektname}/Media/Images/{@xlink:href}"
								 content-width="scale-to-fit"
								 content-height="100%"
								 width="100%"/>
		</fo:block>
	</xsl:template>
	
	<!-- Template für MathML-Formeln -->
	<xsl:template match="mml:math">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mml:mrow">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mml:mo">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mml:msub">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mml:mi">
		<xsl:apply-templates/>
	</xsl:template>
	<xsl:template match="mml:mfrac">
		<xsl:apply-templates/>
	</xsl:template>

	<xsl:template match="inline-graphic">
		<fo:inline>
			<fo:external-graphic scaling="uniform"
								 src="{$Projektname}/Media/Images/{@xlink:href}"
								 content-width="auto"
								 max-width="{$Satzspiegelbreite}"/>
		</fo:inline>
	</xsl:template>

	<!-- Template für Formeln als Grafik -->
	<xsl:template match="disp-formula/graphic">
		<fo:block space-before="{$Grundschrift_Zeilenabstand}"
				  space-after="{$Formelgrafik_Abstand_danach}">
			<fo:table>
				<fo:table-column column-number="1" column-width="{$Satzspiegelbreite}"/>
				<fo:table-column column-number="2"/>
				<fo:table-body>
					<fo:table-row>
						<!-- Spalte für die Formel-Grafik -->
						<fo:table-cell column-number="1" display-align="center">
							<fo:block>
								<fo:external-graphic scaling="uniform"
												     src="{$Projektname}/Media/Images/{@xlink:href}"
													 content-width="{$Formelgrafik_Skalierung}"
													 content-height="auto"/>
							</fo:block>
						</fo:table-cell>
						<!-- Spalte für das Label der Grafik -->
						<fo:table-cell column-number="2"
									   display-align="{$zentriert}"
									   start-indent="{$Formellabel_Einzug}">
							<fo:block text-align="{$rechtsbündig}"
									  hyphenate="{$Silbentrennung_nein}">
								<xsl:value-of select="../label"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
		</fo:block>
	</xsl:template>
	
	<xsl:template match="inline-formula">
		<fo:inline>
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>

	<!-- Template für Formelzeichen-Aufzählungen im Inhalt -->
	<xsl:template match="p/def-list">
		<fo:block space-after="{$Grundschrift_Zeilenabstand}">
			<xsl:if test="title">
				<fo:block>
					<xsl:value-of select="title"/>
				</fo:block>
			</xsl:if>
			<fo:table start-indent="{$Abstand_Fußnote_Text}" table-layout="auto">
				<fo:table-column column-number="1"/>
				<fo:table-column column-number="2"/>
				<fo:table-body>
				<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
				<xsl:for-each select="def-item">
						<fo:table-row min-height="{$Grundschrift_Zeilenabstand}">
							<!-- Spalte für das Formelzeichen -->
							<fo:table-cell column-number="1">
								<fo:block>
									<xsl:apply-templates select="term"/>
									<xsl:apply-templates select="sup"/>
									<xsl:apply-templates select="sub"/>
								</fo:block>
							</fo:table-cell>
							<!-- Spalte für die Beschreibung des Formelzeichens -->
							<fo:table-cell column-number="2">
								<fo:block text-align="{$linksbündig}"
										  hyphenate="{$Silbentrennung_nein}"
										  line-height="{$Grundschrift_Zeilenabstand}">
									<xsl:apply-templates select="def/p"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
				</xsl:for-each>
				</fo:table-body>
			</fo:table>
		</fo:block>
	</xsl:template>
	
	<xsl:template match="def-list/title">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für Grafiken -->
	<xsl:template match="fig">
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<fo:block-container 
							space-before="{$Abbildung_Abstand_davor}"
							space-after="{$Abbildung_Abstand_danach}">
			<xsl:apply-templates select="graphic"/>
			<!-- Abbildungsunterschrift -->
			<fo:list-block space-after="{$Abbildungsunterschrift_Abstand_danach}"
						   space-before="{$Abbildungsunterschrift_Abstand_davor}"
						   
						   provisional-label-separation="{$Label_Separation_Abbildungsunterschrift}"
						   provisional-distance-between-starts="{$Label_Start_Abbildungsunterschrift}">
				<fo:list-item>
					<fo:list-item-label end-indent="label-end()">
						<fo:block font-size="{$Schriftgroesse_Tabellenueberschrift}"
								  font-family="{$Schriftart_Tabellenlabel}">
							<xsl:value-of select="label"/>
						</fo:block>
					</fo:list-item-label>
					<fo:list-item-body start-indent="body-start()">
						<fo:block font-size="{$Schriftgroesse_Tabellenueberschrift}"
								  line-height="{$Zeilenabstand_Abbildungsunterschrift}"
								  text-align="{$linksbündig}">
							<xsl:value-of select="caption/title"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="caption/p"/>
							<xsl:if test="object-id">
							<fo:inline >
								<!-- Einfügen der DOI für die Abbildung -->
								<xsl:text> </xsl:text>
								<xsl:text>(http://doi.org/</xsl:text>
								<xsl:value-of select="object-id"/>
								<xsl:text>)</xsl:text>
							</fo:inline>
							</xsl:if>
						</fo:block>
					</fo:list-item-body>
				</fo:list-item>
			</fo:list-block>
		</fo:block-container>
	</xsl:template>
	
	<!-- Template für Überschriften von Abbildungen -->
	<xsl:template match="abstract">
		<fo:block>
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- Template für Aufzählungen und Listen -->
	<xsl:template match="list">
		<xsl:choose>
			<xsl:when test="parent::td">
				<fo:block orphans="{$Schusterjunge_Einstellung}"
						  text-align="{$linksbündig}"
						  widows="{$Hurenkind_Einstellung}">
					<fo:block font-family="{$Schriftart_h_ohneNummerierung}">
						<xsl:value-of select="title"/>
					</fo:block>
					<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block space-before="{$Abstand_davor_Listen}"
						  space-after="{$Abstand_danach_Listen}"
						  orphans="{$Schusterjunge_Einstellung}"
						  text-align="{$linksbündig}"
						  widows="{$Hurenkind_Einstellung}">
					<fo:block font-family="{$Schriftart_h_ohneNummerierung}">
						<xsl:value-of select="title"/>
					</fo:block>
					<xsl:apply-templates/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>	
	</xsl:template>

	<xsl:template match="list/list-item" priority="1">
		<fo:block>
			<fo:list-block provisional-distance-between-starts="{$Abstand_Listenlabel_Listentext}"
						   orphans="{$Schusterjunge_Einstellung}"
						   widows="{$Hurenkind_Einstellung}">
				<fo:list-item>
					<fo:list-item-label end-indent="label-end()">
						<fo:block>
							<xsl:choose>
								<xsl:when test="parent::list[@list-type = 'bullet']">
									<xsl:text>&#8213;</xsl:text>
								</xsl:when>
								<xsl:when test="parent::list[@list-type = 'order']">
									<xsl:number count="list-item" format="1."/>
								</xsl:when>
								<xsl:when test="parent::list[@list-type = 'alpha-lower']">
									<xsl:number count="list-item" format="a)"/>
								</xsl:when>
								<xsl:when test="parent::list[@list-type = 'haken']">
									<xsl:text>&#10003;</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>&#8213;</xsl:text>
								</xsl:otherwise>				
							</xsl:choose>
						</fo:block>
					</fo:list-item-label>
					<fo:list-item-body start-indent="body-start()">
						<fo:block>
							<xsl:apply-templates/>
						</fo:block>
					</fo:list-item-body>
				</fo:list-item>
			</fo:list-block>
		</fo:block>
	</xsl:template>

	<!-- Templates für verschachtelte Listen -->
	<xsl:template match="list/list-item/list" priority="2">
		<fo:block space-after="{$Abstand_danach_Listen}">
			<xsl:apply-templates/>
		</fo:block>
		
	</xsl:template>

	<xsl:template match="list/list-item/list/list-item" priority="3">
		<fo:block>
			<fo:list-block>
				<fo:list-item>
					<fo:list-item-label end-indent="label-end()">
						<fo:block>
							<xsl:choose>
								<xsl:when test="parent::list[@list-type = 'bullet']">
									<xsl:text>&#8213;</xsl:text>
								</xsl:when>
								<xsl:when test="parent::list[@list-type = 'order']">
									<xsl:number count="list-item" format="1."/>
								</xsl:when>
								<xsl:when test="parent::list[@list-type = 'alpha-lower']">
									<xsl:number count="list-item" format="a)"/>
								</xsl:when>
								<xsl:otherwise>
									<xsl:text>&#8213;</xsl:text>
								</xsl:otherwise>
							</xsl:choose>
						</fo:block>
					</fo:list-item-label>
					<fo:list-item-body start-indent="body-start()">
						<fo:block>
							<xsl:value-of select="p"/>
						</fo:block>
					</fo:list-item-body>
				</fo:list-item>
			</fo:list-block>
		</fo:block>
	</xsl:template>

	<!-- Template für die Informationskästen -->
	<xsl:template match="boxed-text">
		<fo:block background-color="{$Hintergrundfarbe_Textboxen}"
				  absolute-position="auto"
				  height="auto" width="{$Satzspiegelbreite}"
				  space-before="{$Abstand_davor_Textboxen}"
				  space-after="{$Abstand_danach_Textboxen}">
			<fo:block padding-top="{$Abstand_davor_Textboxen}"
					  padding-bottom="{$Abstand_danach_Textboxen}"
					  margin-left="{$Abstand_innen_Textboxen}"
					  margin-right="{$Abstand_innen_Textboxen}"
					  font-size="{$Schriftgroesse_Textboxen}"
					  line-height="{$Zeilenabstand_Textboxen}">
				<xsl:apply-templates/>
			</fo:block>
		</fo:block>
	</xsl:template>

	<!-- Template für Quellcode -->
	<xsl:template match="code">
		<fo:block font-family="{$Schriftart_Quellcode}"
				  font-size="{$Schriftgroesse_Quellcode}"
				  line-height="{$Zeilenabstand_Quellcode}"
				  text-align="{$linksbündig}"
				  white-space="pre"
				  space-before="{$Abstand_davor_Textboxen}"
				  space-after="{$Abstand_danach_Textboxen}">
			<xsl:apply-templates/> 
		</fo:block>
	</xsl:template>

	<!-- Template für Index -->
	<xsl:template match="index-term">
		<fo:inline id="{generate-id(.)}">
			<xsl:apply-templates/>
		</fo:inline>
	</xsl:template>
	<xsl:template match="index-term/term">
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- Template für xref -->
	<xsl:template match="xref">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für disp-formula -->
	<xsl:template match="disp-formula">
		<xsl:apply-templates/>
	</xsl:template>
	
	
	<!-- Template für subtitle (kleinere Zwischenüberschriften) -->
	<xsl:template match="subtitle">
		<xsl:choose>
			<xsl:when test="following-sibling::*[1][self::fig]">
				<fo:block font-family="{$Schriftart_h_ohneNummerierung}"
				space-before="{$Grundschrift_Zeilenabstand}">
				<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:when test="self::subtitle[preceding-sibling::*[1][self::subtitle]]">
				<fo:block font-family="{$Schriftart_h_ohneNummerierung}"
				space-before="0mm">
				<xsl:apply-templates/>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block font-family="{$Schriftart_h_ohneNummerierung}"
						  space-before="{$Grundschrift_Zeilenabstand}">
				<xsl:apply-templates/>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>

	<!-- *****************************************************
  Templates für den Knoten book-back
********************************************************* -->

	<!-- Template für den knoten book-back -->
	<xsl:template match="book-back">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für den knoten ref -->
	<xsl:template match="ref">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für den knoten mixed citation -->
	<xsl:template match="mixed-citation">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für den knoten book-app-group -->
	<xsl:template match="book-back/book-app-group">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für den knoten book-app-group -->
	<xsl:template match="book-back/book-app-group/book-part-meta">
		<fo:block break-before="page" break-after="page">
			<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<!-- Template für den Zwischentitel des Anhangs -->
	<xsl:template match="book-app-group/book-part-meta/title-group">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift_1.Grades">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Liste Zwischentitel Anhang -->
		<fo:block-container space-before="{$Abstand_davor_Zwischentitel}"
							font-family="{$Schriftart_Zwischentitel}"
							font-size="{$Schriftgroesse_Zwischentitel}"
							line-height="{$Zeilenabstand_Zwischentitel}"
							text-align="{$linksbündig}"
							hyphenate="{$Silbentrennung_nein}">
			<fo:block>
				<xsl:value-of select="title"/>
			</fo:block>
			<fo:block>
				<xsl:value-of select="subtitle"/>
			</fo:block>
		</fo:block-container>
		<!-- Linie unterhalb der Überschrift 1.Grades -->
		<fo:block break-after="page">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}"
					   leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}"
					   rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>
	</xsl:template>


	<xsl:template match="book-app">
		<fo:block break-after="page">
		<xsl:apply-templates/>
		</fo:block>
	</xsl:template>

	<xsl:template match="book-app/book-part-meta">
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für die Überschrift 1. Grades des Anhangs -->
	<xsl:template match="book-app/book-part-meta/title-group">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift_1.Grades">
				<fo:inline space-end="{$Abstand_Label_Kolumnentitel}">
					<xsl:value-of select="label"/>
				</fo:inline>
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Marker für DOI -->
		<fo:block>
			<fo:marker marker-class-name="DOI">
				<xsl:value-of select="../book-part-id"/>
			</fo:marker>
		</fo:block>
		<!-- Überschrift 1.Grades -->
		<fo:block-container font-family="{$Schriftart_h1}"
						    font-size="{$Schriftgroesse_h1}"
							line-height="{$Zeilenabstand_h1}"
							space-before="{$Abstand_davor_h1}"
							text-align="{$linksbündig}"
							hyphenate="{$Silbentrennung_nein}">
			<fo:block>
				<xsl:value-of select="label"/>
			</fo:block>
			<fo:block>
				<xsl:value-of select="title"/>
			</fo:block>
		</fo:block-container>
		<!-- Linie unterhalb der Überschrift 1.Grades -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}"
					   leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}"
					   rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>
		<xsl:apply-templates/>
	</xsl:template>

	<!-- Template für die Überschrift 2. Grades des Anhangs -->
	<xsl:template match="book-app/body/sec">
		<!-- Marker für Kolumnentitel -->
		<fo:block id="{generate-id(.)}">
			<fo:marker marker-class-name="Kapitelueberschrift_2.Grades">
				<xsl:value-of select="title"/>
			</fo:marker>
		</fo:block>
		<!-- Ausgabe Überschrift 2.Grades des Anhangs und Abstandeinstellung für aufeinanderfolgende Überschriften -->
		<xsl:choose>
			<xsl:when test="preceding-sibling::*[1][self::title]">
				<fo:block-container font-family="{$Schriftart_h2}"
						  font-size="{$Schriftgroesse_h2}"
						  line-height="{$Zeilenabstand_h2}"
						  space-after="{$Abstand_danach_h2}"
						  text-align="{$linksbündig}"
						  hyphenate="{$Silbentrennung_nein}">
						<fo:list-block provisional-label-separation="{$Label_Separation_h_A2}"
									   provisional-distance-between-starts="{$Label_Start_h_A2}">
							<fo:list-item>
								<fo:list-item-label end-indent="label-end()">
									<fo:block>
										<xsl:value-of select="label"/>
									</fo:block>
								</fo:list-item-label>
								<fo:list-item-body start-indent="body-start()">
									<fo:block>
										<xsl:value-of select="title"/>
									</fo:block>
								</fo:list-item-body>
							</fo:list-item>
						</fo:list-block>
				</fo:block-container>
			</xsl:when>
			<xsl:otherwise>
				<fo:block-container font-family="{$Schriftart_h2}"
						  font-size="{$Schriftgroesse_h2}"
						  line-height="{$Zeilenabstand_h2}"
						  space-after="{$Abstand_danach_h2}"
						  space-before="{$Abstand_davor_h2}"
						  text-align="{$linksbündig}"
						  hyphenate="{$Silbentrennung_nein}">
						<fo:list-block provisional-label-separation="{$Label_Separation_h_A2}"
									   provisional-distance-between-starts="{$Label_Start_h_A2}">
							<fo:list-item>
								<fo:list-item-label end-indent="label-end()">
									<fo:block>
										<xsl:value-of select="label"/>
									</fo:block>
								</fo:list-item-label>
								<fo:list-item-body start-indent="body-start()">
									<fo:block>
										<xsl:value-of select="title"/>
									</fo:block>
								</fo:list-item-body>
							</fo:list-item>
						</fo:list-block>
				</fo:block-container>
			</xsl:otherwise>	
		</xsl:choose>
		<xsl:apply-templates/>
	</xsl:template>
	
	<!-- Default-Template -->
	<xsl:template match="*"/>

</xsl:stylesheet>
