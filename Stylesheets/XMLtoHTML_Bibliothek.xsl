<?xml version="1.0" encoding="UTF-8"?>

<!-- 
Element-Bibliothek für Erstellung der XHTML-Dateien
Erstellungsdatum: 1. August 2021 / Version: BETA 1.0
Copyright (C) 2021 HTWK Leipzig, Projekt OA-STRUKTKOMM

Dieses Programm ist freie Software. Sie können es unter den Bedingungen der GNU General Public License, wie von der Free Software Foundation veröffentlicht, weitergeben und/oder modifizieren, entweder gemäß Version 3 der Lizenz oder (nach Ihrer Option) jeder späteren Version.

Die Veröffentlichung dieses Programms erfolgt in der Hoffnung, daß es Ihnen von Nutzen sein wird, aber OHNE IRGENDEINE GARANTIE, sogar ohne die implizite Garantie der MARKTREIFE oder der VERWENDBARKEIT FÜR EINEN BESTIMMTEN ZWECK. Details finden Sie in der GNU General Public License.

Sie sollten ein Exemplar der GNU General Public License zusammen mit diesem Programm erhalten haben. Falls nicht, siehe <http://www.gnu.org/licenses/>. 
-->

<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
							  xmlns:xlink="http://www.w3.org/1999/xlink"
							  xmlns:mml="http://www.w3.org/1998/Math/MathML"
							  xmlns:epub="http://www.idpf.org/2007/ops"
							  xmlns="http://www.w3.org/1999/xhtml"
							  xmlns:oa="urn:oa-satzsystem"
							  exclude-result-prefixes="oa">
	
<!-- Templates für die Inhaltsgliederung -->
	
<!-- Template für den knoten book-back -->
<xsl:template match="book-back">
	<div id="book-back">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<!-- Template für den knoten book-body -->
<xsl:template match="book-body">
	<xsl:apply-templates/>
</xsl:template>

<!-- Template für den Knoten book-part -->
<xsl:template match="book-part">
	<!-- Nichts tun, da über Schleife über book-part gegangen wird -->
</xsl:template>

<!-- Template für den Knoten book-part-meta -->
<xsl:template match="book-part-meta">
	<xsl:apply-templates/>
</xsl:template>	
	
<!-- Template für den Knoten book-part-id (DOI) -->
<xsl:template match="book-part-id">
	<!-- DOI des Kapitels ausgeben -->
	<p class="DOI">
		<xsl:variable name="Link_DOI">
			<xsl:text>http://doi.org/</xsl:text>
			<xsl:value-of select="."/>
		</xsl:variable>
			
		<xsl:text>DOI Kapitel:</xsl:text>
		<xsl:text>&#160;&#160;</xsl:text>
		<a href="{$Link_DOI}">
			<xsl:text>http://doi.org/</xsl:text>
			<xsl:apply-templates/>
		</a>
	</p>
</xsl:template>
	
<!-- Template für den Knoten dedication -->
<xsl:template match="dedication">
	<xsl:apply-templates/>
</xsl:template>
	
<!-- Template für den Knoten named-book-part-body -->
<xsl:template match="named-book-part-body">
	<xsl:apply-templates/>
</xsl:template>
	
<!-- Template für den Knoten dedication -->
<xsl:template match="title-group">
	<!-- nichts tun -->
</xsl:template>	
	
<!-- Template für den Knoten body -->
<xsl:template match="body">
	<xsl:apply-templates/>
</xsl:template>
	
<!-- Template für den Knoten sec -->
<xsl:template match="sec">
	<div class="chapter" id="{@id}">
		
		<!-- Variable mit der Knotenebene anlegen -->
		<xsl:variable name="Knotenebene">
			<xsl:value-of select="count(ancestor::sec)"/>
		</xsl:variable>
			
		<xsl:call-template name="debug">
			<xsl:with-param name="debug-template">sec</xsl:with-param>
			<xsl:with-param name="debug-level">3</xsl:with-param>
			<xsl:with-param name="debug-text">[Knotenebene: [<xsl:value-of select="$Knotenebene"/>]]</xsl:with-param>
		</xsl:call-template>
			
			
		<xsl:choose>
			<!-- 2. Ebene -->
			<xsl:when test="$Knotenebene='0'">
				<h2>
					<xsl:value-of select="label"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="title"/>
				</h2>
			</xsl:when>
			<xsl:when test="$Knotenebene='1'">
				<h3>
					<xsl:value-of select="label"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="title"/>
				</h3>
			</xsl:when>
			<xsl:when test="$Knotenebene='2'">
				<h4>
					<xsl:value-of select="label"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="title"/>
				</h4>
			</xsl:when>
			<xsl:when test="$Knotenebene='3'">
				<h5>
					<xsl:value-of select="label"/>
					<xsl:text> </xsl:text>
					<xsl:value-of select="title"/>
				</h5>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="debug">
					<xsl:with-param name="debug-template">sec</xsl:with-param>
					<xsl:with-param name="debug-level">2</xsl:with-param>
					<xsl:with-param name="debug-text">[Knotenebene: [<xsl:value-of select="$Knotenebene"/>]]</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:apply-templates/>	
	</div>
</xsl:template>
	
<!-- Template für Absätze -->
<xsl:template match="p">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="name(parent::node())!='disp-quote'">
			<p class="normal">
				<xsl:apply-templates/>	
			</p>
			<!-- Fußnoten nach jedem Absatz einfügen-->
			<xsl:if test="fn">
				<div class="endnoten">
					<xsl:for-each select="fn">
						<aside epub:type="footnote" id="{@id}">
							<xsl:value-of select="@symbol"/>
							<xsl:text>&#160;&#160;</xsl:text>
							<xsl:for-each select="p">
								<xsl:apply-templates/>
							</xsl:for-each>
						</aside>
					</xsl:for-each>
				</div>
			</xsl:if>
		</xsl:when>	
		<xsl:otherwise>
			<xsl:apply-templates/>
			<xsl:for-each select="fn">	
				<!-- Fußnoten nach jedem Absatz einfügen-->
				<xsl:if test="fn">
					<div class="endnoten">
						<xsl:for-each select="fn">
							<aside epub:type="footnote" id="{@id}">
								<xsl:value-of select="@symbol"/>
								<xsl:text>&#160;&#160;</xsl:text>
								<xsl:for-each select="p">
									<xsl:apply-templates/>
								</xsl:for-each>
							</aside>
						</xsl:for-each>
					</div>
				</xsl:if>
			</xsl:for-each>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Template für Absätze mit Zitaten -->
<xsl:template match="disp-quote">
	<blockquote>
		<p class="zitat">
			<xsl:apply-templates/>
		</p>
	</blockquote>
		
	<!-- Fußnoten nach jedem Absatz einfügen-->
	<xsl:if test="p/fn">
		<div class="endnoten">
			<xsl:for-each select="p/fn">
				<aside epub:type="footnote" id="{@id}">
					<xsl:value-of select="@symbol"/>
					<xsl:text>&#160;&#160;</xsl:text>
					<xsl:for-each select="p">
						<xsl:apply-templates/>
					</xsl:for-each>
				</aside>
			</xsl:for-each>
		</div>
	</xsl:if>
</xsl:template>
	
<!-- Template für die Informationskästen -->
<xsl:template match="boxed-text">
	<div class="boxed-text">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<!-- Typografie -->
<xsl:template match="bold">
	<strong>
		<xsl:apply-templates/>
	</strong>
</xsl:template>
	
<xsl:template match="semibold">
	<p class="semibold">
		<xsl:apply-templates/>
	</p>
</xsl:template>
	
<!-- Template für crossmadiale Inhalte -->
<xsl:template match="fig">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<!-- existieren verschiedene Medientypen -->
	<xsl:choose>
		<xsl:when test="alternatives">
			<!-- Jeden Medientyp gesondert behandeln -->
			<xsl:for-each select="alternatives/media">
				<xsl:choose>
					<xsl:when test="@mimetype='video'">
						<video width="320" height="240" controls="yes">
  							<source>
  								<xsl:if test="@mime-subtype='mp4'">
  									<xsl:attribute name="type">
  										<xsl:text>video/mp4</xsl:text>
  									</xsl:attribute>	
  								</xsl:if>
  								<xsl:if test="@mime-subtype='avi'">
  									<xsl:attribute name="type">
  										<xsl:text>video/avi</xsl:text>
  									</xsl:attribute>	
  								</xsl:if>
  									<xsl:attribute name="src">
  										<xsl:value-of select="@xlink:href"/>							
  									</xsl:attribute>
  							</source>
							Das Video kann nicht abgespielt werden.
						</video> 
					</xsl:when>
					<xsl:when test="@mimetype='audio'">
						<audio controls="yes">
							<xsl:if test="@mime-subtype='mp3'">
								<xsl:attribute name="type">
									<xsl:text>audio/mpeg</xsl:text>
								</xsl:attribute>	
							</xsl:if>
							<xsl:if test="@mime-subtype='ogg'">
								<xsl:attribute name="type">
									<xsl:text>audio/ogg</xsl:text>
								</xsl:attribute>	
							</xsl:if>
							<xsl:attribute name="src">
								<xsl:value-of select="@xlink:href"/>							
							</xsl:attribute>
						</audio>
						<xsl:text>Das Audio-File kann nicht abgespielt werden</xsl:text>
					</xsl:when>
					<xsl:otherwise>
						<xsl:call-template name="debug">
							<xsl:with-param name="debug-template">fig</xsl:with-param>
							<xsl:with-param name="debug-level">1</xsl:with-param>
							<xsl:with-param name="debug-text">[Nicht unterstützter Medientyp: 
							[<xsl:value-of select="@mimetype"/>]]</xsl:with-param>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:for-each>
		</xsl:when>
		<xsl:when test="graphic | inline-graphic">
			<xsl:apply-templates select="graphic | inline-graphic"/>
		</xsl:when>
		<xsl:otherwise>
			<xsl:call-template name="debug">
				<xsl:with-param name="debug-template">fig</xsl:with-param>
				<xsl:with-param name="debug-level">1</xsl:with-param>
				<xsl:with-param name="debug-text">[Kein gültiger Grafiktyp angegeben]</xsl:with-param>
			</xsl:call-template>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Template für den Knoten contrib-group -->
<xsl:template match="contrib-group">
	<div id="contrib-group">
		<xsl:apply-templates/>
	</div>	
</xsl:template>
	
<!-- Template für den noten contrib -->
<xsl:template match="contrib">
	<xsl:variable name="contrib-type">
		<xsl:choose>
			<xsl:when test="@contrib-type='content-supplier'">
				<xsl:text>author</xsl:text>
			</xsl:when>
			<xsl:when test="@contrib-type='reviewer'">
				<xsl:text>reviewer</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>other</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<div>
		<xsl:attribute name="id">
			<xsl:value-of select="$contrib-type"/>
		</xsl:attribute>
		<xsl:apply-templates/>
	</div>	
</xsl:template>
	
<xsl:template match="contrib-id">
	<xsl:variable name="contrib-id-type">
		<xsl:choose>
			<xsl:when test="@contrib-id-type='student-id'">
				<xsl:text>student</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:text>other</xsl:text>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<div>
		<xsl:attribute name="contrib-id">
			<xsl:value-of select="$contrib-id-type"/>
		</xsl:attribute>
		<xsl:value-of select="."/>
	</div>	
</xsl:template>
	

<xsl:template match="degrees">
	<div id="degrees">
		<xsl:value-of select="."/>
		<xsl:text> </xsl:text>
	</div>	
</xsl:template>

<xsl:template match="aff">
	<div id="aff">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="institution">
	<div id="institution">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="city">
	<div id="city">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<xsl:template match="country">
	<div id="country">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<xsl:template match="pub-date">
	<div id="pub-date">
		<xsl:choose>
			<xsl:when test="day[@* | node()] and month[@* | node()] and year[@* | node()]">
				<xsl:value-of select="day"/>.<xsl:value-of select="month"/>.<xsl:value-of select="year"/>
			</xsl:when>
			<xsl:when test="not(day[@* | node()]) and month[@* | node()] and year[@* | node()]">
				<xsl:value-of select="month"/>/<xsl:value-of select="year"/>
			</xsl:when>
			<xsl:when test="not(day[@* | node()]) and not(month[@* | node()]) and year[@* | node()]">
				<xsl:value-of select="year"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="debug">
					<xsl:with-param name="debug-template">pub-date</xsl:with-param>
					<xsl:with-param name="debug-level">1</xsl:with-param>
					<xsl:with-param name="debug-text">unbekanntes Datum: 
					[<xsl:value-of select="day"/>].[<xsl:value-of select="month"/>].[<xsl:value-of select="year"/>]</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</div>
</xsl:template>

<xsl:template match="isbn">
	<div id="isbn">
		<xsl:value-of select="."/>
	</div>
</xsl:template>
	
<xsl:template match="publisher">
	<div id="publisher">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="publisher-name">
	<div id="publisher-name">
		<xsl:apply-templates/>
	</div>
</xsl:template>

<xsl:template match="publisher-loc">
	<div id="publisher-loc">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<xsl:template match="permissions">
	<div id="permissions">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<xsl:template match="copyright-statement">
	<p>
		<xsl:apply-templates/>
	</p>
</xsl:template>

<xsl:template match="copyright-year">
	<p>
		<xsl:apply-templates/>
	</p>
</xsl:template>
	
<xsl:template match="copyright-holder">
	<p>
		<xsl:apply-templates/>
	</p>
</xsl:template>
	
<xsl:template match="license">
	<p>
		<xsl:apply-templates/>
		<xsl:choose>
			<xsl:when test="@license-type='open-access'">
				<xsl:text>(siehe dazu: </xsl:text><xsl:value-of select="@xlink:href"/><xsl:text>)</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="debug">
					<xsl:with-param name="debug-template">license</xsl:with-param>
					<xsl:with-param name="debug-level">1</xsl:with-param>
					<xsl:with-param name="debug-text">unbekannter Lizenztyp: [<xsl:value-of select="@license-type"/>]</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</p>
</xsl:template>
	
<xsl:template match="license-p">
	<xsl:apply-templates/>
</xsl:template>
	
<!-- Template für den Knoten <name> -->
<xsl:template match="name">
	<div id="name">
		<xsl:if test="prefix">
			<xsl:value-of select="prefix"/>
			<xsl:text> </xsl:text>
		</xsl:if>
		<!-- Schleife über alle Kidelemente given-names -->
		<xsl:for-each select="given-names">
			<xsl:value-of select="."/>
			<xsl:text> </xsl:text>
		</xsl:for-each>
		<xsl:value-of select="surname"/>
		<xsl:if test="suffix">
			<xsl:value-of select="suffix"/>
		</xsl:if>
	</div>
</xsl:template>
	
<xsl:template match="abstract | trans-abstract">
	<div id="abstract">
		<xsl:apply-templates/>
	</div>
</xsl:template>
	
<!-- Adressen -->
<!-- Template für den Knoten address -->
<xsl:template match="address">
	<div id="address">
		<xsl:if test="institution">
			<xsl:value-of select="institution"/><br/>
		</xsl:if>
		<!-- mehrere addr-line-Elemente? -->
		<xsl:for-each select="addr-line">
			<xsl:value-of select="."/><br/>
		</xsl:for-each>
		<xsl:if test="city">
			<xsl:if test="postal-code">
				<xsl:value-of select="postal-code"/>
				<xsl:text> </xsl:text>
			</xsl:if>
		<xsl:value-of select="city"/><br/>
		</xsl:if>
		<xsl:if test="country">
			<xsl:value-of select="country"/><br/>
		</xsl:if>
		<xsl:if test="fax">
			<xsl:text>Fax: </xsl:text>
			<xsl:value-of select="fax"/><br/>
		</xsl:if>
		<xsl:if test="phone">
			<xsl:text>Tel.: </xsl:text>
			<xsl:value-of select="phone"/><br/>
		</xsl:if>
		<xsl:if test="email">
			<xsl:text>Mail: </xsl:text>
			<xsl:value-of select="email"/><br/>
		</xsl:if>
		<xsl:if test="uri">
			<xsl:text>Web: </xsl:text>
			<xsl:value-of select="email"/><br/>
		</xsl:if>
		<xsl:if test="ext-link">
			<xsl:choose>
				<xsl:when test="@ext-link-type='email'">
					<xsl:text>Mail: </xsl:text>
					<xsl:value-of select="."/><br/>
				</xsl:when>
				<xsl:otherwise>
					<xsl:text>Unbekannter Linktyp: {</xsl:text>
					<xsl:value-of select="@ext-link-type"/>
					<xsl:text>}</xsl:text>
				</xsl:otherwise>	
			</xsl:choose>
		</xsl:if>
	</div>
</xsl:template>
	
<!-- Listen -->
<xsl:template match="list">
	<xsl:if test="title">
		<p class="subtitle">
			<strong><xsl:value-of select="title"/></strong>
		</p>
	</xsl:if>
	<xsl:choose>
		<xsl:when test="@list-type='bullet'">
			<div class="{@list-type}">
				<ul>
					<xsl:for-each select="list-item">
						<li>
							<xsl:apply-templates/>
						</li>
					</xsl:for-each>
				</ul>
			</div>
		</xsl:when>
		<xsl:otherwise>
			<div class="{@list-type}">
				<ol>
					<xsl:for-each select="list-item">
						<li>
							<xsl:apply-templates/>
						</li>
					</xsl:for-each>
				</ol>
			</div>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
	
<xsl:template match="def-list">
	<dl>
		<dt><xsl:value-of select="title"/></dt>
		<dd style="color:white">Platzhalter</dd>
		<xsl:for-each select="def-item">
			<xsl:apply-templates/>
		</xsl:for-each>
	</dl>
</xsl:template>
	
<xsl:template match="term">
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template match="def-list/def-item/term">
	<dt>
		<xsl:apply-templates/>
	</dt>
</xsl:template>
	
<xsl:template match="def">
	<dd>
		<xsl:value-of select="p"/>
	</dd>
</xsl:template>

<!-- Links -->
<xsl:template match="xref">
<!-- Alle Referenzen anlegen, außer ref-type=aff, für die KEIN Link angelegt wird -->
	<xsl:choose>
		<xsl:when test="normalize-space(@rid) != '' and (@ref-type='disp-formula' or
						@ref-type='bibr' or
						@ref-type='chapter' or
						@ref-type='fig' or
						@ref-type='hyperlink' or
						@ref-type='app' or
						@ref-type='table')">
			<xsl:variable name="uri">
				<xsl:choose>
					<xsl:when test="@ref-type='bibr'">
						<xsl:value-of select="$Literaturverzeichnis"/>
						<xsl:value-of select="$Contentausgabeformat"/>
					</xsl:when>
					<xsl:when test="@ref-type='app'">
						<xsl:value-of select="$Anhang"/>
						<xsl:text>_</xsl:text>
						<xsl:value-of select="oa:safe-name(@rid)"/>
						<xsl:value-of select="$Contentausgabeformat"/>
					</xsl:when>
					<xsl:when test="@ref-type='hyperlink'">
						<xsl:value-of select="@rid"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:variable name="rid">
							<xsl:value-of select="normalize-space(@rid)"/>
						</xsl:variable>		
						<xsl:variable name="aktueller_book_part">
							<!-- Ermitteln des Vorgänger-Elementes <book-part>, in dem das Linkziel liegt.
							Daraus wird dann die physische Datei, in der das Linkende im OEPBS/Content-Verzeichnis 
							liegt, abgeleitet. -->
								<xsl:value-of select="//book-part[@book-part-type='chapter'][descendant-or-self::*[@id=$rid]]/book-part-meta/title-group/label"/>
						</xsl:variable>
						<xsl:text>Kapitel_</xsl:text>
						<xsl:value-of select="oa:safe-name($aktueller_book_part)"/>
						<xsl:value-of select="$Contentausgabeformat"/>	
					</xsl:otherwise>
				</xsl:choose>

				<xsl:text>#</xsl:text>
				<xsl:value-of select="@rid"/>
			</xsl:variable>
			<a>
				<xsl:attribute name="href">
					<xsl:value-of select="$uri"/>
				</xsl:attribute>
				<xsl:apply-templates/>
			</a>
		</xsl:when>
		<xsl:otherwise>
			<xsl:apply-templates/>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>

<!-- Auszeichnungen -->
<xsl:template match="italic">
	<i><xsl:apply-templates/></i>
</xsl:template>	
	
<xsl:template match="sub">
	<sub><xsl:apply-templates/></sub>
</xsl:template>	

<xsl:template match="sup">
	<sup><xsl:apply-templates/></sup>
</xsl:template>
	
<xsl:template match="subtitle">
	<p class="subtitle">
		<strong><xsl:apply-templates/></strong>
	</p>
</xsl:template>
	
<!-- Formeln -->
<xsl:template match="disp-formula">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<figure class="disp-formula">	
		<xsl:choose>
			<xsl:when test="graphic | inline-graphic">
				<xsl:variable name="uri">
					<xsl:text>../Images/</xsl:text>
					<xsl:choose>
						<xsl:when test="graphic">					
							<xsl:value-of select="graphic/@xlink:href"/>
						</xsl:when>
						<xsl:otherwise>
							<xsl:value-of select="inline-graphic/@xlink:href"/>
						</xsl:otherwise>
					</xsl:choose>
				</xsl:variable>				
				<img class="disp-formula">
					<xsl:attribute name="src">
						<xsl:value-of select="$uri"/>
					</xsl:attribute>
				</img>
			</xsl:when>
			<xsl:when test="mml:math[@* | node()]">
				<xsl:apply-templates select="mml:math"/>
			</xsl:when>
			<xsl:when test="tex-math[@* | node()]">
				<xsl:apply-templates select="tex-math"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="debug">
					<xsl:with-param name="debug-template">disp-formula</xsl:with-param>
					<xsl:with-param name="debug-level">1</xsl:with-param>
					<xsl:with-param name="debug-text">Formel ohne Inhalt!</xsl:with-param>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
		<label class="disp-formula" epub:type="ordinal">
			<xsl:value-of select="label"/>
		</label>
	</figure>
</xsl:template>

<xsl:template match="inline-formula">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<xsl:value-of select="."/>
</xsl:template>

	
<!-- Images -->
<xsl:template match="graphic|inline-graphic">
	<xsl:variable name="uri">
		<xsl:text>../Images/</xsl:text>
		<xsl:value-of select="@xlink:href"/>
	</xsl:variable>
	<figure>
		<img>
		<xsl:attribute name="src">
			<xsl:value-of select="$uri"/>
		</xsl:attribute>
		<xsl:attribute name="alt">
			<xsl:text>Bildquelle:</xsl:text>
			<xsl:value-of select="$uri"/>
		</xsl:attribute>
		</img>
		<xsl:if test="../caption">
			<figcaption>
				<label>
					<xsl:value-of select="../label"/>
				</label>
				<xsl:value-of select="../caption"/>
				<!-- Falls DOI vorhanden, dann ausgeben -->
				<xsl:if test="../object-id">				
					<xsl:variable name="Link_DOI-images">
						<xsl:text>http://doi.org/</xsl:text>
						<xsl:value-of select="../object-id"/>
					</xsl:variable>
					<xsl:text> (DOI: </xsl:text>
					<a href="{$Link_DOI-images}">
						<xsl:text>http://doi.org/</xsl:text>
						<xsl:value-of select="../object-id"/>
					</a>
					<xsl:text>)</xsl:text>
				</xsl:if>
			</figcaption>	
		</xsl:if>	
	</figure>
</xsl:template>
	
<!-- Images in tables -->
<xsl:template match="table-wrap/graphic">
	<xsl:variable name="uri">
		<xsl:text>../Images/</xsl:text>
		<xsl:value-of select="@xlink:href"/>
	</xsl:variable>
	<figure>
		<img>
			<xsl:attribute name="src">
				<xsl:value-of select="$uri"/>
			</xsl:attribute>
			<xsl:attribute name="alt">
				<xsl:text>Bildquelle:</xsl:text>
				<xsl:value-of select="$uri"/>
			</xsl:attribute>
		</img>
	</figure>
</xsl:template>
	
<xsl:template match="mml:math">
	<!-- hier Math-ML-Formeln behandeln -->
</xsl:template>
	
<xsl:template match="tex-math">
	<!-- hier TeX-Formeln behandeln -->
</xsl:template>
	
<!-- Quellcode -->
<xsl:template match="code">
	<pre>
		<code>
			<xsl:apply-templates/>
		</code>
	</pre>
</xsl:template>
	
<!-- Tabellen -->
<xsl:template match="table-wrap">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<table>
		<caption>
			<label>
				<xsl:value-of select="label"/>
			</label>
			<xsl:text> </xsl:text>
			<xsl:for-each select="caption/title">
				<xsl:apply-templates/>
			</xsl:for-each>
				
			<!-- Fußnoten nach jedem Absatz einfügen-->
			<xsl:if test="caption/title/fn">
				<div class="endnoten">
					<xsl:for-each select="caption/title/fn">
						<aside epub:type="footnote" id="{@id}">
							<xsl:value-of select="@symbol"/>
							<xsl:text>&#160;&#160;</xsl:text>
							<xsl:for-each select="p">
								<xsl:apply-templates/>
							</xsl:for-each>
						</aside>
					</xsl:for-each>
				</div>
			</xsl:if>
				
			<!-- Falls DOI vorhanden, dann ausgeben -->
			<xsl:if test="object-id">				
				<xsl:variable name="Link_DOI-table">
					<xsl:text>http://doi.org/</xsl:text>
					<xsl:value-of select="object-id"/>
				</xsl:variable>
				<xsl:text> (DOI: </xsl:text>
				<a href="{$Link_DOI-table}">
					<xsl:text>http://doi.org/</xsl:text>
					<xsl:value-of select="object-id"/>
				</a>
				<xsl:text>)</xsl:text>
			</xsl:if>
		</caption>
	
		<xsl:if test="table-wrap/graphic">
			<xsl:value-of select="graphic/@xlink:href"/>
		</xsl:if>
		
		<xsl:apply-templates/>
		
	</table>
</xsl:template>
	
<xsl:template match="table">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<thead>
		<!-- Tabellenkopf -->
		<xsl:for-each select="thead/tr">
			<tr>
				<xsl:for-each select="th">
					<xsl:choose>
						<xsl:when test="@colspan">
							<th class="head" colspan="{@colspan}">
								<xsl:apply-templates/>
							</th>
						</xsl:when>
						<xsl:otherwise>
							<th class="head">
								<xsl:apply-templates/>
							</th>
						</xsl:otherwise>
					</xsl:choose>
			</xsl:for-each>
			</tr>
		</xsl:for-each>
	</thead>
	<tbody>
		<!-- Tabellenrumpf -->
		<xsl:for-each select="tbody/tr">
			<tr>
				<xsl:for-each select="td">
					<td class="normal">
						<xsl:apply-templates/>
					</td>
				</xsl:for-each>
			</tr>
		</xsl:for-each>
	</tbody>
</xsl:template>
	
<xsl:template match="table-wrap-foot">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="fn-group">
	<xsl:for-each select="fn">
		<xsl:apply-templates/>
	</xsl:for-each>
</xsl:template>
	
<xsl:template match="fn">
	<xsl:choose>
		<xsl:when test="normalize-space(@id) != ''">
			<a epub:type="noteref" href="#{@id}">
				<sup><xsl:value-of select="@symbol"/></sup>
			</a>
		</xsl:when>
		<xsl:otherwise>
			<sup><xsl:value-of select="@symbol"/></sup>
		</xsl:otherwise>
	</xsl:choose>
</xsl:template>
	
<!-- Bibliografie -->
<xsl:template match="ref-list">
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template match="ref">
	<li id="{@id}">
		<xsl:apply-templates/>
	</li>
	<!-- <button onclick="window.history.back()">Zurück</button> -->
</xsl:template>
	
<xsl:template match="ref/label">
	<xsl:apply-templates/>
</xsl:template>

<xsl:template match="mixed-citation">
	<xsl:apply-templates/>
</xsl:template>	
	
<!-- Appendix -->
<xsl:template match="book-app">
	<xsl:if test="@id">
		<a id="{@id}"/>
	</xsl:if>
	<div id="appendix">
		<xsl:apply-templates/>			
	</div>
</xsl:template>
	
<xsl:template match="break">
	<br/>
</xsl:template>
	
<xsl:template match="object-id">
</xsl:template>
	
<!-- Elemente, die im jeweiligen Kontext behandelt werden -->
<xsl:template match="label|title|caption">
	<!-- nichts ausgeben, die Inhalte werden in dem jeweiligen Kontext transformiert -->
</xsl:template>	
	
<!-- Debugging -->
<xsl:template name="debug">
	<xsl:param name="debug-template"/>
	<xsl:param name="debug-level"/>
	<xsl:param name="debug-text"/>
	
	<xsl:if test="$debug-level &lt;= $HTML-Debuglevel">
		<xsl:message>[<xsl:value-of select="$debug-level"/>/<xsl:value-of select="$HTML-Debuglevel"/>][<xsl:value-of select="$debug-template"/>]: <xsl:value-of select="$debug-text"/>
		</xsl:message>
	</xsl:if>
</xsl:template>
	
<xsl:template match="sc">
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template match="index-term">
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template match="attrib">
	<xsl:apply-templates/>
</xsl:template>
	
<xsl:template match="monospace">
	<xsl:apply-templates/>
</xsl:template>
	
</xsl:stylesheet>
