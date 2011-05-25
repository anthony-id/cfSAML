<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<cffunction name="setup">
		<cfset keystore = createObject("component","cfSAML.src.Keystore")>
		<!--- <cfset kestore.init(keystoreFile,keyPass,certificateAlias)> --->
	</cffunction>
	
	<cffunction name="testGetKeyStoreFile_returns_string">
	</cffunction>
	
</cfcomponent>