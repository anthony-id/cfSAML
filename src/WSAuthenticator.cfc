<!---
NAME:		WSAuthenticator.cfc
OVERVIEW:	Adds WSAuthentication to SOAP Requests, Sends SOAP request and returns result
AUTHOR: 	Anthony Israel-Davis
DATE:		05/12/2010

NOTES:
=====================================================
This requires the following jar files in the [cf_home]/lib directories:

xmlsec-1.4.2.jar
wss4j-1.5.8.jar

Updated versions of the jars should be tested before dropping them into production
====================================================
--->
<cfcomponent output="false">
	<!--- 
	THE FOLLOWING ARE REQUIRED FOR SENDING THE SOAP REQUEST
	<cfhttpparam type="Header" name="Accept-Encoding" value="deflate;q=0">
	<cfhttpparam type="Header" name="TE" value="deflate;q=0"> 
		
	EXAMPLE	
	<cfhttp url="https://some.url.com/rpc/soap/SomeService" method="POST" result="result" >
		<cfhttpparam type="Header" name="Accept-Encoding" value="deflate;q=0">
		<cfhttpparam type="Header" name="TE" value="deflate;q=0"> 
		
		
		<cfhttpparam type="header" name="SOAPAction" value="""SomeSoapAction""">
		<cfhttpparam type="xml" value="#toString(xmlParse(soapEnvelope))#"/>
	</cfhttp>
	 --->
	
	<cffunction name="init" access="public" output="false">
		<cfreturn this>
	</cffunction>
	
	<cffunction name="addWSAuthentication"  access="public" output="false" hint="I sign SOAP envelope using WS Authentication">
		<cfargument name="soapEnvelope" type="string" required="true">
		<cfargument name="username" type="string" required="true">
		<cfargument name="password" type="string" required="false">
		<cfscript>
		// Create Java Objects from xmlsec and wss4j
		var	WSConstants = CreateObject("Java","org.apache.ws.security.WSConstants");
		var msg = CreateObject("Java","org.apache.ws.security.message.WSSAddUsernameToken");
		// Get Soap Envlope document for Java processing
		var soapEnv = arguments.soapEnvelope;
		var env = soapEnv.getDocumentElement();
		var e = "";
		// Set Password type to TEXT (default is DIGEST)
		msg.setPasswordType(WSConstants.PASSWORD_TEXT);
		// Create WS-Security SOAP header using the build method from WSAddUsernameToken
		e = msg.build(env.GetOwnerDocument(),arguments.username,arguments.password);
		// Add the Nonce and Created elements
		msg.addNonce(e);
		msg.addCreated(e);
		// Return the secure xml object 
		return soapEnv;
		</cfscript>
	</cffunction>
	
	<cffunction name="sendSoapRequest" access="public" output="false" hint="I send the SOAP request off retrun the SOAP response">
		<cfargument name="endpoint" type="string" required="true">
		<cfargument name="soapEnvelope" type="any" required="true">
		<cfargument name="soapAction" type="string" required="false" default="">
		<cfset var result = "">
		<cfset var soapEnv = "">
		<!--- <cfset getErrorHandler().handleError(arguments)> --->
		<!--- <cfset soapEnv = addWSAuthentication(arguments.soapEnvelope)> --->
		<cfhttp url="#arguments.endpoint#" method="POST" result="result" >
			<cfhttpparam type="Header" name="Accept-Encoding" value="deflate;q=0">
			<cfhttpparam type="Header" name="TE" value="deflate;q=0"> 
			<cfhttpparam type="header" name="SOAPAction" value="""#arguments.soapAction#""">
			<cfhttpparam type="xml" value="#toString(xmlParse(arguments.soapEnvelope))#"/>
		</cfhttp>
		
		<cfreturn result.fileContent>		
	</cffunction>
	

</cfcomponent>