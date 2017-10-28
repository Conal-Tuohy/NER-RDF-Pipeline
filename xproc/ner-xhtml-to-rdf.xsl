<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
	xmlns:xlink="http://www.w3.org/1999/xlink" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:crm="http://erlangen-crm.org/current/"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:sim="http://purl.org/ontology/similarity/"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:dct="http://purl.org/dc/elements/1.1/"
	xmlns:schema="http://schema.org/"
	xmlns:c="http://www.w3.org/ns/xproc-step">
	
	<xsl:param name="resource-base-uri"/>
	<xsl:param name="document-uri"/>
	<xsl:variable name="document-id" select="translate(encode-for-uri($document-uri), '%', '_')"/>
	
	<!-- the list of names recognised by the Stanford NER --> 
	<!-- excluding any personal names consist of a single word e.g. "Arthur" -->
	<xsl:variable name="names" select="
		/c:response/c:body/xhtml:html/xhtml:head/xhtml:meta[
			@name=('NER_LOCATION', 'NER_ORGANIZATION') or
			(
				@name='NER_PERSON' and contains(normalize-space(@content), ' ')
			)
		]
	"/>
	
	
	<xsl:template match="xhtml:meta[@name='NER_PERSON']" mode="type-curie">foaf:Person</xsl:template>
	<xsl:template match="xhtml:meta[@name='NER_PERSON']" mode="type-id-prefix">person-</xsl:template>
	
	<xsl:template match="xhtml:meta[@name='NER_LOCATION']" mode="type-curie">geo:SpatialThing</xsl:template>
	<xsl:template match="xhtml:meta[@name='NER_LOCATION']" mode="type-id-prefix">location-</xsl:template>
	
	<xsl:template match="xhtml:meta[@name='NER_ORGANIZATION']" mode="type-curie">foaf:Group</xsl:template>
	<xsl:template match="xhtml:meta[@name='NER_ORGANIZATION']" mode="type-id-prefix">group-</xsl:template>
	
	<xsl:template match="xhtml:meta" mode="id">
		<xsl:apply-templates select="." mode="type-id-prefix"/><!-- e.g. "person-", "location-", "group-" -->
		<xsl:value-of select="translate(encode-for-uri(translate(@content, ' ', '_')), '%', '_')"/>
	</xsl:template>
	
	<!-- successful NER leads to extracting marked up entities from the HTML header -->
	<xsl:template match="/c:response[@status='200']">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<xsl:if test="$names">
				<foaf:Document rdf:about="{$document-uri}">
					<xsl:for-each select="$names">
						<schema:mentions>
							<!-- describe the Named Entity recognised -->
							<xsl:variable name="name-type">
								<xsl:apply-templates select="." mode="type-curie"/><!-- e.g. "foaf:Person", geo:SpatialThing -->
							</xsl:variable>
							<xsl:element name="{$name-type}">
								<xsl:attribute name="foaf:name">
									<xsl:value-of select="@content"/>
								</xsl:attribute>
								<xsl:attribute name="rdf:about">
									<xsl:apply-templates mode="id" select="."/>
								</xsl:attribute>
							</xsl:element>
						</schema:mentions>
					</xsl:for-each>
				</foaf:Document>
				<xsl:for-each-group select="$names" group-by="@content">
					<xsl:variable name="name-text" select="@content"/>
					<xsl:variable name="count" select="count(/xhtml:html/xhtml:body//xhtml:a[.=$name-text])"/>
					<xsl:if test="$count &gt; 0">
						<sim:Association rdf:about="references-{$document-id}-{translate(encode-for-uri(translate(@content, ' ', '_')), '%', '_')}">
							<sim:subject rdf:resource="{$document-uri}"/>
							<sim:weight rdf:datatype="http://www.w3.org/2001/XMLSchema#int">
								<xsl:value-of select="$count"/>
							</sim:weight>
							<xsl:for-each select="current-group()">
								<xsl:variable name="name-id">
									<xsl:apply-templates mode="id" select="."/>
								</xsl:variable>
								<sim:object rdf:resource="{$name-id}"/>
							</xsl:for-each>
						</sim:Association>
					</xsl:if>
				</xsl:for-each-group>
			</xsl:if>
		</rdf:RDF>
	</xsl:template>
	
	<!-- NER web service has reported an error with a non-200 status code response -->
	<xsl:template match="/c:response[not(@status='200')]/c:body[@content-type='text/plain']">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<foaf:Document rdf:about="{$document-uri}">
				<rdfs:comment>Tika returned an error: <xsl:value-of select="."/></rdfs:comment>
			</foaf:Document>
		</rdf:RDF>
	</xsl:template>
	
	<!-- an XProc error occurred while invoking the NER web service -->
	<xsl:template match="/c:errors">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<foaf:Document rdf:about="{$document-uri}">
				<rdfs:comment>failed to parse <xsl:value-of select="$document-uri"/></rdfs:comment>
				<xsl:for-each select="//c:error">
					<rdfs:comment><xsl:value-of select="."/></rdfs:comment>
				</xsl:for-each>
			</foaf:Document>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>

