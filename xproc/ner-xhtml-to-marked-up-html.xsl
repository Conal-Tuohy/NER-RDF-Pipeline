<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:xlink="http://www.w3.org/1999/xlink" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:crm="http://erlangen-crm.org/current/"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:sim="http://purl.org/ontology/similarity/"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:dc="http://purl.org/dc/elements/1.1/">
	
	<xsl:variable name="names" select="
		/xhtml:html
			/xhtml:head
				/xhtml:meta[@name=('NER_PERSON', 'NER_LOCATION', 'NER_ORGANIZATION')]
	"/>
	
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="/xhtml:html/xhtml:body//text()[normalize-space()]">
		<xsl:call-template name="mark-up-names"/>
	</xsl:template>
	
	<xsl:template name="mark-up-names">
		<xsl:param name="names" select="$names"/>
		<xsl:param name="text" select="."/>
		<!--<xsl:comment>looking for <xsl:value-of select="count($names)"/> names</xsl:comment>-->
		<xsl:choose>
			<xsl:when test="count($names) &gt; 0 and normalize-space($text)">
				<!--<xsl:comment>names and text</xsl:comment>-->
				<xsl:variable name="longest-name-length" select="max(for $name in ($names/@content) return string-length($name))"/>
				<!--<xsl:comment>longest name to check is : <xsl:value-of select="$longest-name-length"/> chars</xsl:comment>-->
				<xsl:variable name="longest-name"
					select="$names[string-length(@content)=$longest-name-length][1]"/>
				<!--<xsl:comment>looking for name: "<xsl:value-of select="$longest-name/@content"/>"</xsl:comment>-->
				<xsl:variable name="encoded-name" select="encode-for-uri($longest-name/@content)"/>
				<xsl:choose>
					<xsl:when test="contains($text, $longest-name/@content)">
						<xsl:call-template name="mark-up-names">
							<xsl:with-param name="names" select="$names except $longest-name"/>
							<xsl:with-param name="text" select="substring-before($text, $longest-name/@content)"/>
						</xsl:call-template>
						<xsl:call-template name="mark-up-name">
							<xsl:with-param name="name" select="$longest-name"/>
						</xsl:call-template>
						<xsl:call-template name="mark-up-names">
							<xsl:with-param name="names" select="$names"/>
							<xsl:with-param name="text" select="substring-after($text, $longest-name/@content)"/>
						</xsl:call-template>
					</xsl:when>
					<xsl:otherwise>
						<!-- longest name not found - look for next longest name ... -->
						<xsl:call-template name="mark-up-names">
							<xsl:with-param name="names" select="$names except $longest-name"/>
							<xsl:with-param name="text" select="$text"/>
						</xsl:call-template>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:when>
			<xsl:otherwise>
				<!-- no more text to replace inside, or no more names to look for -->
				<!--
				<xsl:comment>no more names or no more text</xsl:comment>
				<xsl:comment><xsl:value-of select="count($names)"/> names</xsl:comment>
				-->
				<xsl:value-of select="$text"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="mark-up-name">
		<xsl:param name="name"/>
		<xsl:element name="a">
			<!-- a list of the @name attributes (i.e. the name TYPEs) of any of the recognised name that
			are a textual match for the text being marked up. e.g. a name may have been recognised as
			more than one type of entity, and lacking context to decide which, we have to assign both classes
			to the mention -->
			<!-- ISSUE: can we get the NER system to return the marked up names? -->
			<xsl:attribute name="class" select="string-join($names[@content = $name/@content]/@name, ' ')"/>
			<xsl:value-of select="$name/@content"/>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>
	
