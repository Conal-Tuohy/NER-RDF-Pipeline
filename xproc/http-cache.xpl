<p:declare-step version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:ner="https://github.com/Conal-Tuohy/NER-RDF-Pipeline"
	name="http-get" type="ner:http-get">
	<p:documentation>
		This pipeline implements an http cache.
		The pipeline first checks if the document identified by the href parameter is present in the cache. The cache does not implement any expiration strategy; which means it is currently only suitable for static content.
		If the document is present, it is returned, otherwise it is downloaded and cached.
		Internally, the document URI is hashed to a single byte value, which is used as the name for the folder in which the document is stored. This will divide the cache into 256 sub-folders, and thereby reduce the number of files in the cache folder. 
	</p:documentation>
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:output port="result"/>

	<p:option name="href" required="true"/>
	<p:option name="cache-location" required="true"/>
	<file:mkdir fail-on-error="false">
		<p:with-option name="href" select="$cache-location"/>
	</file:mkdir>
	<p:xslt name="hash">
		<p:with-param name="key" select="$href"/>
		<p:input port="source"><p:inline><ignored/></p:inline></p:input>
		<p:input port="stylesheet">
			<p:inline>
				<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
					<xsl:param name="key"/>
					<xsl:template match="/">
						<xsl:element name="hash">
							<xsl:call-template name="hash">
								<xsl:with-param name="characters" select="string-to-codepoints($key)"/>
							</xsl:call-template>
						</xsl:element>
					</xsl:template>
					<xsl:template name="hash">
						<xsl:param name="characters"/>
						<xsl:param name="partial-hash" select="0"/>
						<xsl:choose>
							<xsl:when test="exists($characters)">
								<xsl:variable name="character" select="$characters[1]"/>
								<xsl:call-template name="hash">
									<xsl:with-param name="characters" select="subsequence($characters, 2)"/>
									<xsl:with-param name="partial-hash" select="($partial-hash + $character) mod 256"/>
								</xsl:call-template>
							</xsl:when>
							<xsl:otherwise>
								<xsl:value-of select="$partial-hash"/>
							</xsl:otherwise>
						</xsl:choose>
					</xsl:template>
				</xsl:stylesheet>
			</p:inline>
		</p:input>
	</p:xslt>
	<p:group>
		<p:variable name="hash" select="/*"/>
		<p:variable name="encoded-href" select="encode-for-uri(encode-for-uri($href))"/>
		<p:variable name="file-name" select="concat($cache-location, $hash, '/', $encoded-href, '.xml')"/>
		<p:try>
			<p:group>
				<p:load>
					<p:with-option name="href" select="$file-name"/>
				</p:load>
			</p:group>
			<p:catch>				
				<file:mkdir fail-on-error="false">
					<p:with-option name="href" select="concat($cache-location, $hash)"/>
				</file:mkdir>
				<p:template name="load-document">
					<p:with-param name="href" select="$href"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<c:request href="{$href}" method="GET"/>
						</p:inline>
					</p:input>
				</p:template>
				<p:http-request name="download"/>
				<p:store>
					<p:with-option name="href" select="$file-name"/>
				</p:store>				
				<p:identity>
					<p:input port="source">
						<p:pipe step="download" port="result"/>
					</p:input>
				</p:identity>
			</p:catch>
		</p:try>
	</p:group>
	
</p:declare-step>
