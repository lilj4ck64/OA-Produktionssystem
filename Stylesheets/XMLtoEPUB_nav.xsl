<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Transformationsstylesheet für Navigationsdateien des EPUB-Formats
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0" 
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns="http://www.w3.org/1999/xhtml">

<xsl:output method="xhtml"
			encoding="utf-8"/>

<!-- <xsl:template match="book">
	<xsl:call-template name="navhtml"/> 
</xsl:template> -->

<xsl:template name="navhtml">
	<xsl:result-document method="xhtml" href="{$EPUB_navhtml}">
		<xsl:text disable-output-escaping="yes">&lt;!DOCTYPE html&gt;</xsl:text>
		<html	xmlns:epub="http://www.idpf.org/2007/ops" 
				epub:prefix="z3998: http://www.daisy.org/z3998/2012/vocab/structure/#" 
				xml:lang="de"
				xmlns:xlink="http://www.w3.org/1999/xlink"
				xmlns:mml="http://www.w3.org/1998/Math/MathML">
			<head>
				<link rel="stylesheet" type="text/css" href="Styles/HTWK-OAVerlag.css"/>
				<title>Inhaltsverzeichnis</title>
			</head>
			<body>
				<nav epub:type="toc" id="toc">
					<h1>Inhaltsverzeichnis</h1>
					<ol>
						<li><a href="Content/Cover.xhtml">Cover</a></li>
						<li><a href="Content/Schmutztitel.xhtml">Schmutztitel</a></li>
						<li><a href="Content/Haupttitel.xhtml">Haupttitel</a></li>
						<li><a href="Content/Impressum.xhtml">Impressum</a></li>
						<li><a href="Content/Zusammenfassung.xhtml">Zusammenfassung</a></li>
						<li><a href="Content/Inhaltsverzeichnis.xhtml">Inhaltsverzeichnis</a></li>
						<li><a href="Content/Abbildungsverzeichnis.xhtml">Abbildungsverzeichnis</a></li>
						<li><a href="Content/Tabellenverzeichnis.xhtml">Tabellenverzeichnis</a></li>
						
						<!-- Optional falls vorhanden: Formelzeichen-Verzeichnis -->
						<xsl:if test="//glossary/title='Formelzeichen'">
							<li><a href="Content/Formelzeichen.xhtml">Formelzeichen</a></li>
						</xsl:if>
						
						<!-- Optional falls vorhanden: Abkürzungsverzeichnis -->
						<xsl:if test="//glossary/title='Abkürzungsverzeichnis'">
							<li><a href="Content/Abkuerzungsverzeichnis.xhtml">Abkuerzungsverzeichnis</a></li>
						</xsl:if>
						
						<!-- Kapitel erster Ordnung anlegen -->
						<xsl:for-each select="//book-part[@book-part-type = 'chapter']">
							<li>
								<a href="Content/{$Kapitel}_{book-part-meta/title-group/label}{$Contentausgabeformat}">
									<xsl:if test="book-part-meta/title-group/label">
										<xsl:value-of select="book-part-meta/title-group/label"/>
										<xsl:text> </xsl:text>
									</xsl:if>
									<xsl:value-of select="book-part-meta/title-group/title"/></a>
								
								<!-- Kapitel zweiter Ordnung anlegen -->
								<xsl:if test="body/sec">
									<ol>
										<xsl:for-each select="body/sec">
											<li><a href="Content/{$Kapitel}_{../../book-part-meta/title-group/label}{$Contentausgabeformat}#{@id}">
												<xsl:value-of select="label"/>
												<xsl:text> </xsl:text>	
												<xsl:value-of select="title"/>
											</a>
												
											<!-- Kapitel dritter Ordnung anlegen -->
											<xsl:if test="sec">
												<ol>
													<xsl:for-each select="sec">
														<li><a href="Content/{$Kapitel}_{../../../book-part-meta/title-group/label}{$Contentausgabeformat}#{@id}">
															<xsl:value-of select="label"/>
															<xsl:text> </xsl:text>	
															<xsl:value-of select="title"/>
															</a>
															
															<!-- Kapitel vierter Ordnung anlegen -->
															<xsl:if test="sec">
																<ol>
																	<xsl:for-each select="sec">
																		<li><a href="Content/{$Kapitel}_{../../../../book-part-meta/title-group/label}{$Contentausgabeformat}#{@id}">
																			<xsl:value-of select="label"/>
																			<xsl:text> </xsl:text>	
																			<xsl:value-of select="title"/>
																		</a>
																		</li>
																	</xsl:for-each>
																</ol>
															</xsl:if>
														</li>
													</xsl:for-each>
												</ol>
											</xsl:if>
											</li>
									</xsl:for-each>
									</ol>
								</xsl:if>
							</li>
						</xsl:for-each>
						
						<li><a href="Content/Literaturverzeichnis.xhtml">Literaturverzeichnis</a></li>
						
						<!-- Optional falls vorhanden: Index -->
						<xsl:if test="//index-term">
							<li><a href="Content/Index.xhtml">Index</a></li>
						</xsl:if>
						
						<!-- Anhang erster Ordnung anlegen -->
						<xsl:for-each select="//book-back/book-app-group/book-app">
							<li>
								<a href="Content/{$Anhang}_{@id}{$Contentausgabeformat}">
									<xsl:if test="book-part-meta/title-group/label">
										<xsl:value-of select="book-part-meta/title-group/label"/>
										<xsl:text> </xsl:text>
									</xsl:if>
									<xsl:value-of select="book-part-meta/title-group/title"/></a>
								
								<!-- Anhang zweiter Ordnung anlegen -->
								<xsl:if test="body/sec/sec">
									<ol>
										<xsl:for-each select="body/sec/sec">
											<li><a href="Content/{$Anhang}_{../../../@id}{$Contentausgabeformat}#{@id}">
												<xsl:value-of select="label"/>
												<xsl:text> </xsl:text>	
												<xsl:value-of select="title"/></a>
											</li>
										</xsl:for-each>
									</ol>
								</xsl:if>
							</li>
						</xsl:for-each>
					</ol> 
				</nav>
				
				<section epub:type="landmarks" hidden="hidden">
					<h1>Guide</h1>
					<nav epub:type="landmarks">
						<ol>
							<li><a href="Content/Cover.xhtml" epub:type="cover">Cover</a></li>
							<li><a href="Content/Inhaltsverzeichnis.xhtml" epub:type="toc">Inhaltsverzeichnis</a></li>
							<li><a href="Content/Kapitel_1.xhtml" epub:type="bodymatter">Inhalt</a></li>
						</ol>
					</nav>
				</section>
			</body>
		</html>
		
		
	</xsl:result-document>
</xsl:template>	

</xsl:stylesheet>	