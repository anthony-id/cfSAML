<cfcomponent extends="mxunit.framework.TestCase" output="false">
	<cffunction name="setup">
		<cfscript>
		var currentDirectory = getDirectoryFromPath(getCurrentTemplatePath());
		var keystoreFile = reREplace(currentDirectory,"tests[/|\\]","keystore.jks");
		var keystore = createObject("component","cfSAML.src.Keystore").init(keystoreFile,"password","selfsigned");	
		SAMLSvc = createObject("component","cfSAML.src.SAMLService").init();
		SAMLSvc.setKeystore(keystore);
		SAMLSvc.setIssuer("https://test.issuer.com");
		</cfscript>
	</cffunction>
	
	<cffunction name="testCreateVersion1SAML_returns_valid_xml">
		<cfscript>
		makePublic(SAMLSvc,"createVersion1SAML");
		assertTrue(isXML(SAMLSvc.createVersion1SAML("aNameId",getSAMLMetaData(),"https://the.recipient.com")));
		// Could insert xPath assertions as well...but need to be GOOD tests. 
		</cfscript>
	</cffunction>
	
	<cffunction name="testCreateVersion2SAML_returns_valid_xml">
		<cfscript>
		makePublic(SAMLSvc,"createVersion2SAML");
		assertTrue(isXML(SAMLSvc.createVersion2SAML("https://the.audience.com","aNameId",{},getSAMLMetaData())));
		// Could insert xPath assertions as well...but need to be GOOD tests. 
		</cfscript>
	</cffunction>
	
	<cffunction name="testSignSAML_returns_valid_xml">
		<cfscript>
		var samlData = getSAMLMetaData();	
		makePublic(SAMLSvc,"createVersion1SAML");
		makePublic(SAMLSvc,"signSAML");
		SAMLSvc.setSAMLVersion(1);
		v1SAML = SAMLSvc.createVersion1SAML("aNameId",samlData,"https://the.audience.com");
		assertTrue(isXML(SAMLSvc.signSAML(v1SAML,samlData['assertionId'])));
		
		makePublic(SAMLSvc,"createVersion2SAML");
		SAMLSvc.setSAMLVersion(2);
		v2SAML = SAMLSvc.createVersion2SAML("https://the.audience.com","aNameId",{},samlData);
		assertTrue(isXML(SAMLSvc.signSAML(v2SAML,samlData['assertionId'])));
		
		// Could insert xPath assertions as well...but need to be GOOD tests. 
		</cfscript>
	</cffunction>
			
	<cffunction name="testCreateSAML_returns_valid_xml">
		<cfscript>
		makePublic(SAMLSvc,"createSAML");
		SAMLSvc.setSAMLVersion(1);
		assertTrue(isXML(SAMLSvc.CreateSAML("https://the.audience.com","aNameId",{},getSAMLMetaData())));	
		
		SAMLSvc.setSAMLVersion(2);	
		assertTrue(isXML(SAMLSvc.CreateSAML("https://the.audience.com","aNameId",{},getSAMLMetaData())));
		</cfscript>
	</cffunction>
	
	<cffunction name="testGetSAML_returns_Base64Encoded_SAML" access="public" output="false">
		<cfscript>
		SAMLSvc.setSAMLVersion(1);	
		debug(SAMLSvc.getSAML("https://the.audience.com","aNameId",{}));	
			
		SAMLSvc.setSAMLVersion(2);	
		debug(SAMLSvc.getSAML("https://the.audience.com","aNameId",{}));
			
		</cfscript>
	</cffunction>
	
	<cffunction name="getSAMLMetaData" access="private" output="false">
		<cfscript>
		var samlData = 
			{NotBefore = DateFormat(DateConvert('local2utc',Now()),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',-1,Now())),'HH:mm:SSZ')
			,NotAfter = DateFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'HH:mm:SSZ')
   			,assertionId = createUUID()};
		return samlData;
		</cfscript>
	</cffunction>
	
</cfcomponent>