<cfcomponent output="false">
	
	<cffunction name="init" output="false" access="public">
		<cfscript>
		/* 
		Could use JavaLoader to help with this or put xml-sec jar file in {coldfusion_home}/lib
		if in /lib it requires a ColdFusion restart
		*/
		variables.SignatureSpecNS = CreateObject("Java", "org.apache.xml.security.utils.Constants").SignatureSpecNS;
		variables.XMLSignatureClass = CreateObject("Java", "org.apache.xml.security.signature.XMLSignature");
		
		variables.TransformsClass = CreateObject("Java","org.apache.xml.security.transforms.Transforms");
		variables.transformEnvStr = variables.TransformsClass.TRANSFORM_ENVELOPED_SIGNATURE;
		variables.transformOmitCommentsStr = variables.TransformsClass.TRANSFORM_C14N_EXCL_OMIT_COMMENTS;
		
		return this;
		</cfscript>
	</cffunction>
	<!--- Keystore is best composed into this object usign DI such as ColdSpring, but can be done manually --->	
	<cffunction name="setKeystore" access="public" output="false" hint="This sets the keystore object composed into the SAMLService">
	 	<cfargument name="keystoreObject" required="true" type="Keystore">
	 	<cfset variables.keystore = arguments.keystoreObject>
	</cffunction>
	
	<cffunction name="getKeystore" access="public" output="false">
	  	<cfreturn variables.keystore>
	</cffunction>
	
	<cffunction name="setIssuer" output="false" access="public">
		<cfargument name="issuer" required="true" type="string" hint="The URI of the issuer. Usually the domain from where this is called">
		<cfset variables.issuer = arguments.issuer>
	</cffunction>
	
	<cffunction name="getIssuer" output="false" access="public">
		<cfreturn variables.issuer>
	</cffunction>
		
	<cffunction name="setSAMLVersion" output="false" access="public">
		<cfargument name="samlVersion" required="true" type="numeric" hint="The version of SAML used. Valid options are 1 or 2">
		<cfset variables.samlVersion = arguments.samlVersion>
	</cffunction>
	
	<cffunction name="getSAMLVersion" output="false" access="public">
		<cfreturn variables.samlVersion>
	</cffunction>
						
	<cffunction name="getSAML" output="false" access="public" hint="Public interface to create SAML packet">
		<cfargument name="audience" type="string" required="true" hint="URI of SAML consumer. Usually a service provider">
		<cfargument name="nameId" type="string" required="true" hint="Value for the nameId node. How the Subject (user) is identified by Identity Provider (us)">
		<cfargument name="attribs" type="struct" required="true" hint="Additional attributes to pass to service - e.g. firstname, lastname, etc.">
		<cfscript>
		/* 
			Default strategy is to use 1 minute before and 1 minute after now, with a UUID for the assertionID	
			This may be better split out and made more flexible in the future
		*/
		var samlData = 
			{NotBefore = DateFormat(DateConvert('local2utc',Now()),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',-1,Now())),'HH:mm:SSZ')
			,NotAfter = DateFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'HH:mm:SSZ')
   			,assertionId = createUUID()};
   		// This string shows up in the signedSAML and needs to be removed	
		var replaceString = "#chr(10)##chr(9)##chr(32)##chr(32)##chr(32)##chr(32)#";
		// Create the unsigned SAML
		var SAML = createSAML(arguments.audience,arguments.nameId,arguments.attribs,samlData);
		// Now add the signature using the keystore - this is still plain XML
		var samlAssertionXML = signSAML(SAML,samlData['assertionId']);
		// Convert SAML to base64 for POST operations removing control characters
		var samlResponse = toBase64(replace(toString(samlAssertionXML),replaceString,"","ALL"), "utf-8");
		return samlResponse;
		</cfscript>
	</cffunction>
	
	<cffunction name="createSAML" output="false" access="private">
		<cfargument name="audience" type="string" required="true">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="attribs" type="struct" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfscript>
		// default is to create version 2 SAML				
		switch (getSAMLVersion()){
			case "1":
				return createVersion1SAML(arguments.nameId,arguments.samlMetaData,arguments.audience);
			break;
			default:
				return createVersion2SAML(arguments.audience,arguments.nameId,arguments.attribs,samlMetaData);
			default;
		}
		</cfscript>
	</cffunction>
	
	<cffunction name="createVersion2SAML" output="false" access="private">
		<cfargument name="audience" type="string" required="true">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="attribs" type="struct" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfset var ssoData = {}>
		<cfset var samlData = arguments.samlMetaData>
		<cfset var attrib = "">
		
		<cfoutput>
		<cfxml variable="samlAssertionXML"><!DOCTYPE Response [<!ATTLIST saml:Assertion ID ID ##IMPLIED>]><samlp:Response 
			ID="#createUUID()#" 
			IssueInstant=""
			xmlns:samlp="urn:oasis:names:tc:SAML:2.0:protocol" 
			xmlns:ds="http://www.w3.org/2000/09/xmldsig#chr(35)#" 
			xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
			xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" 
			Version="2.0" 
		>
		<samlp:Status>
				<samlp:StatusCode Value="samlp:Success"/>
			</samlp:Status>	
			<saml:Assertion 
				ID="#samlData['assertionId']#" 
				IssueInstant="#samlData['NotBefore']#" 
				Version="2.0"
				xmlns:saml="urn:oasis:names:tc:SAML:2.0:assertion" 
				xmlns:ds="http://www.w3.org/2000/09/xmldsig#chr(35)#" 
				xmlns:xenc="http://www.w3.org/2001/04/xmlenc#chr(35)#" 
				xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
				<saml:Issuer>#getIssuer()#</saml:Issuer> 
				<saml:Conditions NotAfter="#samlData['NotAfter']#" NotBefore="#samlData['NotBefore']#">
					<!--- Service Provider(s) --->
					<saml:AudienceRestriction>
						<saml:Audience>#arguments.audience#</saml:Audience> 
					</saml:AudienceRestriction>
				</saml:Conditions>
				<saml:AuthnStatement AuthnInstant="#samlData['NotBefore']#" SessionIndex="1234567890">
					<!--- How the user was authenticated at IdP --->
					<saml:AuthContext>
						<saml:AuthnContextClassRef>urn:oasis:names:tc:SAML:2.0:ac:classes:Password</saml:AuthnContextClassRef>
					</saml:AuthContext>
				</saml:AuthnStatement>
				<!--- Attribute Statements = Properties --->
				<saml:AttributeStatement>
					<saml:Subject>
						<!--- How the Subject (user) is identified by Identity Provider (us) --->
						<saml:NameID>#trim(xmlFormat(arguments.nameId))#</saml:NameID>
						<saml:SubjectConfirmation Method="urn:oasis:names:tc:SAML:2.0:cm:bearer"/>
					</saml:Subject>
					<!--- 
					Attributes to pass to Service Provider. 
					Can be any number of arbitrary name value pairs that the SP is expecting  
					--->
					<cfloop collection="#arguments.attribs#" item="attrib">
					<saml:Attribute Name="#attrib#">
						<saml:AttributeValue>#trim(xmlFormat(arguments.attribs[attrib]))#</saml:AttributeValue>
					</saml:Attribute>	
					</cfloop>	
				</saml:AttributeStatement>
			</saml:Assertion>
		</samlp:Response>
		</cfxml>
		</cfoutput>
		<cfreturn samlAssertionXML>
	</cffunction>
	
	<cffunction name="createVersion1SAML" output="false" access="private">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfargument name="recipient" type="string" required="true" hint="The target of the SAML post">
		<cfset var ssoData = {}>
		<cfset var samlData = arguments.samlMetaData>
		<cfset var attrib = "">
		
		<cfoutput>
		<cfxml variable="samlAssertionXML"><samlp:Response 
			xmlns:samlp="urn:oasis:names:tc:SAML:1.0:protocol"
			ResponseID="#samlData['assertionId']#"
			MajorVersion="1" 
			MinorVersion="1"
			IssueInstant="#samlData['NotBefore']#"
			Recipient="#arguments.recipient#"
			>
			<samlp:Status>
				<samlp:StatusCode Value="samlp:Success"></samlp:StatusCode>
			</samlp:Status>	
			<saml:Assertion 
				AssertionID="#createUUID()#"
				IssueInstant="#samlData['NotBefore']#" 
				Issuer="#getIssuer()#" 
				MajorVersion="1" 
				MinorVersion="1" 
				xmlns:saml="urn:oasis:names:tc:SAML:1.0:assertion" 
				xmlns:samlp="urn:oasis:names:tc:SAML:1.0:protocol">
				<saml:Conditions NotOnOrAfter="#samlData['NotAfter']#" NotBefore="#samlData['NotBefore']#"/>
				<saml:AuthenticationStatement AuthenticationInstant="#samlData['NotBefore']#" AuthenticationMethod="urn:oasis:names:tc:SAML:1.0:am:password" >
					<!--- How the user was authenticated at IdP --->
					<saml:Subject>
						<!--- How the Subject (user) is identified by Identity Provider (us) --->
						<saml:NameIdentifier>#trim(xmlFormat(arguments.nameId))#</saml:NameIdentifier>
						<saml:SubjectConfirmation>
							<saml:ConfirmationMethod>urn:oasis:names:tc:SAML:1.0:cm:bearer</saml:ConfirmationMethod>
						</saml:SubjectConfirmation>
					</saml:Subject>
				</saml:AuthenticationStatement>
				<!--- 
				Attribute Statements = Properties 
				TODO - research SAML 1 attribute statement block. Likely very similar to v2, but I haven't had a chance to work with it 
				--->
			</saml:Assertion>
		</samlp:Response>
		</cfxml>
		</cfoutput>
		<cfreturn samlAssertionXML>
	</cffunction>
	
	<cffunction name="signSAML" output="false" access="private">
		<cfargument name="samlAssert">
		<cfargument name="assertionId">
		<cfscript>
		var samlAssertionXML = arguments.samlAssert;	
		//injest the xml 
		var samlAssertionElement = samlAssertionXML.getDocumentElement();
		var samlAssertionDocument = samlAssertionElement.GetOwnerDocument();
		var samlAssertion = samlAssertionDocument.getFirstChild();
							
		var conditionsNode = samlAssertionElement.getElementsByTagName('saml:Conditions');
		var assertionNode = samlAssertionElement.getElementsByTagName('saml:Assertion');
		var statusNode = samlAssertionElement.getElementsByTagName('samlp:Status');
		
		var signature = getSignature(samlAssertionDocument);
		
		//set up signature transforms 
		var transforms = variables.TransformsClass.init(assertionNode.item(0).getOwnerDocument());
		
		transforms.addTransform(variables.transformEnvStr);
		transforms.addTransform(variables.transformOmitCommentsStr);
				
		switch(getSAMLVersion()) {
			case "1":
				// Insert signature before statusNode
				samlAssertion.insertBefore(signature.getElement(),statusNode.item(0));
			break;
			default:
				// Insert signature AFTER issuer node
				assertionNode.item(0).insertBefore(signature.getElement(),conditionsNode.item(0));
			break;
		}
		
		//set up the signature
		signature.addDocument("###arguments.assertionId#",transforms);
		//optionally include the cert and public key 
		signature.addKeyInfo(getKeystore().getCert());
		signature.addKeyInfo(getKeystore().getPublickey());
		signature.sign(getKeystore().getPrivateKey());
		return samlAssertionXML;
		</cfscript>
	</cffunction>
	 
	<cffunction name="getSignature" access="private" output="false" hint="Returns signature object initialized with SAML document">
		<cfargument name="assertionDocument" required="true" hint="The owner document for signature consumption">
		<cfscript>
		/* 
		TODO - allow signature type to be set as property or variable. 
		This is how the cert in the keystore was generated.
		*/
		var sigType = variables.XMLSignatureClass.ALGO_ID_SIGNATURE_RSA_SHA1;
		return variables.XMLSignatureClass.init(arguments.assertionDocument, javacast("string",""), sigType);
		</cfscript>
	</cffunction>	
	
</cfcomponent>