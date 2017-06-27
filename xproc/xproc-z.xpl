<p:declare-step
	name="main"
	xmlns:p="http://www.w3.org/ns/xproc" version="1.0" 
	xmlns:c="http://www.w3.org/ns/xproc-step" 
	xmlns:apo="https://github.com/Conal-Tuohy/NER-RDF-Pipeline"
>
	<!-- The "source" input is the HTTP request -->
	<p:input port='source' primary='true'/>
	<!-- The "parameters" input port lists the environment parameters -->	
	<p:input port='parameters' kind='parameter' primary='true'/>
	<!-- The "result" output port is for our HTTP response -->
	<p:output port="result" primary="true" sequence="true"/>
	
	<!-- What URI did the browser request? -->
	<p:variable name="relative-request-uri" select="substring-after(/c:request/@href, '/xproc-z/')"/>
	<p:choose>
		<!-- "related" URI is a request for a list of documents related to the referrering document -->
		<p:when test="$relative-request-uri = 'related' ">
			<!-- The URI of the referring page is given by the "referer" (sic) HTTP header -->
			<p:variable name="referer" select="/c:request/c:header[@name='referer']/@value"/>
			<!-- Construct an HTTP request containing a SPARQL query that will return a list of related documents -->
			<p:xslt name="construct-sparql-query">
				<p:input port="stylesheet">
					<p:inline>
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
							<xsl:template match="/c:request">
								<xsl:variable name="sparql-query">
									<![CDATA[
									PREFIX foaf: <http://xmlns.com/foaf/0.1/>
									PREFIX dcterms: <http://purl.org/dc/terms/>
									SELECT 
										?relatedDigitalObjectTitle 
										?relatedPage 
										(count(?namedEntity) as ?namedEntitiesInCommon)
									WHERE {
										?digitalObject foaf:isPrimaryTopicOf ?page.
										?relatedDigitalObject foaf:isPrimaryTopicOf ?relatedPage.
										?digitalObject foaf:topic ?namedEntity. 
										?relatedDigitalObject foaf:topic ?namedEntity. 
										?relatedDigitalObject dcterms:title ?relatedDigitalObjectTitle
										FILTER(?relatedDigitalObject != ?digitalObject)
										FILTER(?page = <«current-page»>)
									} 
									GROUP BY ?relatedPage ?relatedDigitalObjectTitle 
									ORDER BY DESC(?namedEntitiesInCommon) 
									LIMIT 100
									]]>
								</xsl:variable>
								<!-- Specify an HTTP request to the SPARQL query server on localhost -->
								<c:request href="http://localhost:8080/fuseki/dataset/query" method="POST">
									<!-- HTTP content negotiation: demand results in XML format -->
									<c:header name="Accept" value="application/sparql-results+xml"/>
									<c:body content-type="application/sparql-query">
										<!-- Substitute the "referer" URI into our SPARQL query -->
										<!-- NB because this is running on a dev Drupal server, and the RDF metadata refers to the 
										production Drupal server, the referring page URI has a different hostname (i.e. not apo.org.au) -->
										<!-- so we strip off the start of the 'referer' URI and replace it with "http://apo.org.au/" first. -->
										<xsl:value-of select="
											replace(
												$sparql-query, 
												'«current-page»',
												concat(
													'http://apo.org.au/node/',
													substring-after(
														/c:request/c:header[@name='referer']/@value,
														'/node/'
													)
												)
											)
										"/>
									</c:body>
								</c:request>
							</xsl:template>
						</xsl:stylesheet>
					</p:inline>
				</p:input>
			</p:xslt>
			<!-- Send the SPARQL query to the server and get results -->
			<p:http-request/>
			<!-- Use an XSLT to format the XML query results as an HTML list -->
			<p:xslt name="format-results-as-table-of-links">
				<p:with-param name="referer" select="$referer"/>
				<p:input port="stylesheet">
					<p:inline>
						<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
							xmlns:sparql="http://www.w3.org/2005/sparql-results#">
							<xsl:param name="referer"/>
							<xsl:template match="/sparql:sparql">
								<!-- HTTP response 200 = "OK" -->
								<c:response status="200">
									<!-- A hint for the browser and any intermediary caches about caching this response: -->
									<!-- The content we are serving up depends not just on the request URI, but ALSO -->
									<!-- on the value of the "Referer" header which the browser sent. -->
									<c:header name="Vary" value="Referer"/>
									<c:body content-type="application/xhtml+xml">
										<html xmlns="http://www.w3.org/1999/xhtml">
											<head>
												<title>Related</title>
												<style type="text/css">
													* { 
														font-family: sans-serif;
													}
													a {
														color: rgb(7, 109, 139);
														text-decoration: none;
													}
													a:hover {
														text-decoration: underline; 
													}
												</style>
											</head>
											<body>
												<xsl:choose>
													<xsl:when test="sparql:results/sparql:result/sparql:binding[@name='relatedPage']">
														<ul>
															<xsl:for-each select="sparql:results/sparql:result">
																<xsl:variable name="page" select="sparql:binding[@name='relatedPage']/sparql:uri"/>
																<xsl:variable name="title" select="sparql:binding[@name='relatedDigitalObjectTitle']/sparql:literal"/>
																<!-- Again, we have to substitute the base URI of the dev Drupal site back onto these URIs, -->
																<!-- which would otherwise point to pages on the production Drupal site. -->
																<li><a target="_parent" href="{
																	concat(
																		substring-before($referer, '/node/'),
																		'/node/',
																		substring-after($page, '/node/')
																	)
																}"><xsl:value-of select="$title"/></a></li>
															</xsl:for-each>
														</ul>
													</xsl:when>
													<xsl:otherwise>
														<!-- SPARQL query found no related documents -->
														<p>No related documents found</p>
													</xsl:otherwise>
												</xsl:choose>
											</body>
										</html>
									</c:body>
								</c:response>
							</xsl:template>
						</xsl:stylesheet>
					</p:inline>
				</p:input>
			</p:xslt>
		</p:when>
		<p:otherwise>
			<!-- The browser requested some other URI (not "related") -->
			<p:identity>
				<p:input port="source">
					<p:inline>
						<c:response status="404">
							<c:body content-type="application/xhtml+xml">
								<html xmlns="http://www.w3.org/1999/xhtml">
									<head>
										<title>Not Found</title>
									</head>
									<body>
										<h1>Not Found</h1>
										<p>The requested resource was not found.</p>
									</body>
								</html>
							</c:body>
						</c:response>
					</p:inline>
				</p:input>
			</p:identity>
		</p:otherwise>
	</p:choose>

</p:declare-step>
