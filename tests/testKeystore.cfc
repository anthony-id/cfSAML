<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<cffunction name="setup">
		<cfscript>
		var currentDirectory = getDirectoryFromPath(getCurrentTemplatePath());
		var keystoreFile = reREplace(currentDirectory,"tests[/|\\]","keystore.jks");
		keystore = createObject("component","cfSAML.src.Keystore").init(keystoreFile,"password","selfsigned");
		</cfscript>
	</cffunction>
	
	<cffunction name="testGetKey_returns_certKey">
		<cfscript>
		//This test may be brittle depending on the certKey
		assertTrue(IsInstanceOf(keystore.getKey(),"org.bouncycastle.jce.provider.JCERSAPrivateCrtKey"))
		</cfscript>
	</cffunction>
	
</cfcomponent>