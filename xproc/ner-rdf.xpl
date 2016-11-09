<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:ner="https://github.com/Conal-Tuohy/NER-RDF-Pipeline">

	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="http-cache.xpl"/>
	
	<p:declare-step name="web" type="ner:generate-rdf-from-web">
		<p:option name="href" required="true"/>
		<p:option name="cache-location" required="true"/>
		<p:option name="resource-base-uri" required="true"/>
		<p:output port="result"/>
		<ner:http-get>
			<p:with-option name="href" select="$href"/>
			<p:with-option name="cache-location" select="$cache-location"/>
		</ner:http-get>
		<ner:generate-rdf>
			<p:with-option name="resource-base-uri" select="$resource-base-uri"/>
			<p:with-option name="document-uri" select="$href"/>
		</ner:generate-rdf>
	</p:declare-step>
	

	<p:declare-step name="file" type="ner:generate-rdf-from-file">	
		<!--
		harvest from http://apo.org.au/oai3?verb=ListRecords&amp;metadataPrefix=oai_dc
		select dc:identifier[starts-with(., 'http://apo.org.au/files/')]
		-->
		<p:output port="result"/>
		<p:option name="input-file" required="true"/>
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
		<ner:generate-rdf>
			<p:with-option name="resource-base-uri" select="'http://apo.conaltuohy.com/resource/'"/>
			<p:with-option name="document-uri" select="$input-file"/>
		</ner:generate-rdf>

	</p:declare-step>	
	
	<p:declare-step type="ner:generate-rdf" name="generate-rdf">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="resource-base-uri" required="true"/><!-- base uri for minting rdf resource uris -->
		<p:option name="document-uri" required="true"/><!-- uri of the source document -->
		<p:template name="construct-ner-request">
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
		<p:try name="convert-the-digital-object-to-rdf">
			<p:group name="parse-digital-object-to-create-rdf">
				<p:output port="result"/>
				<p:http-request name="tika-web-service"/>
				<p:identity>
					<p:input port="source" select="/c:response/c:body/*">
						<p:pipe step="tika-web-service" port="result"/>
					</p:input>
				</p:identity>
				<!--
				QAZ disabling because of poor performance
				<p:xslt name="upconvert-ner-results">
					<p:input port="parameters"><p:empty/></p:input>
					<p:input port="stylesheet">
						<p:document href="ner-xhtml-to-marked-up-html.xsl"/>
					</p:input>
				</p:xslt>
				<p:store indent="true">
					<p:with-option name="href" select="concat($input-file, '.xhtml')"/>
				</p:store>
				-->
			</p:group>
			<p:catch name="ner-failed">
				<p:output port="result"/>
				<p:identity/>
			</p:catch>
		</p:try>

		<p:xslt name="convert-ner-results-to-rdf">
			<p:with-param name="document-file-name" select="replace($document-uri, '(.*/)', '')"/>
			<p:with-param name="resource-base-uri" select=" 'http://apo.conaltuohy.com/resource/' "/>
			<p:input port="stylesheet">
				<p:document href="ner-xhtml-to-rdf.xsl"/>
			</p:input>
		</p:xslt>
		<!--
		<p:store indent="true">
			<p:with-option name="href" select="concat($input-file, '.rdf')"/>
		</p:store>
		-->
	</p:declare-step>
	
</p:library>
