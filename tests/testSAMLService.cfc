<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<cffunction name="setup">
		<cfset SAMLSvc = createObject("component","cfSAML.src.SAMLService")>
	</cffunction>
	
	<cffunction name="testGetIssuer_returns_string">
	</cffunction>
	
</cfcomponent>