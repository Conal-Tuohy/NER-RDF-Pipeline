<?xml version="1.0"?>
<!--
   Copyright 2017 Conal Tuohy

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
-->
<p:declare-step
	name="main"
	version="1.0" 
	xmlns:p="http://www.w3.org/ns/xproc" 
	xmlns:fn="http://www.w3.org/2005/xpath-functions" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:apo="https://github.com/Conal-Tuohy/NER-RDF-Pipeline"
	xmlns:pxf="http://exproc.org/proposed/steps/file"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:cx="http://xmlcalabash.com/ns/extensions"
	xmlns:sitemap="http://www.sitemaps.org/schemas/sitemap/0.9"
>
	<!-- import calabash extension library to enable use of delete-file step -->
	<p:import href="http://xmlcalabash.com/extension/steps/library-1.0.xpl"/>
	
	<!-- library for performing ner and producing rdf -->
	<p:import href="ner-rdf.xpl"/>
	
	<!-- 
	<p:import href="xproc-z-library.xpl"/>
	-->
	
	<p:option name="sitemapindex-uri" required="true"/>
	
	<apo:harvest-sitemapindex>
		<p:with-option name="sitemapindex-uri" select="$sitemapindex-uri"/>
	</apo:harvest-sitemapindex>

	<p:declare-step type="apo:harvest-sitemapindex" name="harvest-sitemapindex">
		<p:option name="sitemapindex-uri" required="true"/>
		<!-- for each sitemap x in sitemapindex, harvest-sitemap x -->
		<p:load name="sitemapindex">
			<p:with-option name="href" select="$sitemapindex-uri"/>
		</p:load>
		<apo:fix-hostnames-in-sitemap/>
		<!-- process list of sitemaps -->
		<p:for-each name="sitemap-in-sitemapindex">
			<p:iteration-source select="/sitemap:sitemapindex/sitemap:sitemap/sitemap:loc"/>
			<apo:harvest-sitemap>
				<p:with-option name="sitemap-uri" select="."/>
			</apo:harvest-sitemap>
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step type="apo:harvest-sitemap" name="harvest-sitemap">
		<p:option name="sitemap-uri" required="true"/>
		<!-- for each page y in sitemap, harvest-page y -->
		<p:load name="sitemap">
			<p:with-option name="href" select="$sitemap-uri"/>
		</p:load>
		<apo:fix-hostnames-in-sitemap/>
		<!-- ignore pages which don't have "/node/" in the URI -->
		<p:delete match="/sitemap:urlset/sitemap:url[not(matches(sitemap:loc, '^.*/node/.+$'))]"/>
		<!-- process list of pages -->
		<p:for-each name="page-in-sitemap">
			<p:iteration-source select="/sitemap:urlset/sitemap:url/sitemap:loc"/>
			<apo:harvest-page>
				<p:with-option name="page-uri" select="."/>
			</apo:harvest-page>
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step type="apo:harvest-page" name="harvest-page">
		<p:option name="page-uri" required="true"/>
		<p:documentation>Download the page, extract metadata, download linked object, perform ner, convert to rdf, store results</p:documentation>
		<p:documentation>Formulate a request for the Drupal page</p:documentation>
		<apo:http-get name="page">
			<p:with-option name="href" select="$page-uri"/>
		</apo:http-get>
		<p:for-each name="page-retrieved">
			<!-- convert any HTTP errors to RDF and store them -->
			<p:iteration-source select="/c:response[@status='200']/c:body"/>
			<!-- Tidy the HTML page up into XHTML form -->
			<p:unescape-markup name="convert-to-xhtml" content-type="text/html"/>
			<!-- Discard the wrapper element -->
			<p:unwrap match="/*"/>
			<!-- extract and store metadata -->
			<p:for-each name="page-containing-link-to-an-object" xmlns:xhtml="http://www.w3.org/1999/xhtml">
				<p:iteration-source select="/xhtml:html[.//xhtml:div[@class='view-content']//xhtml:a/@href]"/>
				
				<!-- extract metadata from HTML, store as RDF graph -->
				<p:variable name="object-uri" select="(//xhtml:div[@class='view-content']//xhtml:a/@href)[1]"/>
				<p:variable name="object-title" select="//xhtml:meta[@name='dcterms.title']/@content"/>
				<!-- generate RDF graph -->
				<p:template name="web-page-graph">
					<p:with-param name="page-uri" select="$page-uri"/>
					<p:with-param name="object-uri" select="$object-uri"/>
					<p:with-param name="object-title" select="$object-title"/>
					<p:input port="source"><p:empty/></p:input>
					<p:input port="template">
						<p:inline>
							<rdf:Description rdf:about="{$object-uri}" xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
								<!-- the digital object (e.g. a PDF) is the primary topic of the html ("splash") page -->
								<foaf:isPrimaryTopicOf xmlns:foaf="http://xmlns.com/foaf/0.1/" rdf:resource="{$page-uri}"/>
								<!-- the digital object's title comes from the html page's metadata -->
								<dcterms:title xmlns:dcterms="http://purl.org/dc/terms/">{$object-title}</dcterms:title>
								<!-- TODO extract more metadata from the HTML page -->
							</rdf:Description>
						</p:inline>
					</p:input>
				</p:template>
				<apo:store-graph name="save-web-page-graph">
					<p:with-option name="graph-uri" select="$page-uri"/>
				</apo:store-graph>
				<!-- download the document (using cache) -->
				<apo:http-get name="digital-object">
					<p:with-option name="href" select="$object-uri"/>
				</apo:http-get>
				<p:for-each name="object-retrieved">
					<!-- TODO convert any HTTP errors to RDF and store them -->
					<p:iteration-source select="
						/c:response[@status='200']
							/c:body[@content-type=(
								'text/plain', 
								'text/html', 
								'application/xhtml+xml', 
								'application/pdf', 
								'application/msword', 
								'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
							)]
					"/>
				<!--
					<p:store href="object.xml"/>
					<p:identity><p:input port="source"><p:pipe step="digital-object" port="result"/></p:input></p:identity>
				-->
					<!-- perform NER on it, and convert the results to RDF -->
					<apo:recognise-named-entities name="mined-data">
						<p:with-option name="document-uri" select="$object-uri"/>
					</apo:recognise-named-entities>
					<!-- store the NER RDF -->
					<apo:store-graph>
						<p:with-option name="graph-uri" select="$object-uri"/>
					</apo:store-graph>
				</p:for-each>
			</p:for-each>
		</p:for-each>
	</p:declare-step>
	
	<p:declare-step type="apo:fix-hostnames-in-sitemap">
		<p:documentation>Fix errors in URLs caused by misconfiguration of Drupal sitemaps module</p:documentation>
		<p:input port="sitemap"/>
		<p:output port="sitemap-with-hostnames-fixed"/>
		<!-- update the text content of sitemap:loc elements to replace bogus site name with 'http://apo.org.au/', using regex subsitution -->
		<p:string-replace match="sitemap:loc/text()" replace="
			replace(
				., 
				'(http://http//apo001.prod.acquia-sites.com/)(.*)', 
				'http://apo.org.au/$2'
			)
		"/>
	</p:declare-step>
	
	
	<!-- sparql interface -->
	<p:declare-step type="apo:sparql-update" name="sparql-update">
		<p:option name="sparql-update-uri"/>
		<p:option name="query"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="sparql-update" select="$sparql-update"/>
			<p:with-param name="query" select="$query"/>
			<p:input port="template">
				<p:inline>
					<c:request href="{$sparql-update}" method="POST">
						<c:body content-type="application/sparql-update">{$query}</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
	</p:declare-step>
	
	<!-- delete graph -->
	<p:declare-step type="apo:delete-graph" name="delete-graph">
		<p:option name="graph-store" select=" 'http://localhost:8080/fuseki/dataset/data' "/>
		<p:option name="graph-uri" required="true"/>
		<p:template name="construct-deletion-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="template">
				<p:inline>
					<c:request method="DELETE" href="{$graph-store}?graph={encode-for-uri($graph-uri)}" detailed="true"/>
				</p:inline>
			</p:input>
			<p:input port="source">
				<p:empty/>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	
	<!-- store graph -->
	<p:declare-step type="apo:store-graph" name="store-graph">
		<p:input port="source"/>
		<p:option name="graph-store" select=" 'http://localhost:8080/fuseki/dataset/data' "/>
		<p:option name="graph-uri" required="true"/>
		<!-- execute an HTTP PUT to store the graph in the graph store at the location specified -->
		<p:template name="generate-put-request">
			<p:with-param name="graph-store" select="$graph-store"/>
			<p:with-param name="graph-uri" select="$graph-uri"/>
			<p:input port="source">
				<p:pipe step="store-graph" port="source"/>
			  </p:input>
			<p:input port="template">
				<p:inline>
					<c:request method="PUT" href="{$graph-store}?graph={encode-for-uri($graph-uri)}" detailed="true">
						<c:body content-type="application/rdf+xml">{ /* }</c:body>
					</c:request>
				</p:inline>
			</p:input>
		</p:template>
		<p:http-request/>
		<p:sink/>
	</p:declare-step>
	
</p:declare-step>
