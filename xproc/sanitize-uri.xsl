<!-- Sanitizes the request URI given in /c:request/@href -->
<!-- Some URIs contain invalid characters (e.g. "[") which should be escaped. 
A web browser would recognise those chars and escape them. This transform does the same -->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="3.0"
	xmlns:c="http://www.w3.org/ns/xproc-step">
	<xsl:template match="*">
		<xsl:copy>
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="@href"/>
			<xsl:apply-templates/>
		</xsl:copy>
	</xsl:template>
	
	<xsl:template match="@href">
		<xsl:attribute name="href">
			<xsl:analyze-string select="." regex="(https?://[^\?/]*)([^?#]*)(.*)">
				<xsl:matching-substring>
					<!-- regex-group(1) = scheme and host -->
					<!-- regex-group(2) = path -->
					<!-- regex-group(3) = query and fragment id -->
					<xsl:value-of select="regex-group(1)"/>
					<xsl:analyze-string select="regex-group(2)" regex="[/a-zA-Z0-9\-\._~]">
						<!-- matches any character OK in a URI path -->
						<xsl:matching-substring>
							<xsl:value-of select="."/>
						</xsl:matching-substring>
						<!-- characters that aren't OK get encoded -->
						<xsl:non-matching-substring>
							<xsl:value-of select="encode-for-uri(.)"/>
						</xsl:non-matching-substring>
					</xsl:analyze-string>
					<xsl:value-of select="regex-group(3)"/>
				</xsl:matching-substring>
			</xsl:analyze-string>
		</xsl:attribute>
	</xsl:template>
	
</xsl:stylesheet>

