<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Transformationsstylesheet für OEBPS-Inhaltsdateien des EPUB-Formats
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns="http://www.idpf.org/2007/opf"
				xmlns:a="http://www.daisy.org/z3986/2005/ncx/"
				xmlns:oa="urn:oa-satzsystem"
				exclude-result-prefixes="oa">

<xsl:output method="xhtml"
			encoding="utf-8"/>
			
<xsl:include href="epubconfig.xsl"/>

<xsl:template name="oebps">		
	<!--  content.opf -->
	<xsl:result-document method="xml" href="{$EPUB_content}">
			<package xmlns="http://www.idpf.org/2007/opf" xmlns:dc="http://purl.org/dc/elements/1.1/"
					     xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:dcterms="http://purl.org/dc/terms/"
    					 version="3.0" xml:lang="de" unique-identifier="doi">
					
		<metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
			<dc:title id="title1">
				<xsl:value-of select="//book/book-meta/book-title-group/book-title"/>
			</dc:title>
			<xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']">
                <dc:creator>
                    <xsl:value-of select="name/given-names"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="name/surname"/> 
				</dc:creator>
            </xsl:for-each>
			<dc:publisher>
				<xsl:value-of select="//book/book-meta/publisher/publisher-name"/>
			</dc:publisher>
			<dc:language>de</dc:language>
			<dc:identifier id="isbn">
				<xsl:value-of select="//book/book-meta/isbn[@content-type='epub']"/>
			</dc:identifier>
			<dc:identifier id="doi">
				<xsl:value-of select="//book/book-meta/book-id[@book-id-type='doi']"/>
			</dc:identifier>
			<dc:date>2019-10-01T00:00:00Z</dc:date>
			<dc:rights>
				<xsl:value-of select="//book/book-meta/permissions/copyright-statement"/>
			</dc:rights>
			<dc:subject>Wissenschaftliches Publizieren</dc:subject>
			<dc:subject>Open Access</dc:subject>
			<dc:subject>Hochschulverlag</dc:subject>
			<meta property="dcterms:modified">2019-09-30T00:00:00Z</meta>
			<meta refines="#title1" property="title-type">main</meta>
			<!-- Angaben für die Barrierefreiheit, noch nicht automatisiert -->
			<meta property="schema:accessMode">textual</meta>
			<meta property="schema:accessMode">visual</meta>
			<meta property="schema:accessModeSufficient">textual,visual</meta>
			<meta property="schema:accessModeSufficient">textual</meta>
			<meta property="schema:accessibilityFeature">MathML</meta>
			<meta property="schema:accessibilityFeature">alternativeText</meta>
			<meta property="schema:accessibilitySummary">Blindtext: diese Publikation enthält 
			Alternativtexte für Abbildungen sowie MathML.In Kapitel 4.4.2 wird eine 
			Formel als Bild dargestellt, da es sich jedoch um ein Musterbeispiel handelt, 
			entstehen hier keine Nachteile für die Zugänglichkeit.</meta>
		</metadata>
							
		<manifest>
			<!-- Inhalt -->
			<xsl:call-template name="manifest"/>
		</manifest>

		<spine toc="ncx">
			<xsl:call-template name="spine"/>
		</spine>

		</package>

</xsl:result-document>

<!-- toc.ncx -->
<xsl:call-template name="tocncx"/>
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template name="manifest">
	<xsl:message>Manifest</xsl:message>
	
	<!-- Schleife über alle Kapitel erster Ordnung-->
	<xsl:for-each select="//book-part[@book-part-type = 'chapter']">
		<xsl:variable name="url">
			<!--<xsl:value-of select="$EPUB_Text_Pfad"/>-->
			<xsl:text>Content/Kapitel_</xsl:text>  <!--Vorläufig, muss noch überprüft werden -->
			<xsl:value-of select="oa:safe-name(book-part-meta/title-group/label)"/>
			<xsl:value-of select="$Contentausgabeformat"/>
		</xsl:variable>
		<xsl:message>
			<xsl:text>Eintrag für: </xsl:text>
			<xsl:value-of select="$url"/>
		</xsl:message>
		<xsl:variable name="uri">
			<xsl:text>Kapitel_</xsl:text>
			<xsl:value-of select="oa:safe-name(book-part-meta/title-group/label)"/>
		</xsl:variable>		
		<item href="{$url}" id="{$uri}" media-type="application/xhtml+xml"/>
	</xsl:for-each>

	<!-- Schleife über alle Kapitel erster Ordnung des Anhangs-->
	<xsl:for-each select="//book-back/book-app-group/book-app">
		<xsl:variable name="url">
			<!--<xsl:value-of select="$EPUB_Text_Pfad"/>-->
			<xsl:text>Content/</xsl:text>  <!--Vorläufig, muss noch überprüft werden -->
			<xsl:value-of select="$Anhang"/>
			<xsl:text>_</xsl:text>
			<xsl:value-of select="oa:safe-name(@id)"/>
			<xsl:value-of select="$Contentausgabeformat"/>
		</xsl:variable>
		<xsl:message>
			<xsl:text>Eintrag für: </xsl:text>
			<xsl:value-of select="$url"/>
		</xsl:message>
		<xsl:variable name="uri">
			<xsl:text>Anhang_</xsl:text>
			<xsl:number value="position()" format="A"/>
		</xsl:variable>		
		<item href="{$url}" id="{$uri}" media-type="application/xhtml+xml"/>
	</xsl:for-each>
	
	<item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/> 
	<item id="nav" properties="nav" href="nav{$Contentausgabeformat}" media-type="application/xhtml+xml"/>
	<item id="stylesheet" href="Styles/{$CSS-Stylesheet}" media-type="text/css"/>
	
	<!-- Angabe restliche Dateien (Verzeichnisse, Titelei) -->
	<item id="coverpage" media-type="application/xhtml+xml" href="Content/Cover{$Contentausgabeformat}"/>
	<item id="halftitlepage" media-type="application/xhtml+xml" href="Content/Schmutztitel{$Contentausgabeformat}"/>
	<item id="titlepage" media-type="application/xhtml+xml" href="Content/Haupttitel{$Contentausgabeformat}"/>
	<item id="copyright" media-type="application/xhtml+xml" href="Content/Impressum{$Contentausgabeformat}"/>
	<item id="abstract" media-type="application/xhtml+xml" href="Content/Zusammenfassung{$Contentausgabeformat}"/>
    <xsl:if test="//ack">
		<item id="ack" media-type="application/xhtml+xml" href="Content/Ack{$Contentausgabeformat}"/>
	</xsl:if>
	<item id="toc" media-type="application/xhtml+xml" href="Content/Inhaltsverzeichnis{$Contentausgabeformat}"/>
	<item id="list_fig" media-type="application/xhtml+xml" href="Content/Abbildungsverzeichnis{$Contentausgabeformat}"/>
	<item id="list_tab" media-type="application/xhtml+xml" href="Content/Tabellenverzeichnis{$Contentausgabeformat}"/>
	<xsl:if test="//glossary/title='Formelzeichen'"> 
		<item id="list_eq" media-type="application/xhtml+xml" href="Content/Formelzeichen{$Contentausgabeformat}"/>
	</xsl:if> 
	<xsl:if test="//glossary/title='Abkürzungsverzeichnis'">
		<item id="list_abbr" media-type="application/xhtml+xml" href="Content/Abkuerzungsverzeichnis{$Contentausgabeformat}"/>
	</xsl:if>
	
	<item id="list_ref" media-type="application/xhtml+xml" href="Content/Literaturverzeichnis{$Contentausgabeformat}"/>
	
	<xsl:if test="//index-term">
		<item id="index" media-type="application/xhtml+xml" href="Content/Index{$Contentausgabeformat}"/>
	</xsl:if>
	
	<!-- Angabe aller Schriften -->
	<item id="font1" href="Fonts/Source_Code_Pro/SourceCodePro-Black.ttf" media-type="application/x-font-ttf"/>
	<item id="font2" href="Fonts/Source_Code_Pro/SourceCodePro-Bold.ttf" media-type="application/x-font-ttf"/>
	<item id="font3" href="Fonts/Source_Code_Pro/SourceCodePro-ExtraLight.ttf" media-type="application/x-font-ttf"/>
	<item id="font4" href="Fonts/Source_Code_Pro/SourceCodePro-Light.ttf" media-type="application/x-font-ttf"/>
	<item id="font5" href="Fonts/Source_Code_Pro/SourceCodePro-Medium.ttf" media-type="application/x-font-ttf"/>
	<item id="font6" href="Fonts/Source_Code_Pro/SourceCodePro-Regular.ttf" media-type="application/x-font-ttf"/>
	<item id="font7" href="Fonts/Source_Code_Pro/SourceCodePro-Semibold.ttf" media-type="application/x-font-ttf"/>
	
	<item id="font8" href="Fonts/Source_Sans_Pro/SourceSansPro-Black.ttf" media-type="application/x-font-ttf"/>
	<item id="font9" href="Fonts/Source_Sans_Pro/SourceSansPro-BlackItalic.ttf" media-type="application/x-font-ttf"/>
	<item id="font10" href="Fonts/Source_Sans_Pro/SourceSansPro-Bold.ttf" media-type="application/x-font-ttf"/>
	<item id="font11" href="Fonts/Source_Sans_Pro/SourceSansPro-BoldItalic.ttf" media-type="application/x-font-ttf"/>
	<item id="font12" href="Fonts/Source_Sans_Pro/SourceSansPro-ExtraLight.ttf" media-type="application/x-font-ttf"/>
	<item id="font13" href="Fonts/Source_Sans_Pro/SourceSansPro-ExtraLightItalic.ttf" media-type="application/x-font-ttf"/>
	<item id="font14" href="Fonts/Source_Sans_Pro/SourceSansPro-Italic.ttf" media-type="application/x-font-ttf"/>
	<item id="font15" href="Fonts/Source_Sans_Pro/SourceSansPro-Light.ttf" media-type="application/x-font-ttf"/>
	<item id="font16" href="Fonts/Source_Sans_Pro/SourceSansPro-LightItalic.ttf" media-type="application/x-font-ttf"/>
	<item id="font17" href="Fonts/Source_Sans_Pro/SourceSansPro-Regular.ttf" media-type="application/x-font-ttf"/>
	<item id="font18" href="Fonts/Source_Sans_Pro/SourceSansPro-SemiBold.ttf" media-type="application/x-font-ttf"/>
	<item id="font19" href="Fonts/Source_Sans_Pro/SourceSansPro-SemiBoldItalic.ttf" media-type="application/x-font-ttf"/>
	
	<item id="font20" href="Fonts/Source_Serif_Pro/SourceSerifPro-Black.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font21" href="Fonts/Source_Serif_Pro/SourceSerifPro-BlackIt.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font22" href="Fonts/Source_Serif_Pro/SourceSerifPro-Bold.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font23" href="Fonts/Source_Serif_Pro/SourceSerifPro-BoldIt.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font24" href="Fonts/Source_Serif_Pro/SourceSerifPro-ExtraLight.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font25" href="Fonts/Source_Serif_Pro/SourceSerifPro-ExtraLightIt.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font26" href="Fonts/Source_Serif_Pro/SourceSerifPro-It.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font27" href="Fonts/Source_Serif_Pro/SourceSerifPro-Light.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font28" href="Fonts/Source_Serif_Pro/SourceSerifPro-LightIt.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font29" href="Fonts/Source_Serif_Pro/SourceSerifPro-Regular.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font30" href="Fonts/Source_Serif_Pro/SourceSerifPro-Semibold.otf" media-type="application/vnd.ms-opentype"/>
	<item id="font31" href="Fonts/Source_Serif_Pro/SourceSerifPro-SemiboldIt.otf" media-type="application/vnd.ms-opentype"/>
	
	<!-- Angabe aller fixen Bilder -->
	<item id="cover" media-type="image/jpeg" href="Images/cover.jpg"/>
	<item id="logo" media-type="image/jpeg" href="Images/HTWK_Logo.jpg"/>
	<item id="qr" media-type="image/jpeg" href="Images/qr-doi.jpg"/>
	<item id="cc-hinweis" media-type="image/jpeg" href="Images/CC_Hinweis.jpg"/>
	
	<!-- Angabe aller variablen Bilder -->
	<xsl:for-each select="//fig">
	        <xsl:variable name="uri_bild">
	                <xsl:text>Images/</xsl:text>
	                <xsl:for-each select="graphic">
                                <xsl:value-of select="@xlink:href"/>      
	                </xsl:for-each>
	        </xsl:variable>
	        <xsl:variable name="id_bild">
                        <xsl:value-of select="@id"/>      
	        </xsl:variable>
	        <item id="{$id_bild}" media-type="image/jpeg" href="{$uri_bild}"/>     
	</xsl:for-each>
	
	<!-- Angabe aller Bilder von Formeln -->
	<xsl:for-each select="//disp-formula">
	        <xsl:variable name="uri_bild">
	                <xsl:text>Images/</xsl:text>
	                <xsl:for-each select="graphic">
                                <xsl:value-of select="@xlink:href"/>      
	                </xsl:for-each>
	        </xsl:variable>
	        <xsl:variable name="id_bild">
                        <xsl:value-of select="@id"/>      
	        </xsl:variable>
	        <item id="{$id_bild}" media-type="image/png" href="{$uri_bild}"/>     
	</xsl:for-each>
	
	<!-- Angabe aller Tabellen, die als Bild eingefügt sind -->
    <xsl:if test="table-wrap/graphic">   
		<xsl:for-each select="//table-wrap">
                <xsl:variable name="uri_bild">
                        <xsl:text>Images/</xsl:text>
                        <xsl:for-each select="graphic">
                                <xsl:value-of select="@xlink:href"/>      
                        </xsl:for-each>
                </xsl:variable>
                <xsl:variable name="id_bild">
                        <xsl:value-of select="@id"/>      
                </xsl:variable>
                <item id="{$id_bild}" media-type="image/jpg" href="{$uri_bild}"/>     
        </xsl:for-each>
	</xsl:if>
        
</xsl:template>
	
<xsl:template name="spine">
	<xsl:message>Spine</xsl:message>
	
	<!-- Verzeichnisse und Titelei -->
	<itemref idref="coverpage"/>
	<itemref idref="halftitlepage"/>
	<itemref idref="titlepage"/>
	<itemref idref="copyright"/>
	<itemref idref="abstract"/>
	
	<xsl:if test="//ack">
		<itemref idref="ack"/>
	</xsl:if>
	
	<itemref idref="toc"/>
	<itemref idref="list_fig"/>
	<itemref idref="list_tab"/>
	
	<xsl:if test="//glossary/title='Formelzeichen'"> 
		<itemref idref="list_eq"/>
	</xsl:if> 
	<xsl:if test="//glossary/title='Abkürzungsverzeichnis'"> 
		<itemref idref="list_abbr"/>
	</xsl:if> 
	
	<!-- Inhaltsinstanzen -->
	<xsl:for-each select="//book-part[@book-part-type = 'chapter']">
		<xsl:variable name="uri">
			<xsl:text>Kapitel_</xsl:text>
			<xsl:value-of select="oa:safe-name(book-part-meta/title-group/label)"/>
		</xsl:variable>		
		<itemref idref="{$uri}" />
	</xsl:for-each>
	
	<!-- Literaturverzeichnis -->
	<itemref idref="list_ref"/>
	
	<!-- Index -->
	<xsl:if test="//index-term"> 
		<itemref idref="index"/>
	</xsl:if> 
	
	<!-- Anhangsinstanzen -->
	<xsl:for-each select="//book-back/book-app-group/book-app">
		<xsl:variable name="uri">
			<xsl:text>Anhang_</xsl:text>
			<xsl:number value="position()" format="A"/>
		</xsl:variable>		
		<itemref idref="{$uri}" />
	</xsl:for-each>
	
</xsl:template>

<xsl:template name="tocncx">
	<xsl:result-document method="xml" href="{$EPUB_tocncx}">
			<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
			   <head>
			   	<meta name="dtb:uid" content="{$DOI}"/>
			   	<meta name="dtb:depth" content="2"/>
			   	<meta name="dtb:totalPageCount" content="0"/>
			   	<meta name="dtb:maxPageNumber" content="0"/>
			   </head>
				<docTitle>
      				<text>Inhaltsverzeichnis</text>
				</docTitle>
				
				<!-- playOrdner funktioniert noch nicht!!! -->
				<navMap>
						
				<!-- Navigationspunkt für das Cover -->
               <navPoint>
					<xsl:attribute name="id">
						<xsl:text>coverpage</xsl:text>
					</xsl:attribute>
					<navLabel>
						<text>Cover</text>
					</navLabel>  
                	<content src="Content/Cover{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für die Titelseite -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>titlepage</xsl:text>
					</xsl:attribute> 
										
					<navLabel>
						<text>Titel</text>
					</navLabel>
					<content src="Content/Haupttitel{$Contentausgabeformat}"></content>
				</navPoint>

				<!-- Navigationspunkt für den Schmutztitel -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>halftitlepage</xsl:text>
					</xsl:attribute> 
										
					<navLabel>
						<text>Schmutzttitel</text>
					</navLabel>
					<content src="Content/Schmutztitel{$Contentausgabeformat}"></content>
				</navPoint>
									
				<!-- Navigationspunkt für das Impressum -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>copyright</xsl:text>
					</xsl:attribute>
										
					<navLabel>
						<text>Impressum</text>
					</navLabel>
					<content src="Content/Impressum{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für das Abstract -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>abstract</xsl:text>
					</xsl:attribute>
										
					<navLabel>
						<text>Zusammenfassung</text>
					</navLabel>
					<content src="Content/Zusammenfassung{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für das Inhaltsverzeichnis -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>toc</xsl:text>
					</xsl:attribute>
										
					<navLabel>
						<text>Inhaltsverzeichnis</text>
					</navLabel>
					<content src="Content/Inhaltsverzeichnis{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für das Abbildungsverzeichnis -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>list_fig</xsl:text>
					</xsl:attribute>	
										
					<navLabel>
						<text>Abbildungsverzeichnis</text>
					</navLabel>
					<content src="Content/Abbildungsverzeichnis{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für das Tabellenverzeichnis -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>list_tab</xsl:text>
					</xsl:attribute>	
					             		
					<navLabel>
						<text>Tabellenverzeichnis</text>
					</navLabel>
					<content src="Content/Tabellenverzeichnis{$Contentausgabeformat}"></content>
				</navPoint>
					
				<!-- Navigationspunkt für die Formelzeichen -->
				<xsl:if test="//glossary/title='Formelzeichen'"> 
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>list_eq</xsl:text>
					</xsl:attribute>
										
					<navLabel>
						<text>Formelzeichen</text>
					</navLabel>
					<content src="Content/Formelzeichen{$Contentausgabeformat}"></content>
				</navPoint>
				</xsl:if>
				        
				<!-- Navigationspunkt für die Abkuerzungsverzeichnis -->
			    <xsl:if test="//glossary/title='Abkürzungsverzeichnis'">
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>list_abbr</xsl:text>
					</xsl:attribute>	
					             		
					<navLabel>
						<text>Abkürzungsverzeichnis</text>
					</navLabel>
					<content src="Content/Abkuerzungsverzeichnis{$Contentausgabeformat}"></content>
				</navPoint>
			    </xsl:if>
				        
				<!-- Navigationspunkte für die Kapitel des Inhalts -->
				<xsl:for-each select="//book-part[@book-part-type='chapter']">
					<xsl:variable name="uri">
			 			<xsl:text>Content/Kapitel_</xsl:text>
						<xsl:value-of select="oa:safe-name(book-part-meta/title-group/label)"/>
						<xsl:value-of select="$Contentausgabeformat"/>
					</xsl:variable>
				        
                	<navPoint>
					<xsl:attribute name="id">
					<xsl:text>Kapitel_</xsl:text>
						<xsl:value-of select="oa:safe-name(book-part-meta/title-group/label)"/>
					</xsl:attribute>
										
					<navLabel>
						<text>
							<xsl:value-of select="book-part-meta/title-group/label"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="book-part-meta/title-group/title"/>
						</text>
					</navLabel>
					<content>
						<xsl:attribute name="src">
							<xsl:value-of select="$uri"/>
						</xsl:attribute>
					</content>
					</navPoint>
				</xsl:for-each>
				
				<!-- Navigationspunkte für die Kapitel des Anhangs -->
				<xsl:for-each select="//book-back/book-app-group/book-app">
					<xsl:variable name="uri">
						<xsl:text>Content/</xsl:text>
						<xsl:value-of select="$Anhang"/>
						<xsl:text>_</xsl:text>
						<xsl:value-of select="oa:safe-name(@id)"/>
						<xsl:value-of select="$Contentausgabeformat"/>
					</xsl:variable>
					
					<navPoint>
					<xsl:attribute name="id">
					<xsl:text>Anhang_</xsl:text>
						<xsl:number value="position()" format="A"/>
					</xsl:attribute>
						           		
					<navLabel>
						<text>
							<xsl:value-of select="book-part-meta/title-group/label"/>
							<xsl:text> </xsl:text>
							<xsl:value-of select="book-part-meta/title-group/title"/>
						</text>
					</navLabel>
					<content>
						<xsl:attribute name="src">
							<xsl:value-of select="$uri"/>
						</xsl:attribute>
					</content>
					</navPoint>
					
				</xsl:for-each>
					
				<!-- Navigationspunkt für das Literaturverzeichnis -->
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>list_ref</xsl:text>
					</xsl:attribute>  
					            							
					<navLabel>
						<text>Literaturverzeichnis</text>
					</navLabel>
					<content src="Content/Literaturverzeichnis{$Contentausgabeformat}"></content>
				</navPoint>
				
				<!-- Navigationspunkt für den Index -->
				<xsl:if test="//index-term"> 
				<navPoint>
					<xsl:attribute name="id">
						<xsl:text>index</xsl:text>
					</xsl:attribute>  
								
					<navLabel>
						<text>Index</text>
					</navLabel>
					<content src="Content/Index{$Contentausgabeformat}"></content>
				</navPoint>
				</xsl:if> 
					
				</navMap>
				
				
			</ncx>
	</xsl:result-document>
</xsl:template>



</xsl:stylesheet>
