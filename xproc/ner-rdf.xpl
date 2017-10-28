<p:library version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:apo="https://github.com/Conal-Tuohy/NER-RDF-Pipeline">

	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	<p:import href="http-cache.xpl"/>
	
	<p:declare-step type="apo:recognise-named-entities" name="recognise-named-entities">
		<p:input port="source"/>
		<p:output port="result"/>
		<p:option name="resource-base-uri" select=" 'http://apo.conaltuohy.com/data/' "/><!-- base uri for minting rdf resource uris -->
		<p:option name="document-uri" required="true"/><!-- uri of the source document -->

		<p:try name="convert-the-digital-object-to-rdf">
			<p:group name="parse-digital-object-to-create-rdf">
				<p:output port="result"/>
				<p:documentation>Format the document into a request for NER</p:documentation>
				<!-- strip charset from content type because Tika doesn't like it; it will work the charset out itself anyway -->
				<p:string-replace match="/c:body/@content-type[contains(., ';')]" replace="substring-before(., ';')"/>
				<cx:message message="Preparing NER request ..."/>
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
				<p:documentation>Submit the NER request to Tika</p:documentation>
				<cx:message message="Submitting document for NER ..."/>
				<p:http-request name="tika-web-service" />
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
				<p:identity>
					<p:input port="source">
						<p:pipe step="ner-failed" port="error"/>
					</p:input>
				</p:identity>
				<cx:message name="ner-failure">
					<p:with-option name="message" select="string-join(//c:message, '&#x0A;')"/>
				</cx:message>
			</p:catch>
		</p:try>
		<cx:message message="Converting NER results to RDF ..."/>
		<p:xslt name="convert-ner-results-to-rdf">
			<p:with-param name="document-uri" select="$document-uri"/>
			<p:with-param name="resource-base-uri" select="$resource-base-uri"/>
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
