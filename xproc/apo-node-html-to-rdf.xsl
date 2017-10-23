<!-- 
replacing

				<p:variable name="object-uri" select="(//xhtml:div[@class='view-content']//xhtml:a/@href)[1]"/>
				<p:variable name="object-title" select="//xhtml:meta[@name='dcterms.title']/@content"/>
				
				<p:template name="web-page-graph">
					<p:with-param name="page-uri" select="$page-uri"/>
					<p:with-param name="object-uri" select="$object-uri"/>
					<p:with-param name="object-title" select="$object-title"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<rdf:Description rdf:about="{$object-uri}" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
								 the digital object (e.g. a PDF) is the primary topic of the html ("splash") page 
								<foaf:isPrimaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{$page-uri}"/>
								 the digital object's title comes from the html page's metadata 
								<dcterms:title xmlns:dcterms="http://purl.org/dc/terms/">{$object-title}</dcterms:title>
							</rdf:Description>
						</p:inline>
					</p:input>
				</p:template>
-->


<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:xlink="http://www.w3.org/1999/xlink" 
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:foaf="http://xmlns.com/foaf/0.1/"
	xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
	xmlns:crm="http://erlangen-crm.org/current/"
	xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
	xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:sim="http://purl.org/ontology/similarity/"
	xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:dcterms="http://purl.org/dc/terms/"
	xmlns:c="http://www.w3.org/ns/xproc-step"
	xpath-default-namespace="http://www.w3.org/1999/xhtml">
	
	<xsl:param name="resource-base-uri"/>
	<xsl:param name="page-uri"/>
		
	<xsl:template match="/html">	
		<xsl:variable name="object-uri" select="(//div[@class='view-content']//a/@href)[1]"/>

		<rdf:RDF>
			<rdf:Description rdf:about="" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
				<xsl:attribute name="xml:base" select="$object-uri"/>
				<!-- the digital object (e.g. a PDF) is the primary topic of the html ("splash") page -->
				<foaf:isPrimaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{$page-uri}"/>
				<!-- the digital object's title comes from the html page's metadata -->
				<dcterms:title><xsl:value-of select="//meta[@name='dcterms.title']/@content"/></dcterms:title>
				<!-- publisher is listed as "publisher-name" -->
				<xsl:apply-templates select="//div[@class='field-name-field-publisher-name']//a/@href">
					<xsl:with-param name="predicate" select=" 'dcterms:publisher' "/>
				</xsl:apply-templates>
				<!-- creators are listed following the heading 'CREATORS' -->
				<xsl:apply-templates select="//div[@class='label-above'][.='CREATORS']/following-sibling::div[1]//a/@href">
					<xsl:with-param name="predicate" select=" 'dcterms:creator' "/>
				</xsl:apply-templates>
				<!-- subjects are listed as 'broad subject areas', "subjects", and also "keywords" -->
				<xsl:apply-templates select="//div[tokenize(@class)=('field-name-field-subject', 'field-name-field-subject-broad', 'field-name-field-keyword')]//a/@href">
					<xsl:with-param name="predicate" select=" 'dcterms:subject' "/>
				</xsl:apply-templates>
				<!-- spatial terms are 'geographic-location' -->
				<xsl:apply-templates select="//div[tokenize(@class)='field-name-field-geographic-location']//a/@href">
					<xsl:with-param name="predicate" select=" 'dcterms:spatial' "/>
				</xsl:apply-templates>
				<!-- containment within APO's "Collections" is modelled as dcterms:isPartOf -->
				<xsl:apply-templates select="//div[tokenize(@class)='field-name-field-apo-collections']//a/@href">
					<xsl:with-param name="predicate" select=" 'dcterms:isPartOf' "/>
				</xsl:apply-templates>
			</rdf:Description>
		</rdf:RDF>
	</xsl:template>
	
	<xsl:template match="a/@href">
		<xsl:param name="predicate"/>
		<xsl:element name="{$predicate}">
			<xsl:attribute name="rdf:resource" select="concat(., '#')"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match="c:*">
		<rdf:RDF>
			<xsl:attribute name="xml:base"><xsl:value-of select="$resource-base-uri"/></xsl:attribute>
			<foaf:Document rdf:about="{$page-uri}">
				<rdfs:comment>failed to parse <xsl:value-of select="$page-uri"/></rdfs:comment>
				<xsl:for-each select="//c:error">
					<rdfs:comment><xsl:value-of select="."/></rdfs:comment>
				</xsl:for-each>
			</foaf:Document>
		</rdf:RDF>
	</xsl:template>
	
</xsl:stylesheet>

