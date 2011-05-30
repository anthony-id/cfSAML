<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<!--- 
	I think there are better ways to test this. 
	These tests may be brittle and depend too much on how the cert/keystore are generated. 
	--->
	<cffunction name="setup">
		<cfscript>
		var currentDirectory = getDirectoryFromPath(getCurrentTemplatePath());
		var keystoreFile = reREplace(currentDirectory,"tests[/|\\]","keystore.jks");
		keystore = createObject("component","cfSAML.src.Keystore").init(keystoreFile,"password","selfsigned");
		</cfscript>
	</cffunction>
	
	<cffunction name="testGetKey_returns_PrivateKey">
		<cfscript>
		//This test may be brittle depending on the certKey
		var algorithmId = keystore.getKey().getAlgorithmId().toString();
		var objectType = "sun.security." & lcase(algorithmId) & "." & algorithmId & "PrivateCrtKeyImpl";
				 
		assertTrue(IsInstanceOf(keystore.getKey(),objectType));
		</cfscript>
	</cffunction>
	
	<cffunction name="testgetCert_returnsCertificate" access="public" output="false">
		<cfscript>
		assertTrue(IsInstanceOf(keystore.getCert(),"sun.security.x509.X509CertImpl"));
		</cfscript>
	</cffunction>
	
	<cffunction name="getPublicKey" access="public" output="false">
		<cfscript>
		var algorithmId = keystore.getPublicKey().getAlgorithmId().toString();
		var objectType = "sun.security." & lcase(algorithmId) & "." & algorithmId & "PublicKeyImpl";
		
		assertTrue(IsInstanceOf(keystore.getPublicKey(),objectType));
		</cfscript>
	</cffunction>
	
</cfcomponent>