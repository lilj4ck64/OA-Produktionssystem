<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Transformationsstylesheet für PDF-Erstellung
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:fo="http://www.w3.org/1999/XSL/Format">




<!-- Einbinden der BITS-Bibliothek-->
<xsl:include href="XMLtoPDF_BITSBibliothek_FOP.xsl"/>


<!-- Template für den Wurzelknoten -->
<xsl:template match="book">

<!-- Anlegen des Zieldokumentes -->
<fo:root>
							   
<!-- *****************************************************
  Anlegen der Musterseiten
********************************************************* -->
	<fo:layout-master-set>
		<!-- Anlegen der rechten Seite -->
		<fo:simple-page-master master-name="rechte_Seite"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
			   <fo:region-body region-name="Satzspiegel"
							   margin-top="{$Abstand_lebender_Kolumnentitel_Satzspiegel}"
							   margin-bottom="{$Abstand_DOI_Satzspiegel}"/>
			 <fo:region-before region-name="Kolumnentitel_ungerade_Seite"/>
		</fo:simple-page-master>
		<!-- Anlegen der ersten rechten Seite ohne Kolumnentitel -->
		<fo:simple-page-master master-name="rechte_Seite_Start"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
			   <fo:region-body region-name="Satzspiegel" 
							   margin-top="{$Abstand_lebender_Kolumnentitel_Satzspiegel}"
							   margin-bottom="{$Abstand_DOI_Satzspiegel}"/>
			  <fo:region-after region-name="DOI_ungerade_Seite"/>
		</fo:simple-page-master>
		<!-- Anlegen der linken Seite -->
        <fo:simple-page-master master-name="linke_Seite"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
			   <fo:region-body region-name="Satzspiegel"
							   margin-top="{$Abstand_lebender_Kolumnentitel_Satzspiegel}"
							   margin-bottom="{$Abstand_DOI_Satzspiegel}"/>
			 <fo:region-before region-name="Kolumnentitel_gerade_Seite"/>
        </fo:simple-page-master>	
		<!-- Anlegen einer leeren linken Seite ohne Kolumnentitel -->
        <fo:simple-page-master master-name="linke_Seite_leer"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
				<fo:region-body region-name="Satzspiegel"/>
				<fo:region-before region-name="header-blank"/>
        </fo:simple-page-master>			
		<!-- Anlegen der rechten Indexseite -->
		<fo:simple-page-master master-name="rechte_Indexseite"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
			   <fo:region-body region-name="Satzspiegel"
							   margin-top="{$Abstand_lebender_Kolumnentitel_Satzspiegel}"
							   margin-bottom="{$Abstand_DOI_Satzspiegel}"/>
			 <fo:region-before region-name="Kolumnentitel_ungerade_Seite"/>
		</fo:simple-page-master>		
		<!-- Anlegen der linken Indexseite -->
        <fo:simple-page-master master-name="linke_Indexseite"
							   page-height="{$Seitenhoehe}"
							   page-width="{$Seitenbreite}"
							   margin-top="{$Kopfsteg}"
							   margin-bottom="{$Fusssteg}"
							   margin-left="{$Bundsteg}"
							   margin-right="{$Aussensteg}">
			   <fo:region-body region-name="Satzspiegel"
							   margin-top="{$Abstand_lebender_Kolumnentitel_Satzspiegel}"
							   margin-bottom="{$Abstand_DOI_Satzspiegel}"/>
			 <fo:region-before region-name="Kolumnentitel_gerade_Seite"/>
        </fo:simple-page-master>

        <!-- Muster einer Seitensequenz für die Titelei -->
        <fo:page-sequence-master master-name="Titelei">
			<fo:repeatable-page-master-alternatives>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite"
													  odd-or-even="even"/>
			</fo:repeatable-page-master-alternatives>
		</fo:page-sequence-master>

        <!-- Muster einer Seitensequenz für die automatisch generierten Verzeichnisse -->
        <fo:page-sequence-master master-name="Verzeichnisse">
			<fo:repeatable-page-master-alternatives>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="first" odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="rest"
													  odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite"
													  page-position="rest"
													  odd-or-even="even"/>
			</fo:repeatable-page-master-alternatives>
		</fo:page-sequence-master>
		
		<!-- Muster einer Seitensequenz für das Literaturverzeichnis (letzte Seite links leer, da Anhang folgt) -->
        <fo:page-sequence-master master-name="Literaturverzeichnis">
			<fo:repeatable-page-master-alternatives>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="first" odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="rest"
													  odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite"
													  page-position="rest"
													  odd-or-even="even"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite_leer"
													  page-position="last"
													  odd-or-even="even"/>
			</fo:repeatable-page-master-alternatives>
		</fo:page-sequence-master>
		
		<!-- Muster einer Seitensequenz für Inhaltsseiten -->
        <fo:page-sequence-master master-name="Inhaltsseiten">
			<fo:repeatable-page-master-alternatives>
				<fo:conditional-page-master-reference master-reference="rechte_Seite_Start"
													  page-position="first"
													  odd-or-even="odd"
													  blank-or-not-blank="not-blank"/>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="rest"
													  odd-or-even="odd"
													  blank-or-not-blank="not-blank"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite"
													  page-position="rest"
													  odd-or-even="even"
													  blank-or-not-blank="not-blank"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite_leer"
													  page-position="rest"
													  odd-or-even="even"
													  blank-or-not-blank="blank"/>
			</fo:repeatable-page-master-alternatives>
        </fo:page-sequence-master>
		
		<!-- Muster einer Seitensequenz für den Index -->
        <fo:page-sequence-master master-name="Indexseiten">
			<fo:repeatable-page-master-alternatives>
				<fo:conditional-page-master-reference master-reference="rechte_Indexseite"
													  page-position="first" odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="rechte_Seite"
													  page-position="rest"
													  odd-or-even="odd"/>
				<fo:conditional-page-master-reference master-reference="linke_Indexseite"
													  page-position="rest"
													  odd-or-even="even"/>
				<fo:conditional-page-master-reference master-reference="linke_Seite_leer"
													  page-position="last"
													  odd-or-even="even"/>
			</fo:repeatable-page-master-alternatives>
		</fo:page-sequence-master>	
	</fo:layout-master-set>
	
<!-- *****************************************************
  Erzeugen der Seitensequenz für die Titelei
********************************************************* -->
	<fo:page-sequence force-page-count="end-on-even" master-reference="Titelei">
	
		<!-- Erzeugen der Fußnotentrennlinie -->
        <fo:static-content flow-name="xsl-footnote-separator">
			<fo:block text-align="{$Blocksatz}"
					  space-before="{$Abstand_davor_Fussnotenlinie}"
					  space-after="{$Abstand_danach_Fussnotenlinie}">
				<fo:leader leader-length="{$Laenge_Fussnotenlinie}"
						   rule-thickness="{$Dicke_Fussnotenlinie}"
						   leader-pattern="{$Muster_Fussnotenlinie}"/>
			</fo:block>
        </fo:static-content>
		
        <fo:flow flow-name="Satzspiegel">
			<fo:block-container hyphenate="{$Silbentrennung_ja}"
								xml:lang="{$Silbentrennung_deutsch}"
							    font-family="{$Grundschriftart}"
								font-size="{$Grundschriftgroesse}"
								line-height="{$Grundschrift_Zeilenabstand}"
								orphans="{$Schusterjunge_Einstellung}"
								widows="{$Hurenkind_Einstellung}">	
				<!-- Schmutztitel setzen -->
				<fo:block>	  
					<xsl:call-template name="Schmutztitel"/>
				</fo:block>
				<!-- Vakatseite zwischen Schmutztitel und Titel anlegen -->	
				<fo:block break-after="page"><fo:leader/></fo:block>
				<!-- Titel setzen -->		
				<fo:block break-after="page">	  
					<xsl:call-template name="Titel"/>
				</fo:block>
				<!-- Impressum setzen -->		
				<fo:block break-after="page">	  
					<xsl:call-template name="Impressum"/>
				</fo:block>
				<!-- Abstract setzen -->		
				<fo:block break-after="page">	  
					<xsl:call-template name="Abstract"/>
				</fo:block>
				<!-- Widmung (optional) setzen -->		
				<xsl:if test="//dedication">
					<fo:block break-after="page">	  
						<xsl:call-template name="Widmung"/>
					</fo:block>
				</xsl:if>

				<!-- Danksagung (optional) setzen -->		
				<xsl:if test="//ack">
					<xsl:for-each select="//ack">
					<fo:block break-after="page">&#032;</fo:block>
					<fo:block break-after="page" >	  
						<xsl:call-template name="Danksagung"/>
					</fo:block>
					</xsl:for-each>
				</xsl:if>
			</fo:block-container>
        </fo:flow>
	</fo:page-sequence>	
						
<!-- *****************************************************
  Erzeugen der Seitensequenz für die automatisch generierten Verzeichnisse
********************************************************* -->
	<fo:page-sequence force-page-count="end-on-even"
					  master-reference="Verzeichnisse"
					  format="I">
	
		<!-- Erzeugen des lebenden Kolumnentitels für gerade Seiten -->
		<fo:static-content flow-name="Kolumnentitel_gerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}">
				<fo:inline text-align="{$linksbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>
				<fo:inline text-align="{$linksbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift"
										retrieve-position="first-including-carryover"/>
				</fo:inline>
			</fo:block>			
        </fo:static-content>
		
		<!-- Erzeugen des lebenden Kolumnentitels für ungerade Seiten -->
        <fo:static-content flow-name="Kolumnentitel_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<fo:inline text-align="{$rechtsbündig}" 
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift"
									    retrieve-position="first-including-carryover"/>
				</fo:inline>
				<fo:inline text-align="{$rechtsbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}">
					<fo:page-number/>
				</fo:inline>		
			</fo:block>
        </fo:static-content>

        <!-- Einen Flow in den Satzspiegel starten -->
        <fo:flow flow-name="Satzspiegel">
			<fo:block hyphenate="{$Silbentrennung_ja}"
					  xml:lang="{$Silbentrennung_deutsch}"
					  font-family="{$Grundschriftart}"
					  font-size="{$Grundschriftgroesse}"
					  line-height="{$Grundschrift_Zeilenabstand}"
					  orphans="{$Schusterjunge_Einstellung}"
					  widows="{$Hurenkind_Einstellung}">
						
			<!-- Inhaltsverzeichnis setzen -->
				<fo:block>
					<fo:block font-family="{$Schriftart_h1}"
							  font-size="{$Schriftgroesse_h1}"
							  line-height="{$Zeilenabstand_h1}"
							  text-align="{$linksbündig}"
							  hyphenate="{$Silbentrennung_nein}"
							  
							  break-before="page">
					<xsl:text>Inhaltsverzeichnis</xsl:text></fo:block>
				<!-- Linie unterhalb der Überschrift -->
					<fo:block space-after="{$Abstand_danach_h1}">
						<fo:leader leader-pattern="{$Muster_Fussnotenlinie}"
								   leader-length="{$Linienlaenge_h1}"
								   rule-style="{$Style_Fussnotenlinie}"
								   rule-thickness="{$Liniendicke_h1}"/>
					</fo:block>
				<!-- Verweis Abbildungsverzeichnis im Inhaltsverzeichnis setzen -->
					<xsl:call-template name="Abbildungsverzeichnis_TOC"/>	
				<!-- Verweis Tabellenverzeichnis im Inhaltsverzeichnis setzen -->
					<xsl:call-template name="Tabellenverzeichnis_TOC"/>	
				<!-- Verweis Abkürzungsverzeichnis im Inhaltsverzeichnis setzen (optional) -->
					<xsl:if test="//glossary[@content-type='Abkuerzungen']">
						<xsl:call-template name="Abkürzungsverzeichnis_TOC"/>
					</xsl:if>
				<!-- Verweis Formelzeichen im Inhaltsverzeichnis setzen (optional) -->
					<xsl:if test="//glossary[@content-type='Formeln']">
						<xsl:call-template name="Formelzeichen_TOC"/>
					</xsl:if>
				<!-- Inhaltsverzeichnis setzen -->
					<xsl:call-template name="TOC"/>	
				<!-- Leerzeile zwischen Kapiteln im Inhaltsverzeichnis und Literaturverzeichnis setzen -->
					<fo:block space-after="{$Grundschrift_Zeilenabstand}"/>	
				<!-- Verweis Literaturverzeichnis und Index (optional) im Inhaltsverzeichnis setzen -->
					<xsl:call-template name="Literaturverzeichnis_Index_TOC"/>
				<!-- Verweis Anhang im Inhaltsverzeichnis setzen -->
					<xsl:call-template name="Anhang_TOC"/>
				</fo:block>	
				
			<!-- Abbildungsverzeichnis setzen -->
				<xsl:call-template name="Abbildungsverzeichnis"/>				
			<!-- Tabellenverzeichnis setzen -->
				<xsl:call-template name="Tabellenverzeichnis"/>			
			<!-- Abkürzungsverzeichnis setzen (optional) -->
				<xsl:if test="//glossary[@content-type='Abkuerzungen']">
					<xsl:call-template name="Abkürzungsverzeichnis"/>
				</xsl:if>
			<!-- Formelzeichen setzen (optional) -->
				<xsl:if test="//glossary[@content-type='Formeln']">
					<xsl:call-template name="Formelzeichen"/>	
				</xsl:if>
				
			</fo:block>
        </fo:flow>
    </fo:page-sequence>

<!-- *****************************************************
  Erzeugen der Seitensequenz für die Inhaltsseiten
********************************************************* -->
	<xsl:for-each select="//book-part[@book-part-type='chapter'] | //book-part[@book-part-type='part']/book-part-meta">
	<fo:page-sequence force-page-count="end-on-even"
					  master-reference="Inhaltsseiten">
	
		<!-- Erzeugen des lebenden Kolumnentitels für gerade Seiten -->
		<fo:static-content flow-name="Kolumnentitel_gerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}">
				<fo:inline text-align="{$linksbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>
				<fo:inline text-align="{$linksbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_1.Grades"
										retrieve-position="first-including-carryover"/>
				</fo:inline>
			</fo:block>			
        </fo:static-content>
		
		<!-- Erzeugen des lebenden Kolumnentitels für ungerade Seiten -->
        <fo:static-content flow-name="Kolumnentitel_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<fo:inline text-align="{$rechtsbündig}">
					
					<!-- Überschrift erster Ordnung nur anzeigen, wenn keine Überschrift zweiter Ordnung, 
					ansonsten zweite Ordnung anzeigen -->
					<xsl:choose>
						<xsl:when test="body/sec">
							<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_2.Grades"
								retrieve-boundary="document"
								retrieve-position="first-including-carryover"/>
						</xsl:when>
						<xsl:otherwise>
							<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_1.Grades"
								retrieve-boundary="document"
								retrieve-position="first-including-carryover"/>
						</xsl:otherwise>
					</xsl:choose>
				</fo:inline>
				<fo:inline text-align="{$rechtsbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}">
					<fo:page-number/>
				</fo:inline>		
			</fo:block>
        </fo:static-content>
		
		<!-- Für leere linke Seiten ohne Kolumnentitel -->
		<fo:static-content flow-name="header-blank">
			<fo:block><fo:leader/></fo:block>			
        </fo:static-content>

		<xsl:if test="../book-part[@book-part-type='chapter']">
		<!-- Erzeugen der DOI für ungerade Seiten -->
 		<fo:static-content flow-name="DOI_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<xsl:text>http://doi.org/</xsl:text>
				<fo:retrieve-marker retrieve-class-name="DOI"></fo:retrieve-marker>				
			</fo:block>
        </fo:static-content>
		</xsl:if>
					
		<!-- Erzeugen der Fußnotentrennlinie -->
        <fo:static-content flow-name="xsl-footnote-separator">
			<fo:block text-align="{$Blocksatz}"
					  space-before="{$Abstand_davor_Fussnotenlinie}"
					  space-after="{$Abstand_danach_Fussnotenlinie}">
				<fo:leader leader-length="{$Laenge_Fussnotenlinie}"
						   rule-thickness="{$Dicke_Fussnotenlinie}"
						   leader-pattern="{$Muster_Fussnotenlinie}"/>
			</fo:block>
        </fo:static-content>

        <!-- Einen Flow in den Satzspiegel starten -->
        <fo:flow flow-name="Satzspiegel">
			<fo:block hyphenate="{$Silbentrennung_ja}"
					  xml:lang="{$Silbentrennung_deutsch}"
					  font-family="{$Grundschriftart}" 
					  font-size="{$Grundschriftgroesse}"
					  text-align="{$Satzart}"
					  line-height="{$Grundschrift_Zeilenabstand}"
					  orphans="{$Schusterjunge_Einstellung}"
					  widows="{$Hurenkind_Einstellung}"
					  hyphenation-ladder-count="3"
					  hyphenation-push-character-count="2"
					  hyphenation-remain-character-count="3"> <!-- Registerhaltigkeit einstellen -->	
				<xsl:apply-templates/>
			</fo:block>
        </fo:flow>
    </fo:page-sequence>
	</xsl:for-each>
	
<!-- *****************************************************
  Erzeugen der Seitensequenz für das Literaturverzeichnis
********************************************************* -->
	<fo:page-sequence force-page-count="end-on-even"
					  master-reference="Literaturverzeichnis">
	
		<!-- Erzeugen des lebenden Kolumnentitels für gerade Seiten -->
		<fo:static-content flow-name="Kolumnentitel_gerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}">
				<fo:inline text-align="{$linksbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>
				<fo:inline text-align="{$linksbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_1.Grades"
										retrieve-position="first-including-carryover"/>
				</fo:inline>
			</fo:block>			
        </fo:static-content>
		
		<!-- Erzeugen des lebenden Kolumnentitels für ungerade Seiten -->
        <fo:static-content flow-name="Kolumnentitel_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<fo:inline text-align="{$rechtsbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_2.Grades"
										retrieve-boundary="document"
									    retrieve-position="first-including-carryover"/>
				</fo:inline>
				<fo:inline text-align="{$rechtsbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-start="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>		
			</fo:block>
        </fo:static-content>
					
		<!-- Erzeugen der Fußnotentrennlinie -->
        <fo:static-content flow-name="xsl-footnote-separator">
			<fo:block text-align="{$Blocksatz}"
					  space-before="{$Abstand_davor_Fussnotenlinie}"
					  space-after="{$Abstand_danach_Fussnotenlinie}">
				<fo:leader leader-length="{$Laenge_Fussnotenlinie}"
						   rule-thickness="{$Dicke_Fussnotenlinie}"
						   leader-pattern="{$Muster_Fussnotenlinie}"/>
			</fo:block>
        </fo:static-content>

        <!-- Einen Flow in den Satzspiegel starten -->
        <fo:flow flow-name="Satzspiegel">
			<fo:block hyphenate="{$Silbentrennung_ja}"
					  xml:lang="{$Silbentrennung_deutsch}"
					  font-family="{$Grundschriftart}" 
					  font-size="{$Grundschriftgroesse}"
					  text-align="{$linksbündig}"
					  line-height="{$Grundschrift_Zeilenabstand}"
					  orphans="{$Schusterjunge_Einstellung}"
					  widows="{$Hurenkind_Einstellung}">	
				<!-- Literaturverzeichnis setzen -->
			    <xsl:call-template name="Literaturverzeichnis"/>					
			</fo:block>
        </fo:flow>
    </fo:page-sequence>
	
<!-- *****************************************************
  Erzeugen der Seitensequenz für den Anhang
********************************************************* -->
	<xsl:for-each select="//book-app | //book-app-group/book-part-meta">
	<fo:page-sequence force-page-count="end-on-even"
					  master-reference="Inhaltsseiten">
	
		<!-- Erzeugen des lebenden Kolumnentitels für gerade Seiten -->
		<fo:static-content flow-name="Kolumnentitel_gerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}">
				<fo:inline text-align="{$linksbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>
				<fo:inline text-align="{$linksbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_1.Grades"
										retrieve-position="first-including-carryover"/>
				</fo:inline>
			</fo:block>			
        </fo:static-content>
		
		<!-- Erzeugen des lebenden Kolumnentitels für ungerade Seiten -->
        <fo:static-content flow-name="Kolumnentitel_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<fo:inline text-align="{$rechtsbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift_1.Grades"
										retrieve-boundary="document"
									    retrieve-position="first-including-carryover"/>
				</fo:inline>
				<fo:inline text-align="{$rechtsbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-start="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>		
			</fo:block>
        </fo:static-content>
		
		<!-- Erzeugen der DOI für Kapitelanfang des Anhangs -->
		<xsl:if test="book-part-meta/book-part-id">
		<fo:static-content flow-name="DOI_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<xsl:text>http://doi.org/</xsl:text>
				<fo:retrieve-marker retrieve-class-name="DOI"></fo:retrieve-marker>				
			</fo:block>
        </fo:static-content>
		</xsl:if>
					
		<!-- Erzeugen der Fußnotentrennlinie -->
        <fo:static-content flow-name="xsl-footnote-separator">
			<fo:block text-align="{$Blocksatz}"
					  space-before="{$Abstand_davor_Fussnotenlinie}"
					  space-after="{$Abstand_danach_Fussnotenlinie}">
				<fo:leader leader-length="{$Laenge_Fussnotenlinie}"
						   rule-thickness="{$Dicke_Fussnotenlinie}"
						   leader-pattern="{$Muster_Fussnotenlinie}"/>
			</fo:block>
        </fo:static-content>

        <!-- Einen Flow in den Satzspiegel starten -->
        <fo:flow flow-name="Satzspiegel">
			<fo:block hyphenate="{$Silbentrennung_ja}"
					  xml:lang="{$Silbentrennung_deutsch}"
					  font-family="{$Grundschriftart}" 
					  font-size="{$Grundschriftgroesse}"
					  text-align="{$Satzart}"
					  line-height="{$Grundschrift_Zeilenabstand}"
					  orphans="{$Schusterjunge_Einstellung}"
					  widows="{$Hurenkind_Einstellung}"
					  > <!-- Registerhaltigkeit einstellen -->			
				<!--  Versetzen des Kontextknotens auf den Knoten book-back -->
				<xsl:apply-templates/>	
			</fo:block>
        </fo:flow>
    </fo:page-sequence>
	</xsl:for-each>
		
<!-- *****************************************************
  Erzeugen der Seitensequenz für den Index, falls vorhanden
********************************************************* -->
<xsl:if test="//index-term">
	<fo:page-sequence force-page-count="end-on-even"
					  master-reference="Indexseiten">
	
	<!-- Erzeugen des lebenden Kolumnentitels für gerade Seiten -->
		<fo:static-content flow-name="Kolumnentitel_gerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}">
				<fo:inline text-align="{$linksbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-end="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>
				<fo:inline text-align="{$linksbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift"
										retrieve-position="first-including-carryover"/>
				</fo:inline>
			</fo:block>			
        </fo:static-content>
		
		<!-- Erzeugen des lebenden Kolumnentitels für ungerade Seiten -->
        <fo:static-content flow-name="Kolumnentitel_ungerade_Seite">
			<fo:block font-size="{$Schriftgroesse_lebender_Kolumnentitel}"
					  font-family="{$Schriftart_lebender_Kolumnentitel}"
					  text-align="{$rechtsbündig}">
				<fo:inline text-align="{$rechtsbündig}">
					<fo:retrieve-marker retrieve-class-name="Kapitelueberschrift"
										retrieve-boundary="document"
									    retrieve-position="first-including-carryover"/>
				</fo:inline>
				<fo:inline text-align="{$rechtsbündig}"
						   font-size="{$Schriftgroesse_Kolumnentitel_Pagina}"
						   font-family="{$Schriftart_Kolumnentitel_Pagina}"
						   space-start="{$Abstand_Pagina_Kolumnentitel}">
					<fo:page-number/>
				</fo:inline>		
			</fo:block>
        </fo:static-content>

        <!-- Einen Flow in den Satzspiegel starten -->
        <fo:flow flow-name="Satzspiegel">
			<fo:block break-after="page">	  
				<xsl:call-template name="Index"/>
			</fo:block>
        </fo:flow>
	</fo:page-sequence>
</xsl:if>
	
</fo:root>
</xsl:template>

<!-- *****************************************************
  Template für den Schmutztitel
********************************************************* -->
<xsl:template name="Schmutztitel">
	<fo:block font-size="{$Schriftgroesse_Schmutztitel_Autor}"
			  font-family="{$Schriftart_Schmutztitel_Autor}" 
			  line-height="{$Zeilenabstand_Schmutztitel_Autor}"
			  space-after="{$Abstand_danach_Schmutztitel_Autor}"
			  text-align="{$Textausrichtung_Schmutztitel}">  
			  <xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']">
				<fo:block>
				  <xsl:value-of select="name/given-names"/>
				  <xsl:text> </xsl:text>
				  <xsl:value-of select="name/surname"/>
				</fo:block>
			  </xsl:for-each>
	</fo:block>
	<fo:block font-size="{$Schriftgroesse_Schmutztitel_Titel}"
			  font-family="{$Schriftart_Schmutztitel_Titel}" 
			  line-height="{$Zeilenabstand_Schmutztitel_Titel}"
			  text-align="{$Textausrichtung_Schmutztitel}"
			  space-before="{$Abstand_davor_Schmutztitel_Titel}"
			  hyphenate="{$Silbentrennung_nein}">
			  <xsl:apply-templates select="book-meta/book-title-group/book-title"/>
	</fo:block>
	<fo:block font-size="{$Schriftgroesse_Schmutztitel_Untertitel}"
			  font-family="{$Schriftart_Schmutztitel_Untertitel}" 
			  line-height="{$Zeilenabstand_Schmutztitel_Untertitel}"
			  text-align="{$Textausrichtung_Schmutztitel}"
			  break-after="page"
			  hyphenate="{$Silbentrennung_nein}">
			  <xsl:apply-templates select="book-meta/book-title-group/subtitle"/>
	</fo:block>
</xsl:template>

<!-- *****************************************************
  Template für den Titel
********************************************************* -->
<xsl:template name="Titel">
	<fo:block font-size="{$Schriftgroesse_Titel_Autor}"
			  font-family="{$Schriftart_Titel_Autor}" 
			  line-height="{$Zeilenabstand_Titel_Autor}">
			  
			  <xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']">
				<fo:block space-before="{$Zeilenabstand_Schmutztitel_mehrereAutoren}">
				  <xsl:value-of select="name/given-names"/>
				  <xsl:text> </xsl:text>
				  <xsl:value-of select="name/surname"/>
				</fo:block>
			  </xsl:for-each>
			  
	</fo:block>
	<fo:block font-size="{$Schriftgroesse_Titel_Titel}"
			  font-family="{$Schriftart_Titel_Titel}" 
			  line-height="{$Zeilenabstand_Titel_Titel}"
			  space-before="{$Abstand_davor_Titel_Titel}"
			  space-after="{$Abstand_danach_Titel_Titel}"
			  hyphenate="{$Silbentrennung_nein}">
			  <xsl:apply-templates select="book-meta/book-title-group/book-title"/>
	</fo:block>
	<fo:block font-size="{$Schriftgroesse_Titel_Untertitel}"
			  font-family="{$Schriftart_Titel_Untertitel}" 
			  line-height="{$Zeilenabstand_Titel_Untertitel}"
			  hyphenate="{$Silbentrennung_nein}">
			  <xsl:apply-templates select="book-meta/book-title-group/subtitle"/>
	</fo:block>
	<!-- Einfügen des Institut-Logos -->		
	<fo:block-container absolute-position="absolute"
						top="{$Abstand_davor_Logo_Titel}">
		<fo:block>
			<fo:external-graphic content-width="{$Skalierung_Logo_Titel}" src="{$Shared_Images}HTWK_Logo.jpg"/>
		</fo:block>
	</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Template für das Impressum
********************************************************* -->
<xsl:template name="Impressum">
	<fo:block-container font-size="{$Schriftgroesse_Impressum}"
						line-height="{$Zeilenabstand_Impressum}"
						font-family="{$Schriftart_Impressum}"
						break-before="page">
		<!-- Einfügen der Autorenbeschreibung -->	
		<xsl:choose>
			<!-- BEdingung funktioniert noch nicht -->
			<xsl:when test="book-meta/contrib-group/contrib[@id='author_2']">
				<fo:block font-family="{$Schriftart_Ueberschrift_Impressum}">
					<xsl:text>Über die Autoren</xsl:text>
				</fo:block>
			</xsl:when>
			<xsl:otherwise>
				<fo:block font-family="{$Schriftart_Ueberschrift_Impressum}">
					<xsl:text>Über den Autor</xsl:text>
				</fo:block>
			</xsl:otherwise>
		</xsl:choose>

		<xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']/bio[@content-type='about-the-author']">
			<fo:block space-after="{$Abstand_davor_Ueberschrift_Impressum}">
				<xsl:apply-templates select="p"/>
				<xsl:apply-templates select="semibold"/>
				<xsl:apply-templates select="italic"/>
			</fo:block>
		</xsl:for-each>
	</fo:block-container>
	<fo:block-container font-size="{$Schriftgroesse_Impressum}"
						line-height="{$Zeilenabstand_Impressum}"
						font-family="{$Schriftart_Impressum}"
						absolute-position="absolute" top="{$Abstand_untererBlock_Impressum}">
		<!-- Einfügen des DNB-Hinweises -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">
			<fo:block font-family="{$Schriftart_Ueberschrift_Impressum}">
				<xsl:text>Bibliografische Information der Deutschen Nationalbibliothek</xsl:text>
			</fo:block>
			<fo:block>
				<xsl:text>Die Deutsche Nationalbibliothek verzeichnet diese Publikation in der Deutschen Nationalbibliografie.
				Detaillierte bibliografische Daten sind im Internet unter http://dnb.de abrufbar.</xsl:text>
			</fo:block>
		</fo:block-container>
		<!-- Einfügen des CC-Hinweises -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">
			<fo:table>
				<fo:table-column column-number="1" column-width="{$Spaltenbreite_CC-Hinweis}"></fo:table-column>
				<fo:table-column column-number="2"></fo:table-column>
				<fo:table-body>
					<fo:table-row>
						<fo:table-cell column-number="1">
							<fo:block>
								<fo:external-graphic content-width="{$Skalierung_CC-Hinweis}" src="{$Shared_Images}CC_Hinweis.jpg"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell column-number="2">
							<fo:block hyphenate="{$Silbentrennung_nein}">
								<xsl:value-of select="book-meta/permissions/license/license-p"/>
							</fo:block>							
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>			
		</fo:block-container>
		<!-- Einfügen des QR-Code und der DOI -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">
			<fo:table>
				<fo:table-column column-number="1" column-width="{$Spaltenbreite_QR-Code}"></fo:table-column>
				<fo:table-column column-number="2"></fo:table-column>
				<fo:table-body>
					<fo:table-row>
						<fo:table-cell column-number="1">
							<fo:block>
								<fo:external-graphic content-width="{$Skalierung_QR-Code}" src="{$Projektpfad}/Media/Images/qr-doi.jpg"/>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell column-number="2">
							<fo:block>
								<xsl:text>Die Online-Version dieser Publikation ist abrufbar unter</xsl:text>
							</fo:block>	
							<fo:block>
								<xsl:text>http://doi.org/</xsl:text>
								<xsl:value-of select="book-meta/book-id[@book-id-type='doi']"/>
							</fo:block>	
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>		
		</fo:block-container>
		<!-- Einfügen des Copyright-Verweis -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">	
			<fo:block>
				<xsl:value-of select="book-meta/permissions/copyright-statement"/>
			</fo:block>		
		</fo:block-container>
		<!-- Einfügen des Herausgebers -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">
			<fo:block font-family="{$Schriftart_Ueberschrift_Impressum}">
				<xsl:text>Herausgeber</xsl:text>
			</fo:block>
			<fo:block>
				<xsl:value-of select="book-meta/publisher/publisher-name"/>
			</fo:block>
			<fo:block>
				<xsl:value-of select="book-meta/publisher/publisher-loc/institution"/>
			</fo:block>
			<fo:block>
				<xsl:value-of select="book-meta/publisher/publisher-loc/addr-line"/>
			</fo:block>	
			<fo:block>
				<fo:inline>
					<xsl:value-of select="book-meta/publisher/publisher-loc/postal-code"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="book-meta/publisher/publisher-loc/city"/>
				</fo:inline>
			</fo:block>	
			<fo:block>
				<xsl:value-of select="book-meta/publisher/publisher-loc/country"/>
			</fo:block>				
		</fo:block-container>
		<!-- Einfügen des Druck-Verweises -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">	
			<fo:block>
				<xsl:text>Druck und Bindung in Deutschland und den Niederlanden</xsl:text>
			</fo:block>
			<fo:block>
				<xsl:text>Gedruckt auf säurefreiem Papier</xsl:text>
			</fo:block>				
		</fo:block-container>
		<!-- Einfügen der ISBN für das gewählte Ausgabeformat -->	
		<fo:block-container space-before="{$Abstand_davor_Ueberschrift_Impressum}">
			<fo:block>
				<xsl:text>ISBN (Hardcover) </xsl:text>
				<xsl:value-of select="book-meta/isbn[@content-type='hardcover']"/>
			</fo:block>
			<fo:block>
				<xsl:text>ISBN (Softcover) </xsl:text>
				<xsl:value-of select="book-meta/isbn[@content-type='softcover']"/>
			</fo:block>	
			<fo:block>
				<xsl:text>ISBN (ePub) </xsl:text>
				<xsl:value-of select="book-meta/isbn[@content-type='epub']"/>
			</fo:block>	
			<fo:block>
				<xsl:text>ISBN (PDF) </xsl:text>
				<xsl:value-of select="book-meta/isbn[@content-type='pdf']"/>
			</fo:block>	
		</fo:block-container>
	</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Template für die Widmung
********************************************************* -->
<xsl:template name="Widmung">
	<!-- Leerseite vor der Widmung anlegen -->
	<fo:block break-after="page"><fo:leader/></fo:block> 
	<fo:block break-after="page"
			  text-align="{$zentriert}"
			  font-family="{$Fließtext_Italic}"
			  hyphenation-ladder-count="3"
			  hyphenation-push-character-count="2"
			  hyphenation-remain-character-count="3">
	<xsl:value-of select="front-matter/dedication/named-book-part-body/p"/>
	</fo:block>
	<!-- Leerseite nach der Widmung anlegen -->
	<fo:block break-after="page"><fo:leader/></fo:block>
</xsl:template>

<!-- *****************************************************
  Template für die Danksagung
********************************************************* -->
<xsl:template name="Danksagung">
	<fo:block-container >
		<fo:block font-family="{$Schriftart_h2}"
				  font-size="{$Schriftgroesse_h2}"
				  line-height="{$Zeilenabstand_h2}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  space-before="{$Abstand_davor_h2}"
				  space-after="{$Abstand_danach_h2}"
				  hyphenation-ladder-count="3"
				  hyphenation-push-character-count="2"
				  hyphenation-remain-character-count="3">
				  <xsl:value-of select="title"/>
		</fo:block>
		<fo:block text-align="{$Blocksatz}">
			<xsl:apply-templates select="p"/>
		</fo:block>
		<fo:block space-before="{$Grundschrift_Zeilenabstand}">
			<xsl:value-of select="disp-quote/p"/>
		</fo:block>
		<fo:block>
			<xsl:value-of select="disp-quote/attrib"/>
		</fo:block>
	</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Template für das Abstract
********************************************************* -->
<xsl:template name="Abstract">
	<fo:block-container hyphenate="{$Silbentrennung_ja}"
						font-family="{$Grundschriftart}"
						font-size="{$Grundschriftgroesse}"
						text-align="{$Satzart}"
						line-height="{$Grundschrift_Zeilenabstand}"
						
						hyphenation-ladder-count="3"
						hyphenation-push-character-count="2"
						hyphenation-remain-character-count="3">
		<fo:block font-family="{$Schriftart_h2}"
				  font-size="{$Schriftgroesse_h2}"
				  line-height="{$Zeilenabstand_h2}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  space-before="{$Abstand_davor_h2}"
				  space-after="{$Abstand_danach_h2}">
				<xsl:text>Kurzfassung</xsl:text>
		</fo:block>
		<xsl:for-each select="book-meta/abstract">
			<xsl:apply-templates select="p"/>
		</xsl:for-each>
		<fo:block font-family="{$Schriftart_h2}"
				  font-size="{$Schriftgroesse_h2}"
				  line-height="{$Zeilenabstand_h2}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  space-before="{$Abstand_davor_h2}"
				  space-after="{$Abstand_danach_h2}">
				<xsl:text>Abstract</xsl:text>
		</fo:block>
		<xsl:for-each select="book-meta/trans-abstract">
			<fo:block hyphenate="{$Silbentrennung_ja}" xml:lang="en">
				<xsl:apply-templates select="p"/>
			</fo:block>
		</xsl:for-each>
	</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Templates für das Inhaltsverzeichnis
********************************************************* -->

<!-- Template für Inhaltsverzeichnis -->
<xsl:template name="TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:text>Inhaltsverzeichnis</xsl:text>
		</fo:marker>
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
				<!-- Schleife über alle Knoten sec (für Überschrift 2.-4. Ordnung) -->		
				<xsl:for-each select="book-body/book-part/body/sec[@sec-type='TOC'] | 
									  book-body/book-part/body/sec/sec[@sec-type='TOC'] | 
									  book-body/book-part/body/sec/sec/sec[@sec-type='TOC'] |
									  book-body/book-part/body/book-part/book-part-meta/title-group | 
									  book-body/book-part/body/book-part/body/sec[@sec-type='TOC'] |
									  book-body/book-part/body/book-part/body/sec/sec[@sec-type='TOC'] |
									  //book-body/book-part/book-part-meta/title-group">					
			
				<!-- Bedingte Formatierungen -->
				<xsl:choose>				
				<xsl:when test="../title-group"> 
					<!-- Kapitel 1.Ordnung Bold setzen -->
					<fo:table-row>
						<!-- Spalte für das Kapitel -->	
						<fo:table-cell column-number="1" padding-before="{$Grundschrift_Zeilenabstand}">	
							<fo:block text-align-last="{$Blocksatz}" font-family="{$Fließtext_Bold}">
								
								<fo:inline space-end="{$Abstand_Label_Title}">
									<xsl:value-of select="label"/>
								</fo:inline>
								<xsl:value-of select="title"/>
								<xsl:text> </xsl:text>
								<fo:inline>
									<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
								</fo:inline>
								
							</fo:block>	
						</fo:table-cell>
						<!-- Spalte für die Pagina des Kapitels -->	
						<fo:table-cell column-number="2" padding-before="{$Grundschrift_Zeilenabstand}" display-align="after">
							<fo:block text-align="{$rechtsbündig}" font-family="{$Fließtext_Bold}">
								<fo:page-number-citation ref-id="{generate-id(.)}"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:when>
					
				<xsl:otherwise>
					<fo:table-row>
						<!-- Spalte für das Kapitel -->	
						<fo:table-cell column-number="1">	
							<fo:block text-align-last="{$Blocksatz}">
								<fo:inline space-end="{$Abstand_Label_Title}">
									<xsl:value-of select="label"/>
								</fo:inline>
								<xsl:value-of select="title"/>
								<xsl:text> </xsl:text>
								<fo:inline>
									<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
								</fo:inline>
							</fo:block>
						</fo:table-cell>
					
						<!-- Spalte für die Pagina des Kapitels -->	
						<fo:table-cell column-number="2" display-align="after">
							<fo:block text-align="{$rechtsbündig}">
								<fo:page-number-citation ref-id="{generate-id(.)}"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:otherwise>
				</xsl:choose>
				
				</xsl:for-each>
			</fo:table-body>
		</fo:table>
	</fo:block>
</xsl:template>

<!-- Template für Eintrag Tabellenverzeichnis im Inhaltsverzeichnis -->
<xsl:template name="Tabellenverzeichnis_TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}">
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell column-number="1">
						<fo:block text-align-last="{$Blocksatz}">
							<fo:basic-link internal-destination="Tabellenverzeichnis">
								<xsl:text>Tabellenverzeichnis </xsl:text>
								<fo:inline>
									<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
								</fo:inline>
							</fo:basic-link>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell column-number="2">
						<fo:block text-align="{$rechtsbündig}">
							<fo:basic-link internal-destination="Tabellenverzeichnis">
								<fo:page-number-citation ref-id="Tabellenverzeichnis"/>
							</fo:basic-link>
						</fo:block>
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
</xsl:template>

<!-- Template für Eintrag Abbildungsverzeichnis im Inhaltsverzeichnis -->
<xsl:template name="Abbildungsverzeichnis_TOC">
	<fo:block font-family="{$Grundschriftart}" font-size="{$Schriftgroesse_IHV}">
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row>
						<fo:table-cell column-number="1">
							<fo:block text-align-last="{$Blocksatz}">
								<fo:basic-link internal-destination="Abbildungsverzeichnis">
									<xsl:text>Abbildungsverzeichnis </xsl:text>
									<fo:inline>
										<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
									</fo:inline>
								</fo:basic-link>
							</fo:block>
						</fo:table-cell>
						<fo:table-cell column-number="2">
							<fo:block text-align="{$rechtsbündig}">
								<fo:basic-link internal-destination="Abbildungsverzeichnis">
									<fo:page-number-citation ref-id="Abbildungsverzeichnis"/>
								</fo:basic-link>
							</fo:block>
						</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
</xsl:template>

<!-- Template für Eintrag Abkürzungsverzeichnis im Inhaltsverzeichnis -->
<xsl:template name="Abkürzungsverzeichnis_TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}">
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell column-number="1">
						<fo:block text-align-last="{$Blocksatz}">
								<fo:block>
									<fo:basic-link internal-destination="Abkürzungsverzeichnis">
										<xsl:value-of select="//glossary[@content-type='Abkuerzungen']/title"/>
										<fo:inline>
											<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
										</fo:inline>
									</fo:basic-link>
								</fo:block>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell column-number="2">
							<fo:block text-align="{$rechtsbündig}">
								<fo:basic-link internal-destination="Abkürzungsverzeichnis">
									<fo:page-number-citation ref-id="Abkürzungsverzeichnis"/>
								</fo:basic-link>
							</fo:block>
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
</xsl:template>

<!-- Template für Eintrag Formelzeichen im Inhaltsverzeichnis -->
<xsl:template name="Formelzeichen_TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}">
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row>
					<fo:table-cell column-number="1">
						<fo:block text-align-last="{$Blocksatz}">
								<fo:block>
									<fo:basic-link internal-destination="Formelzeichen">
										<xsl:value-of select="//glossary[@content-type='Formeln']/title"/>
										<fo:inline>
											<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
										</fo:inline>
									</fo:basic-link>
								</fo:block>
						</fo:block>
					</fo:table-cell>
					<fo:table-cell column-number="2">
							<fo:block text-align="{$rechtsbündig}">
								<fo:basic-link internal-destination="Formelzeichen">
									<fo:page-number-citation ref-id="Formelzeichen"/>
								</fo:basic-link>
							</fo:block>
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
</xsl:template>

<!-- Template für Eintrag Literaturverzeichnis und Index (optional) im Inhaltsverzeichnis -->
<xsl:template name="Literaturverzeichnis_Index_TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}">
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			<fo:table-body>
				<fo:table-row>	
					<!-- Spalte für das Kapitel -->	
					<fo:table-cell column-number="1">
						<!-- Schleife über alle Knoten book-back/ref-list (für Literaturverzeichnis) -->		
						<xsl:for-each select="//book-back/ref-list">
							<fo:block text-align-last="{$Blocksatz}"
									  space-before="{$Grundschrift_Zeilenabstand}">
									  <fo:basic-link internal-destination="Literaturverzeichnis">
										  <xsl:value-of select="title"/>
										  <xsl:text></xsl:text>
										  <fo:inline>
											<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
										  </fo:inline>
									  </fo:basic-link>
							</fo:block>		
						</xsl:for-each>
					</fo:table-cell>
					<!-- Spalte für die Pagina des Kapitels -->	
					<fo:table-cell column-number="2">
						<xsl:for-each select="//book-back/ref-list">
							<fo:block text-align="{$rechtsbündig}" space-before="{$Grundschrift_Zeilenabstand}">
								<fo:basic-link internal-destination="Literaturverzeichnis">
									<fo:page-number-citation ref-id="Literaturverzeichnis"/>
								</fo:basic-link>
							</fo:block>
						</xsl:for-each>
					</fo:table-cell>
				</fo:table-row>
			</fo:table-body>
		</fo:table>
	</fo:block>
	
	<xsl:if test="//index-term">
		<fo:block font-family="{$Grundschriftart}" font-size="{$Schriftgroesse_IHV}">
			<fo:table>
				<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
				</fo:table-column>
				<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
				</fo:table-column>
				<fo:table-body>
					<fo:table-row>	
						<!-- Spalte für den Index-Titel -->	
						<fo:table-cell column-number="1">
							<fo:block text-align-last="{$Blocksatz}"
									  space-before="{$Grundschrift_Zeilenabstand}">
								<fo:basic-link internal-destination="Index">
									<xsl:text>Index</xsl:text>
									<fo:inline>
										<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
									</fo:inline>
								</fo:basic-link>
							</fo:block>
						</fo:table-cell>
						<!-- Spalte für die Pagina des Index -->	
						<fo:table-cell column-number="2">
								<fo:block text-align="{$rechtsbündig}" space-before="{$Grundschrift_Zeilenabstand}">
									<fo:basic-link internal-destination="Index">
										<fo:page-number-citation ref-id="Index"/>
									</fo:basic-link>
								</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</fo:table-body>
			</fo:table>
		</fo:block>
	</xsl:if>
</xsl:template>

<!-- Template für Eintrag Anhang im Inhaltsverzeichnis -->
<xsl:template name="Anhang_TOC">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  break-after="page">
		
		<fo:table>
			<fo:table-column column-number="2" column-width="{$Breite_Pagina_TOC}">
			</fo:table-column>
			<fo:table-column column-number="1" column-width="{$Breite_Text_TOC}">
			</fo:table-column>
			
			<fo:table-body>
				<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
				<!-- Schleife über alle Knoten sec (für Überschrift 2.-4. Ordnung) -->		
				<xsl:for-each select="//book-back/book-app-group/book-part-meta/title-group | 
									  //book-app-group/book-app/book-part-meta/title-group | 
									  //book-app-group/book-app/body/sec[@sec-type='TOC']">				

				<!-- Bedingte Formatierungen -->
				<xsl:choose>				
				<xsl:when test="../title-group"> 
					<!-- Kapitel 1.Ordnung Bold setzen -->
					<fo:table-row>
						<!-- Spalte für das Kapitel -->	
						<fo:table-cell column-number="1" padding-before="{$Grundschrift_Zeilenabstand}">	
							<fo:block text-align-last="{$Blocksatz}" font-family="{$Fließtext_Bold}">

									<fo:inline space-end="{$Abstand_Label_Title}">
										<xsl:value-of select="label"/>
									</fo:inline>
									<xsl:value-of select="title"/>
									<xsl:text> </xsl:text>
									<fo:inline>
										<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
									</fo:inline>

							</fo:block>	
						</fo:table-cell>
						<!-- Spalte für die Pagina des Kapitels -->	
						<fo:table-cell column-number="2" padding-before="{$Grundschrift_Zeilenabstand}" display-align="after">
							<fo:block text-align="{$rechtsbündig}" font-family="{$Fließtext_Bold}">

									<fo:page-number-citation ref-id="{generate-id(.)}"/>

							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:when>
					
				<xsl:otherwise>
					<fo:table-row>
						<!-- Spalte für das Kapitel -->	
						<fo:table-cell column-number="1">	
							<fo:block text-align-last="{$Blocksatz}">

									<fo:inline space-end="{$Abstand_Label_Title}">
										<xsl:value-of select="label"/>
									</fo:inline>
									<xsl:value-of select="title"/>
									<xsl:text> </xsl:text>
									<fo:inline>
										<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
									</fo:inline>

							</fo:block>
						</fo:table-cell>
					
						<!-- Spalte für die Pagina des Kapitels -->	
						<fo:table-cell column-number="2" display-align="after">
							<fo:block text-align="{$rechtsbündig}">

									<fo:page-number-citation ref-id="{generate-id(.)}"/>

							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:otherwise>
				</xsl:choose>
				
				</xsl:for-each>
			</fo:table-body>
		</fo:table>		
	</fo:block>
</xsl:template>

<!-- *****************************************************
  Template für das Abbildungsverzeichnis
********************************************************* -->
<xsl:template name="Abbildungsverzeichnis">
	<fo:block break-after="page"
			  font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Abbildungsverzeichnis"
			  hyphenate="{$Silbentrennung_nein}">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:text>Abbildungsverzeichnis</xsl:text>
		</fo:marker>
		<fo:block font-family="{$Schriftart_h1}"
				  font-size="{$Schriftgroesse_h1}"
				  line-height="{$Zeilenabstand_h1}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  
				  break-before="page">
			<xsl:text>Abbildungsverzeichnis</xsl:text>
		</fo:block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>
		<!-- Tabelle anlegen -->
			<fo:table>
				<fo:table-column column-number="1" column-width="{$Breite_label_Tab.Abb.Verzeichnis}"></fo:table-column>
				<fo:table-column column-number="2" column-width="{$Breite_caption_Tab.Abb.Verzeichnis}"></fo:table-column>
				<fo:table-column column-number="3" column-width="{$Breite_Pagina_TOC}"></fo:table-column>
				<fo:table-body>
				<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
				<xsl:for-each select="//fig[@fig-type='Abb.Verzeichnis']">
					<fo:table-row>
						<!-- Spalte für das Label der Abbildungsunterschrift -->	
						<fo:table-cell column-number="1">
								<fo:block text-align-last="{$linksbündig}" font-family="{$Schriftart_label_Tab.Abb.Verzeichnis}">
									<xsl:value-of select="label"/>
								</fo:block>
						</fo:table-cell>
						<!-- Spalte für die Abbildungsunterschrift -->	
						<fo:table-cell column-number="2">	
								<fo:block text-align-last="{$Blocksatz}">
									<xsl:value-of select="caption/title"/>
									<xsl:text> </xsl:text>
									<fo:inline>
										<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
									</fo:inline>
								</fo:block>
						</fo:table-cell>
						<!-- Spalte für die Pagina der Abbildungsunterschrift -->	
						<fo:table-cell column-number="3" display-align="after">
								<fo:block text-align="{$rechtsbündig}">
									<fo:page-number-citation ref-id="{generate-id(.)}"/>
								</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:for-each>
				</fo:table-body>
			</fo:table>
	</fo:block>
</xsl:template>

<!-- *****************************************************
  Template für das Tabellenverzeichnis
********************************************************* -->
<xsl:template name="Tabellenverzeichnis">
	<fo:block break-after="page"
			  font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Tabellenverzeichnis"
			  hyphenate="{$Silbentrennung_nein}">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:text>Tabellenverzeichnis</xsl:text>
		</fo:marker>
		<fo:block font-family="{$Schriftart_h1}"
				  font-size="{$Schriftgroesse_h1}"
				  line-height="{$Zeilenabstand_h1}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  
				  break-before="page">
			<xsl:text>Tabellenverzeichnis</xsl:text>
		</fo:block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>
		<!-- Tabelle anlegen -->
			<fo:table>
				<fo:table-column column-number="1" column-width="{$Breite_label_Tab.Abb.Verzeichnis}"></fo:table-column>
				<fo:table-column column-number="2" column-width="{$Breite_caption_Tab.Abb.Verzeichnis}"></fo:table-column>
				<fo:table-column column-number="3" column-width="{$Breite_Pagina_TOC}"></fo:table-column>
				<fo:table-body>
				<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
				<xsl:for-each select="//table-wrap[@content-type='Tab.Verzeichnis']">
					<fo:table-row>
						<!-- Spalte für das Label der Tabellenüberschrift -->	
						<fo:table-cell column-number="1">
							<fo:block text-align-last="{$linksbündig}" font-family="{$Schriftart_label_Tab.Abb.Verzeichnis}">
								<xsl:value-of select="label"/>
							</fo:block>
						</fo:table-cell>
						<!-- Spalte für die Tabellenüberschrift -->
						<fo:table-cell column-number="2">
							<!-- Schleife über alle Knoten fig -->		
							<fo:block text-align-last="{$Blocksatz}">
								<xsl:for-each select="caption/title | caption/title/italic">
									<xsl:value-of select="node()[not(self::fn/p)]"/>  <!-- Fußnoten innerhalb von Tabellenüberschriften weglassen -->
								</xsl:for-each>
								<xsl:text> </xsl:text>
								<fo:inline>
									<fo:leader leader-alignment="reference-area" leader-pattern="{$Muster_Linie_IHV}"/>
								</fo:inline>
							</fo:block>
						</fo:table-cell>
						<!-- Spalte für die Pagina der Tabellenüberschrift -->	
						<fo:table-cell column-number="3" display-align="after">
							<fo:block text-align="{$rechtsbündig}">
								<fo:page-number-citation ref-id="{generate-id(.)}"/>
							</fo:block>
						</fo:table-cell>
					</fo:table-row>
				</xsl:for-each>
					
				</fo:table-body>
			</fo:table>
	</fo:block>
</xsl:template>

<!-- *****************************************************
  Template für das Abkürzungsverzeichnis
********************************************************* -->
<xsl:template name="Abkürzungsverzeichnis">
<fo:block-container font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Abkürzungsverzeichnis">
	 <xsl:for-each select="//glossary[@content-type='Abkuerzungen']">
	 	<fo:block-container break-after="page">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:value-of select="title"/>
		</fo:marker>
		<fo:list-block font-family="{$Schriftart_h1}"
					   font-size="{$Schriftgroesse_h1}"
					   line-height="{$Zeilenabstand_h1}"
					   text-align="{$linksbündig}"
					   hyphenate="{$Silbentrennung_nein}"
					   
					   provisional-label-separation="{$Label_Separation_h1_ohneLabel}"
					   provisional-distance-between-starts="{$Label_Start_h1_ohneLabel}">
					<fo:list-item>
						<fo:list-item-label end-indent="label-end()">
							<fo:block/>
						</fo:list-item-label>
						<fo:list-item-body start-indent="body-start()">
							<fo:block>
								<xsl:value-of select="title"/>
							</fo:block>
						</fo:list-item-body>
					</fo:list-item>
		</fo:list-block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>	
		<!-- Tabelle anlegen -->
		
			<!-- Zwischentitel einfügen anlegen -->
			<xsl:for-each select="def-list">
				<fo:block font-family="{$Fließtext_Bold}"
						  space-before="{$Grundschrift_Zeilenabstand}" 
						  space-after="{$Grundschrift_Zeilenabstand}">
						  <xsl:value-of select="title"/>
				</fo:block>
				<fo:table >
					<fo:table-column column-number="2" column-width="{$Breite_name_Abkürzungsverzeichnis}"></fo:table-column>
					<fo:table-column column-number="1" column-width="{$Breite_kuerzel_Abkürzungsverzeichnis}"></fo:table-column>
					<fo:table-body>
						<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
						<xsl:for-each select="def-item">
						<fo:table-row>
							<!-- Spalte für die Abkürzung/Formelzeichen -->	
							<fo:table-cell column-number="1">	
								<fo:block text-align="left">
									<xsl:apply-templates select="term"/>
									<xsl:apply-templates select="sup"/>
									<xsl:apply-templates select="sub"/>
								</fo:block>
							</fo:table-cell>
							<!-- Spalte für die Bezeichnung der Abkürzung/Formelzeichen -->	
							<fo:table-cell column-number="2">
								<fo:block text-align="{$linksbündig}" hyphenate="{$Silbentrennung_nein}">
									<xsl:apply-templates select="def/p"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						</xsl:for-each>
					</fo:table-body>
				</fo:table>
			</xsl:for-each>
		</fo:block-container>
	</xsl:for-each>
</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Template für das Formelzeichen-Verzeichnis
********************************************************* -->
<xsl:template name="Formelzeichen">
<fo:block-container font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Formelzeichen">
	 <xsl:for-each select="//glossary[@content-type='Formeln']">
	 	<fo:block-container break-after="page">
		<fo:marker marker-class-name="Kapitelueberschrift">
			<xsl:value-of select="title"/>
		</fo:marker>
		<fo:list-block font-family="{$Schriftart_h1}"
					   font-size="{$Schriftgroesse_h1}"
					   line-height="{$Zeilenabstand_h1}"
					   text-align="{$linksbündig}"
					   hyphenate="{$Silbentrennung_nein}"
					   
					   provisional-label-separation="{$Label_Separation_h1_ohneLabel}"
					   provisional-distance-between-starts="{$Label_Start_h1_ohneLabel}">
					<fo:list-item>
						<fo:list-item-label end-indent="label-end()">
							<fo:block/>
						</fo:list-item-label>
						<fo:list-item-body start-indent="body-start()">
							<fo:block>
								<xsl:value-of select="title"/>
							</fo:block>
						</fo:list-item-body>
					</fo:list-item>
		</fo:list-block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>	
		<!-- Tabelle anlegen -->
		
			<!-- Zwischentitel einfügen anlegen -->
			<xsl:for-each select="def-list">
				<fo:block font-family="{$Fließtext_Bold}"
						  space-before="{$Grundschrift_Zeilenabstand}" 
						  space-after="{$Grundschrift_Zeilenabstand}">
						  <xsl:value-of select="title"/>
				</fo:block>
				<fo:table >
					<fo:table-column column-number="2" column-width="{$Breite_name_Abkürzungsverzeichnis}"></fo:table-column>
					<fo:table-column column-number="1" column-width="{$Breite_kuerzel_Abkürzungsverzeichnis}"></fo:table-column>
					<fo:table-body>
						<fo:table-row><fo:table-cell><fo:block/></fo:table-cell></fo:table-row>
						<xsl:for-each select="def-item">
						<fo:table-row>
							<!-- Spalte für die Abkürzung/Formelzeichen -->	
							<fo:table-cell column-number="1">	
								<fo:block text-align="left">
									<xsl:apply-templates select="term"/>
									<xsl:apply-templates select="sup"/>
									<xsl:apply-templates select="sub"/>
								</fo:block>
							</fo:table-cell>
							<!-- Spalte für die Bezeichnung der Abkürzung/Formelzeichen -->	
							<fo:table-cell column-number="2">
								<fo:block text-align="{$linksbündig}" hyphenate="{$Silbentrennung_nein}">
									<xsl:apply-templates select="def/p"/>
								</fo:block>
							</fo:table-cell>
						</fo:table-row>
						</xsl:for-each>
					</fo:table-body>
				</fo:table>
			</xsl:for-each>
		</fo:block-container>
	</xsl:for-each>
</fo:block-container>
</xsl:template>

<!-- *****************************************************
  Template für das Literaturverzeichnis
********************************************************* -->
<xsl:template name="Literaturverzeichnis">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Literaturverzeichnis">
		<fo:marker marker-class-name="Kapitelueberschrift_1.Grades">
			<xsl:text>Literaturverzeichnis</xsl:text>
		</fo:marker>
		<fo:marker marker-class-name="Kapitelueberschrift_2.Grades">
			<xsl:text>Literaturverzeichnis</xsl:text>
		</fo:marker>
		<fo:block font-family="{$Schriftart_h1}"
				  font-size="{$Schriftgroesse_h1}"
				  line-height="{$Zeilenabstand_h1}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}"
				  break-before="page">
			<xsl:text>Literaturverzeichnis</xsl:text>
		</fo:block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>	
		<!-- Option Literaturverzeichnis mit oder ohne Zwischenüberschriften -->
		<xsl:choose>
			<!-- Optionen  mit Zwischenüberschriften -->
			<xsl:when test="book-back/ref-list/ref-list">
				<xsl:for-each select="book-back/ref-list/ref-list">
					<!-- Einträge Zwischenüberschriften -->	
					<fo:block font-family="{$Schriftart_h1_Literaturverzeichnis}"
					          font-size="{$Schriftgroesse_h1_Literaturverzeichnis}"
					          line-height="{$Zeilenabstand_h1_Literaturverzeichnis}"
					          space-after="{$Abstand_danach_h1_Literaturverzeichnis}"
					          space-before="{$Abstand_davor_h1_Literaturverzeichnis}">
					          <xsl:value-of select="title"/>
					</fo:block>
					<!-- Einträge Literaturverzeichnis -->			
					<xsl:for-each select="ref">
						<fo:block font-size="{$Schriftgroesse_Literaturverzeichnis}"
					              line-height="{$Zeilenabstand_Literaturverzeichnis}"
					              space-after="{$Abstand_danach_Literaturverzeichnis}"
					              start-indent="{$Einzug_start_Literaturverzeichnis}" 
								  text-indent="{$Einzug_text_Literaturverzeichnis}">
								  <xsl:value-of select="label"/>
					              <xsl:text> </xsl:text>
								  <xsl:value-of select="mixed-citation"/>
						</fo:block>
					</xsl:for-each>
				</xsl:for-each>
			</xsl:when>
			<!-- Optionen ohne Zwischenüberschriften -->
			<xsl:otherwise>
				<xsl:for-each select="//ref-list/ref">
					<fo:block font-size="{$Schriftgroesse_Literaturverzeichnis}"
					          line-height="{$Zeilenabstand_Literaturverzeichnis}"
					          space-after="{$Abstand_danach_Literaturverzeichnis}"
					          start-indent="{$Einzug_start_Literaturverzeichnis}"
							  text-indent="{$Einzug_text_Literaturverzeichnis}">
					          <xsl:apply-templates select="label"/>
					          <xsl:text> </xsl:text>
					          <xsl:apply-templates select="mixed-citation"/>
					</fo:block>
				</xsl:for-each>
			</xsl:otherwise>
		</xsl:choose>
	</fo:block>
</xsl:template>

<!-- *****************************************************
  Template für das Sachregister
********************************************************* -->
<xsl:template name="Index">
	<fo:block font-family="{$Grundschriftart}"
			  font-size="{$Schriftgroesse_IHV}"
			  id="Index">
		<fo:marker marker-class-name="Kapitelueberschrift_1.Grades">
			<xsl:text>Index</xsl:text>
		</fo:marker>
		<fo:marker marker-class-name="Kapitelueberschrift_2.Grades">
			<xsl:text>Index</xsl:text>
		</fo:marker>
		<fo:block font-family="{$Schriftart_h1}"
				  font-size="{$Schriftgroesse_h1}"
				  line-height="{$Zeilenabstand_h1}"
				  text-align="{$linksbündig}"
				  hyphenate="{$Silbentrennung_nein}">
			<xsl:text>Index</xsl:text>
		</fo:block>
		<!-- Linie unterhalb der Überschrift -->
		<fo:block space-after="{$Abstand_danach_h1}">
			<fo:leader leader-pattern="{$Muster_Fussnotenlinie}" leader-length="{$Linienlaenge_h1}"
					   rule-style="{$Style_Fussnotenlinie}" rule-thickness="{$Liniendicke_h1}"/>
		</fo:block>
		<xsl:for-each select="//index-term">
			<xsl:sort select="term" lang="de"/>
			<fo:block>
				<fo:inline>
					<xsl:value-of select="."/>
					<xsl:text>&#160;&#160;&#160;</xsl:text>
					<fo:page-number-citation ref-id="{generate-id(.)}"/>
				</fo:inline>
			</fo:block>
		</xsl:for-each>
	</fo:block>
</xsl:template>

</xsl:stylesheet>
