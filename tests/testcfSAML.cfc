<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<cffunction name="setup">
		<cfset SAMLSvc = createOBject("component","cfSAML.src.SAMLService")>
	</cffunction>
	
	<cffunction name="testGetKeyStoreFile_returns_string">
	</cffunction>
	
</cfcomponent>