<p:declare-step version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:file="http://exproc.org/proposed/steps/file"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	name="ner-rdf">
	
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
<!--		<p:output port="result"/>
-->

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
	<!--
	<p:store href="../output.pdf" cx:decode="true"/>
	<p:add-attribute match="/c:body" attribute-name="content-type" attribute-value="application/pdf"/>
					<c:header name="Content-Type" value="application/pdf"/>
	-->
	<p:template name="recognise-entities">
		<p:input port="parameters"><p:empty/></p:input>
		<p:input port="template">
			<p:inline>
				<c:request href="http://localhost:9999/tika" method="PUT" detailed="true">
					<c:header name="Accept" value="text/xml"/>
					{/c:body}
				</c:request>
			</p:inline>
		</p:input>
	</p:template>
	<p:http-request name="tika"/>
	<p:store>
		<p:with-option name="href" select="concat($input-file, '.xhtml')"/>
		<p:input port="source" select="/c:response/c:body/*">
			<p:pipe step="tika" port="result"/>
		</p:input>
	</p:store>

	
</p:declare-step>
