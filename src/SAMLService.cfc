<cfcomponent output="false">
	
	<cffunction name="getKeyStoreFile">
	</cffunction>

	<cffunction name="getKeyPassword">
	</cffunction>
	
	
	<!--- Genericised for Public Consumption --->
	<cffunction name="getSAML" output="false" access="public">
		<cfargument name="audience" type="string" required="true">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="attribs" type="struct" required="true">
		<cfargument name="issuer" type="string" required="false" default="https://#cgi.Server_Name#">
		<cfargument name="version" type="numeric" required="false" default="2">
		<cfscript>
		var samlData = 
			{NotBefore = DateFormat(DateConvert('local2utc',Now()),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',-1,Now())),'HH:mm:SSZ')
			,NotAfter = DateFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'YYYY-MM-DDT') & TimeFormat(DateConvert('local2utc',DateAdd('n',1,Now())),'HH:mm:SSZ')
   			,assertionId = createUUID()};
		var replaceString = "#chr(10)##chr(9)##chr(32)##chr(32)##chr(32)##chr(32)#";
		var samlAssertionXML = signSAML(createSAML(arguments.audience,arguments.nameId,arguments.attribs,samlData,arguments.issuer,arguments.version),samlData['assertionId'],arguments.version);
		var samlResponse = toBase64(replace(toString(samlAssertionXML),replaceString,"","ALL"), "utf-8");
		return samlResponse;
		</cfscript>
	</cffunction>
	
	<cffunction name="createSAML" output="false" access="private">
		<cfargument name="audience" type="string" required="true">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="attribs" type="struct" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfargument name="issuer" type="string" required="true">
		<cfargument name="version" type="numeric" required="false" default="2">
				
		<cfswitch expression = "#arguments.version#">
			<cfcase value="1">
				<cfreturn createVersion1SAML(arguments.nameId,arguments.samlMetaData,arguments.issuer)>
			</cfcase>
			<cfdefaultcase>
				<cfreturn createVersion2SAML(arguments.audience,arguments.nameId,arguments.attribs,samlMetaData)>
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
	<cffunction name="createVersion2SAML" output="false" access="private">
		<cfargument name="audience" type="string" required="true">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="attribs" type="struct" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfset var ssoData = structnew()>
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
				<saml:Issuer>https://#cgi.Server_Name#</saml:Issuer> <!--- TODO SET IN PROPERTIES, CONFIG OR AS VARIABLE! --->
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
					<!--- Attributes to pass to Service Provider in this case an Access ID.  --->
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
	
	<cffunction name="createVersion1SAML" output="false" access="public">
		<cfargument name="nameId" type="string" required="true">
		<cfargument name="samlMetaData" type="struct" require="true">
		<cfargument name="issuer" type="string" required="true">
		<cfset var ssoData = structnew()>
		<cfset var samlData = arguments.samlMetaData>
		<cfset var attrib = "">
		
		<cfoutput>
		<cfxml variable="samlAssertionXML"><samlp:Response 
			xmlns:samlp="urn:oasis:names:tc:SAML:1.0:protocol"
			ResponseID="#samlData['assertionId']#"
			MajorVersion="1" 
			MinorVersion="1"
			IssueInstant="#samlData['NotBefore']#"
			Recipient="https://test-sso.crmondemand.com/fed/sp/samlv11sso" 
		>
			<samlp:Status>
				<samlp:StatusCode Value="samlp:Success"></samlp:StatusCode>
			</samlp:Status>	
			<saml:Assertion 
				AssertionID="#createUUID()#"
				IssueInstant="#samlData['NotBefore']#" 
				Issuer="#arguments.issuer#" 
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
				<!--- Attribute Statements = Properties --->
			</saml:Assertion>
		</samlp:Response>
		</cfxml>
		</cfoutput>
		<cfreturn samlAssertionXML>
	</cffunction>
	
	<!--- TODO Refactor this into either a more friendly function or multiple functions   --->
	
	<cffunction name="signSAML" output="false" access="public">
		<cfargument name="samlAssert">
		<cfargument name="assertionId">
		<cfargument name="version" type="numeric" required="false" default="2">
		<cfscript>
		var samlAssertionXML = arguments.samlAssert;	
		//injest the xml 
		var samlAssertionElement = samlAssertionXML.getDocumentElement();
		var samlAssertionDocument = samlAssertionElement.GetOwnerDocument();
		var samlAssertion = samlAssertionDocument.getFirstChild();
		//create the Java Objects
		var SignatureSpecNS = CreateObject("Java", "org.apache.xml.security.utils.Constants").SignatureSpecNS;
		var	TransformsClass = CreateObject("Java","org.apache.xml.security.transforms.Transforms");
		var	SecInit = CreateObject("Java", "org.apache.xml.security.Init").Init().init();
		var fac = CreateObject("Java", "javax.xml.crypto.dsig.XMLSignatureFactory").getInstance("DOM");
		var XMLSignatureClass = CreateObject("Java", "org.apache.xml.security.signature.XMLSignature");
		//set up the signature 
		var sigType = XMLSignatureClass.ALGO_ID_SIGNATURE_RSA_SHA1;
		var signature = XMLSignatureClass.init(samlAssertionDocument, javacast("string",""), sigType);
		//var signature = "";
		var transformEnvStr = "";
		var transformOmitCommentsStr = "";
		var	transforms = "";
		var KeyStoreClass = CreateObject("Java" , "java.security.KeyStore");
		//injest your previously created keystore
		var ksfile = CreateObject("Java", "java.io.File").init(getKeyStoreFile());
		var inputStream = CreateObject("Java", "java.io.FileInputStream").init(ksfile);
		var ks = KeyStoreClass.getInstance("JKS");
		var keypw = getKeyPassword(); //TODO STORE IN CONFIG FILE!
		var key = "";
		var cert = "";
		var publickey = "";
		var conditionsNode = samlAssertionElement.getElementsByTagName('saml:Conditions');
		var assertionNode = samlAssertionElement.getElementsByTagName('saml:Assertion');
		var statusNode = samlAssertionElement.getElementsByTagName('samlp:Status');
		
		//set up signature transforms 
		transformEnvStr = TransformsClass.TRANSFORM_ENVELOPED_SIGNATURE;
		transformOmitCommentsStr = TransformsClass.TRANSFORM_C14N_EXCL_OMIT_COMMENTS;
				
		transforms = TransformsClass.init(assertionNode.item(0).getOwnerDocument());
		transforms.addTransform(transformEnvStr);
		transforms.addTransform(transformOmitCommentsStr);
		
		switch(arguments.version) {
			case "1":
				// Insert signature before statusNode
				samlAssertion.insertBefore(signature.getElement(),statusNode.item(0));
			break;
			default:
				// Insert signature AFTER issuer node
				assertionNode.item(0).insertBefore(signature.getElement(),conditionsNode.item(0));
			break;
		}
		
		// TODO SAMLName needs to be defined
		ks.load(inputStream,SAMLName);
		key = ks.getKey(SAMLName,keypw.toCharArray());
		cert = ks.getCertificate(SAMLName);
		publickey = cert.getPublicKey();
		//set up the signature 	
		signature.addDocument("###arguments.assertionId#",transforms);
		//optionally include the cert and public key 
		signature.addKeyInfo(cert);
		signature.addKeyInfo(publickey);
		signature.sign(key);
		return samlAssertionXML;
		</cfscript>
	</cffunction>
	
</cfcomponent>