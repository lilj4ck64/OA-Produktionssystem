<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Transformationsstylesheet für Inhaltsdateien des EPUB-Formats
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0" 	
				xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
				xmlns="http://www.w3.org/1999/xhtml"
				xmlns:oa="urn:oa-satzsystem"
				exclude-result-prefixes="oa">

<xsl:output method="xhtml"
			encoding="utf-8"/>
			
<xsl:include href="XMLtoHTML_Bibliothek.xsl"/>

<!--  Separation der HTML-Outputdateien für EPUB -->
<xsl:template name="content">    
        
	<!--  Cover separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Cover{$Contentausgabeformat}">	
			<!--  Cover separieren -->
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
				<head>
					<link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"></link>
                    <title>Cover</title>
                </head>
                <body>
                    <div>
                        <img class="cover" xmlns:xlink="http://www.w3.org/1999/xlink" 
						src="../Images/cover.jpg" alt="Alternativtext"></img>
                    </div>
                </body>
            </html>
        </xsl:result-document>
        
	<!--  Schmutztitel separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Schmutztitel{$Contentausgabeformat}">          
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                <head>
                    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                    <title>Schmutztitel</title>
                </head>
                <body epub:type="frontmatter">
                    <div class="halftitlepage">
                        
                        <!-- Autorennamen ausgeben -->
                        <xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']">
                            <p epub:type="author">
                                <xsl:value-of select="name/given-names"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="name/surname"/>
                            </p> 
                        </xsl:for-each>
                        
                        <!-- Haupttitel ausgeben -->
                        <h1 epub:type="halftitle">
                            <span epub:type="title">
                                <xsl:value-of select="//book/book-meta/book-title-group/book-title"/>
                            </span>
							<!-- Untertitel ausgeben (Optional) -->
							<xsl:if test="//book/book-meta/book-title-group/subtitle">
                                <span epub:type="subtitle">
                                    <xsl:value-of select="//book/book-meta/book-title-group/subtitle"/>
                                </span>
							</xsl:if>
                        </h1>
                    </div>
                </body>
            </html>
        </xsl:result-document>
        
	<!--  Haupttitel separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Haupttitel{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                <head>
                    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                    <title>Haupttitel</title>
                </head>
                <body epub:type="frontmatter">
                    <div class="titlepage">
                        
                        <!-- Autorennamen ausgeben -->
                        <xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']">
                            <p epub:type="author">
                                <xsl:value-of select="name/given-names"/>
                                <xsl:text> </xsl:text>
                                <xsl:value-of select="name/surname"/>
                            </p> 
                        </xsl:for-each>
                        
                        <!-- Haupttitel ausgeben -->
                        <h1 epub:type="fulltitle">
                            <span epub:type="title">
                                <xsl:value-of select="//book/book-meta/book-title-group/book-title"/>
                            </span>
							<!-- Untertitel ausgeben (Optional) -->
							<xsl:if test="//book/book-meta/book-title-group/subtitle">
								<span epub:type="subtitle">
									<xsl:value-of select="//book/book-meta/book-title-group/subtitle"/>
								</span>
							</xsl:if>
                        </h1>

                        <!-- Verlagslogo ausgeben -->
                        <img class="logo" src="../Images/HTWK_Logo.jpg"
                            alt="HTWK: Hochschule für Technik, Wirtschaft und Kultur"/>
                    </div>
                </body>
            </html>
        </xsl:result-document>
        
	<!--  Impressum separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Impressum{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
				<head>
				    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
					<title>Impressum</title>
				</head>
				<body epub:type="frontmatter">
					<div class="biographical-note">
						<h1>Über den Autor</h1>
					    <xsl:for-each select="book-meta/contrib-group/contrib[@contrib-type='content-supplier']/bio[@content-type='about-the-author']">
					        <xsl:apply-templates select="p"/>
					        <xsl:apply-templates select="semibold"/>
					        <xsl:apply-templates select="italic"/>
					    </xsl:for-each>
					</div>
					<div class="imprint">
						<h1>Bibliografische Information der Deutschen Nationalbibliothek</h1>
						<p>Die Deutsche Nationalbibliothek verzeichnet diese Publikation in der Deutschen
							Nationalbibliografie. Detaillierte bibliografische Daten sind im Internet unter <a
								href="http://dnb.de">http://dnb.de</a> abrufbar.</p>
						<img src="../Images/CC_Hinweis.jpg" alt="Creative-Commons-Lizenz CC BY 4.0 International" />
						<p>Der Text dieses Werks ist unter der Creative-Commons-Lizenz CC BY 4.0 International
							veröffentlicht. Den Vertragstext der Lizenz finden Sie unter <br /><a
								href="https://creativecommons.org/licenses/by/4.0/deed.de"
								>https://creativecommons.org/licenses/by/4.0/deed.de</a>. Die Abbildungen sind
							von dieser Lizenz ausgenommen, hier liegt das Urheberrecht beim jeweiligen
							Rechteinhaber.</p>
						<img src="../Images/qr-doi.jpg" alt="QR-Code der Publikation" />
						<p>Die Online-Version dieser Publikation ist abrufbar unter <br />
						<a href="{concat('https://doi.org/', $DOI)}">
						    <xsl:text>https://doi.org/</xsl:text>
							<xsl:value-of select="$DOI"/>
						</a></p>
					    <p><xsl:value-of select="//book/book-meta/permissions/copyright-statement"/></p>
						<p>Druck &amp; Bindung in Deutschland und den Niederlanden</p>
						<p epub:type="isbn">
							<xsl:text>ISBN (Hardcover) </xsl:text>
							<xsl:value-of select="//book/book-meta/isbn[@content-type='hardcover']"/>
						</p>
						<p epub:type="isbn">
							<xsl:text>ISBN (Softcover) </xsl:text>
							<xsl:value-of select="//book/book-meta/isbn[@content-type='softcover']"/>
						</p>
						<p epub:type="isbn">
							<xsl:text>ISBN (ePub) </xsl:text>
							<xsl:value-of select="//book/book-meta/isbn[@content-type='epub']"/>
						</p>
						<p epub:type="isbn">
							<xsl:text>ISBN (PDF) </xsl:text>
							<xsl:value-of select="//book/book-meta/isbn[@content-type='pdf']"/>
						</p>
					</div>
					<div class="publisher-address">
						<h1>Herausgeber</h1>
						<p><xsl:value-of select="//book/book-meta/publisher/publisher-name"/></p>
						<p><xsl:value-of select="//book/book-meta/publisher/publisher-loc/institution"/></p>
						<p><xsl:value-of select="//book/book-meta/publisher/publisher-loc/addr-line"/></p>
						<p><xsl:value-of select="//book/book-meta/publisher/publisher-loc/postal-code"/>
						   <xsl:text> </xsl:text>
						   <xsl:value-of select="//book/book-meta/publisher/publisher-loc/city"/></p>
					</div>
				</body>
			</html>
        </xsl:result-document>
        
	<!--  Zusammenfassung separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Zusammenfassung{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
				<head>
				    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
					<title>Zusammenfassung/Abstract</title>
				</head>
				<body epub:type="frontmatter">
					<div class="abstract">
						<h1>Kurzfassung</h1>
					    <xsl:for-each select="//book/book-meta/abstract[@xml:lang='de']/p">
					        <p><xsl:value-of select="."/></p>
					    </xsl:for-each>
					</div>
					<div class="abstract" xml:lang="en">
						<h1>Abstract</h1>
					    <xsl:for-each select="//book/book-meta/trans-abstract[@xml:lang='en']/p">
					        <p><xsl:value-of select="."/></p>
					    </xsl:for-each>
					</div>
				</body>
			</html>
        </xsl:result-document>
    
    <!--  Ack (Danksagung/Vorwort) separieren -->
    <xsl:if test="//ack">
            <xsl:result-document href="{$EPUB_Content_Pfad}/Ack{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                    <head>
                        <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
						<title>Acknowledgement</title>
                    </head>
					<body epub:type="frontmatter">
						<xsl:for-each select="//ack">
							<div class="ack">
								<h1><xsl:value-of select="title"/></h1>
								<xsl:apply-templates/>
							</div>
						</xsl:for-each>
						<xsl:for-each select="//dedication">
							<div class="dedication">
								<xsl:apply-templates/>
							</div>
						</xsl:for-each>
					</body>
                </html>
            </xsl:result-document>
    </xsl:if>
        
	<!--  Inhaltsverzeichnis separieren -->
        <xsl:result-document href="{$EPUB_Content_Pfad}/Inhaltsverzeichnis{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                <head>
                    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                    <title>Inhaltsverzeichnis</title>
                </head>
                <body epub:type="frontmatter">
                    <nav epub:type="toc">
                    <h1>Inhaltsverzeichnis</h1>   
                        <ol>
                            <li><a href="Abbildungsverzeichnis{$Contentausgabeformat}">Abbildungsverzeichnis</a></li>
                            <li><a href="Tabellenverzeichnis{$Contentausgabeformat}">Tabellenverzeichnis</a></li>     
							
							<xsl:if test="//glossary[@content-type='Abkuerzungen']">
								<li><a href="Abkuerzungsverzeichnis{$Contentausgabeformat}">Abkürzungsverzeichnis</a></li>
							</xsl:if>
							
							<xsl:if test="//glossary[@content-type='Formeln']">
								<li><a href="Formelzeichen{$Contentausgabeformat}">Formelzeichen</a></li>
							</xsl:if>
							
                            
                            <!-- Kapitel erster Ordnung ausgeben-->
                            <xsl:for-each select="//book-part[@book-part-type = 'chapter']">
                                <li class="toc-h1">
									<label epub:type="ordinal">
										<a href="{$Kapitel}_{oa:safe-name(book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
											<xsl:value-of select="book-part-meta/title-group/label"/>
										</a>
									</label>
									<a href="{$Kapitel}_{oa:safe-name(book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
                                        <xsl:value-of select="book-part-meta/title-group/title"/>   
                                    </a>
                                    
                                    <!-- Kapitel zweiter Ordnung ausgeben-->
                                    <xsl:if test="body/sec">
                                       <xsl:for-each select="body/sec"> 
											<ol>
											<li class="toc-h2">
												<label epub:type="ordinal">
													<a href="{$Kapitel}_{oa:safe-name(../../book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
														<xsl:value-of select="label"/>
													</a>
												</label>
												<a href="{$Kapitel}_{oa:safe-name(../../book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
													<xsl:value-of select="title"/>   
												</a>
												
												<!-- Kapitel dritter Ordnung ausgeben-->
												<xsl:if test="sec">
													<xsl:for-each select="sec"> 
														<ol>
														<li class="toc-h3">
															<label epub:type="ordinal">
																<a href="{$Kapitel}_{oa:safe-name(../../../book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
																	<xsl:value-of select="label"/>
																</a>
															</label>
															<a href="{$Kapitel}_{oa:safe-name(../../../book-part-meta/title-group/label)}{$Contentausgabeformat}#{@id}">
																<xsl:value-of select="title"/>   
															</a>
														</li>
														</ol>
													</xsl:for-each>
												</xsl:if>
											</li>
											</ol>
										</xsl:for-each>
                                    </xsl:if>
                                </li>
                            </xsl:for-each>
                            
                            <li class="margin"><a href="Literaturverzeichnis{$Contentausgabeformat}">Literaturverzeichnis</a></li>
							
							<xsl:if test="//index-term">
								<li><a href="Index{$Contentausgabeformat}">Index</a></li>
                            </xsl:if>
							
                            <!-- Anhang erster Ordnung ausgeben-->
                            <xsl:for-each select="//book-back/book-app-group/book-app">
                                <li class="toc-h1">
									<label>
										<a href="{$Anhang}_{oa:safe-name(@id)}{$Contentausgabeformat}">
											<xsl:value-of select="book-part-meta/title-group/label"/>
										</a>
									</label>
									<a href="{$Anhang}_{oa:safe-name(@id)}{$Contentausgabeformat}">
                                        <xsl:value-of select="book-part-meta/title-group/title"/>
                                    </a>
                                </li>
                            </xsl:for-each>
                        </ol>
                    </nav>
                </body>
            </html>
        </xsl:result-document>
        
	<!--  Abbildungsverzeichnis separieren -->
    <xsl:result-document href="{$EPUB_Content_Pfad}/Abbildungsverzeichnis{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
            <head>
                <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                <title>Abbildungsverzeichnis</title>
            </head>
            <body epub:type="frontmatter">
                <div class="loi">
                    <h1>Abbildungsverzeichnis</h1>
                    <table>
                        <xsl:for-each select="//fig[@fig-type='Abb.Verzeichnis']">
                        <tr>
                            <td class="Label_Abb.Verz">
                                <xsl:variable name="Label_Aufruf">
                                    <xsl:value-of select="ancestor::book-part[@book-part-type='chapter']/book-part-meta/title-group/label"/>
                                </xsl:variable>
                                <a href="{$Kapitel}_{oa:safe-name($Label_Aufruf)}{$Contentausgabeformat}#{@id}">
                                    <xsl:value-of select="label"/>
                                </a>
                            </td>
                            <td>
                                <xsl:value-of select="caption/title"/> 
                            </td>
                        </tr>
                    </xsl:for-each>
                    </table>
                </div>
            </body>
        </html>
    </xsl:result-document>
        
	<!--  Tabellenverzeichnis separieren -->
    <xsl:result-document href="{$EPUB_Content_Pfad}/Tabellenverzeichnis{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
            <head>
                <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                <title>Tabellenverzeichnis</title>
            </head>
            <body epub:type="frontmatter">
                <div class="loi">
                    <h1>Tabellenverzeichnis</h1>
                    <table>
                        <xsl:for-each select="//table-wrap[@content-type='Tab.Verzeichnis']">
                            <tr>
                                <td>
                                    <xsl:variable name="Label_Aufruf">
                                        <xsl:value-of select="ancestor::book-part[@book-part-type='chapter']/book-part-meta/title-group/label"/>
                                    </xsl:variable>
                                    <a href="{$Kapitel}_{oa:safe-name($Label_Aufruf)}{$Contentausgabeformat}#{@id}">
                                        <xsl:value-of select="label"/>
                                    </a>
                                </td>
                                <td>
                                    <xsl:value-of select="caption/title"/> 
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table>
                </div>
            </body>
        </html>
    </xsl:result-document>
        
	<!--  Abkürzungsverzeichnis separieren (Optional) -->
    <xsl:if test="//glossary[@content-type='Abkuerzungen']">
	<xsl:for-each select="//glossary[@content-type='Abkuerzungen']">
    <xsl:result-document href="{$EPUB_Content_Pfad}/Abkuerzungsverzeichnis{$Contentausgabeformat}">
			<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
					xmlns:epub="http://www.idpf.org/2007/ops"
					xmlns:xlink="http://www.w3.org/1999/xlink"
					xmlns:mml="http://www.w3.org/1998/Math/MathML">
            <head>
                <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                <title>Abkürzungsverzeichnis</title>
            </head>
            <body epub:type="frontmatter">
                <div class="loi">
                    <h1>Abkürzungsverzeichnis</h1>
                    <table>
                        <xsl:for-each select="def-list/def-item">
                            <tr>
                                <td epub:type="glossterm">
                                    <xsl:value-of select="term"/>
                                </td>
                                <td epub:type="glossdef">
                                    <xsl:value-of select="def/p"/> 
                                </td>
                            </tr>
                        </xsl:for-each>
                    </table>
                    
                </div>
            </body>
        </html>
    </xsl:result-document>
	</xsl:for-each>
    </xsl:if>
	
	<!--  Formelzeichen-Verzeichnis separieren (Optional) -->
    <xsl:if test="//glossary[@content-type='Formeln']">
	<xsl:for-each select="//glossary[@content-type='Formeln']">
    <xsl:result-document href="{$EPUB_Content_Pfad}/Formelzeichen{$Contentausgabeformat}">
			<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
					xmlns:epub="http://www.idpf.org/2007/ops"
					xmlns:xlink="http://www.w3.org/1999/xlink"
					xmlns:mml="http://www.w3.org/1998/Math/MathML">
            <head>
                <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                <title>Formelzeichen</title>
            </head>
            <body epub:type="frontmatter">
                <div class="loi">
                    <h1>Formelzeichen</h1>
                    <xsl:for-each select="def-list">
                        <h2><xsl:value-of select="title"/></h2>
						<table>
							<xsl:for-each select="def-item">
								<tr>
									<td epub:type="glossterm">
										<xsl:value-of select="term"/>
									</td>
									<td epub:type="glossdef">
										<xsl:value-of select="def/p"/> 
									</td>
								</tr>
							</xsl:for-each>
						</table>
                    </xsl:for-each>
                </div>
            </body>
        </html>
    </xsl:result-document>
	</xsl:for-each>
    </xsl:if>
        
	<!--  Literaturverzeichnis separieren -->
        <xsl:for-each select="//book-back/ref-list">
			<xsl:result-document href="{$EPUB_Content_Pfad}/{$Literaturverzeichnis}{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                    <head>
                        <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                        <title>Literaturverzeichnis</title>
                    </head>
                    <body>
                        <div class="bibliography" id="{@id}">
                            <h1><xsl:value-of select="title"/> </h1>
							
							<xsl:for-each select="ref-list">
								<h2><xsl:value-of select="title"/></h2> 
								<ol>
									<li>
									<ol>
										<xsl:for-each select="ref">
											<li id="{@id}"><xsl:apply-templates/></li>
										</xsl:for-each>
									</ol>
									</li>
								</ol>
							</xsl:for-each>
                        </div>
                    </body> 
				</html>
            </xsl:result-document>
        </xsl:for-each>
        
	<!--  Kapitel erster Ordnung separieren-->
        <xsl:for-each select="//book-part[@book-part-type = 'chapter']">
			<xsl:result-document href="{$EPUB_Content_Pfad}/{$Kapitel}_{oa:safe-name(book-part-meta/title-group/label)}{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
					<head>
					    <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
						<title>
							<xsl:value-of select="book-part-meta/title-group/title"/>
						</title>
					</head>
					<body>
						<div class="chapter" id="{@id}">
							<h1>
								<xsl:if test="book-part-meta/title-group/label">
									<xsl:value-of select="book-part-meta/title-group/label"/>
									<xsl:text> </xsl:text>
								</xsl:if>
								<xsl:value-of select="book-part-meta/title-group/title"/>	
							</h1>
							<xsl:apply-templates/>
						</div>
					</body> 
				</html>
            </xsl:result-document>
        </xsl:for-each>
        
	<!--  Anhänge separieren-->
        <xsl:for-each select="//book-back/book-app-group/book-app">
			<xsl:result-document href="{$EPUB_Content_Pfad}/{$Anhang}_{oa:safe-name(@id)}{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
                    <head>
                        <link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
                        <title>
							<xsl:value-of select="book-part-meta/title-group/title"/>
						</title>
                    </head>
                    <body>
                        <div class="appendix" id="{@id}">
                            <h1>
                                <xsl:if test="book-part-meta/title-group/label">
                                    <xsl:value-of select="book-part-meta/title-group/label"/>
                                    <xsl:text> </xsl:text>
                                </xsl:if>
                                <xsl:value-of select="book-part-meta/title-group/title"/>	
                            </h1>
                            <xsl:apply-templates/>
                        </div>
                    </body> 
				</html>
            </xsl:result-document>
        </xsl:for-each>
		
		<!--  Index separieren (Optional) -->
		<xsl:if test="//index-term">
		<xsl:result-document href="{$EPUB_Content_Pfad}/Index{$Contentausgabeformat}">
				<html 	xmlns="http://www.w3.org/1999/xhtml" xml:lang="en"
						xmlns:epub="http://www.idpf.org/2007/ops"
						xmlns:xlink="http://www.w3.org/1999/xlink"
						xmlns:mml="http://www.w3.org/1998/Math/MathML">
				<head>
					<link rel="stylesheet" type="text/css" href="../Styles/{$CSS-Stylesheet}"/>
					<title>Index</title>
				</head>
				<body epub:type="frontmatter">
					<div class="loi">
						<h1>Index</h1>
						<table>
							<xsl:for-each select="//index-term">
								<tr>
									<td epub:type="t">
										<xsl:value-of select="term"/>
									</td>
									<td epub:type="glossdef">
										<xsl:text>Hier steht die Seitenzahl.</xsl:text>
									</td>
								</tr>
							</xsl:for-each>
						</table>
						
					</div>
				</body>
			</html>
		</xsl:result-document>
		</xsl:if>
		
</xsl:template> 

</xsl:stylesheet>
