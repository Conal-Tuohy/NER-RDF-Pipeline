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
	xmlns:prov="http://www.w3.org/ns/prov#"
	xmlns:dct="http://purl.org/dc/elements/1.1/">
	
	<xsl:param name="resource-base-uri"/>
	<xsl:param name="document-file-name"/>
	<xsl:variable name="document-id" select="translate(encode-for-uri($document-file-name), '%', '_')"/>
	
	<xsl:template match="/c:errors">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<foaf:Document rdf:ID="document-{$document-id}">
				<rdfs:comment>failed to parse <xsl:value-of select="$document-file-name"/></rdfs:comment>
				<xsl:for-each select="c:error">
					<rdfs:comment><xsl:value-of select="."/></rdfs:comment>
				</xsl:for-each>
			</foaf:Document>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>
	
