<p:declare-step version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	name="ner-rdf">
	
	<!--
	harvest from http://apo.org.au/oai3?verb=ListRecords&amp;metadataPrefix=oai_dc
	select dc:identifier[starts-with(., 'http://apo.org.au/files/')]
	-->
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>

	<p:option name="input-file" required="true"/>
	<p:variable name="resource-base-uri" select="'http://apo.conaltuohy.com/resource/'"/>
	
	<p:template name="load-document">
		<p:with-param name="input-file" select="$input-file"/>
		<p:input port="source"><p:empty/></p:input>
		<p:input port="template">
			<p:inline>
				<c:request href="{$input-file}" method="GET"/>
			</p:inline>
		</p:input>
	</p:template>
	<p:http-request/>
	<p:template name="recognise-entities">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="template">
			<p:inline>
				<c:request href="http://localhost:9998/tika" method="PUT" detailed="true">
					<c:header name="Accept" value="text/xml"/>
					{/c:body}
				</c:request>
			</p:inline>
		</p:input>
	</p:template>
	<p:http-request name="tika"/>
	<p:xslt name="upconvert-ner-results">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="source" select="/c:response/c:body/*">
			<p:pipe step="tika" port="result"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="ner-xhtml-to-marked-up-html.xsl"/>
		</p:input>
	</p:xslt>
	<p:store indent="true">
		<p:with-option name="href" select="concat($input-file, '.xhtml')"/>
	</p:store>
	<p:xslt name="convert-ner-results-to-rdf">
		<p:with-param name="document-file-name" select="replace($input-file, '(.*/)', '')"/>
		<p:with-param name="resource-base-uri" select=" 'http://apo.conaltuohy.com/resource/' "/>
		<p:input port="source">
			<p:pipe step="upconvert-ner-results" port="result"/>
		</p:input>
		<p:input port="stylesheet">
			<p:document href="ner-xhtml-to-rdf.xsl"/>
		</p:input>
	</p:xslt>
	<p:store indent="true">
		<p:with-option name="href" select="concat($input-file, '.rdf')"/>
	</p:store>
	
</p:declare-step>
