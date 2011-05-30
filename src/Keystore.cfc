<cfcomponent output="false" hint="This object retrieves the keystore certificate data">
	<cffunction name="init" output="false" access="public">
		<cfargument name="keystoreFile" required="true" type="string" hint="The absolute file path to the keystore including the filename">
		<cfargument name="keyPass" required="true" type="string" hint="The password for the keystore">
		<cfargument name="certificateAlias" required="true" type="string" hint="The alias of the certificate in the keystore to use">
		<cfscript>
		var ksfile = CreateObject("Java", "java.io.File").init(arguments.keystoreFile);
		var inputStream = CreateObject("Java", "java.io.FileInputStream").init(ksfile);
		var KeyStoreClass = CreateObject("Java" , "java.security.KeyStore");
		var keystore = KeyStoreClass.getInstance("JKS"); // JKS is the keystore type - may be variable
		
		keystore.load(inputStream,arguments.keyPass.toCharArray());
		variables.key = keystore.getKey(arguments.certificateAlias,arguments.keyPass.toCharArray());
		variables.cert = keystore.getCertificate(arguments.certificateAlias);
		variables.publickey = variables.cert.getPublicKey();	
			
		return this;
		</cfscript>
	</cffunction>
	
	<cffunction name="getPrivateKey" access="public" output="false">
		<cfreturn variables.key>
	</cffunction>
	
	<cffunction name="getCert" access="public" output="false">
		<cfreturn variables.cert>
	</cffunction>
	
	<cffunction name="getPublicKey" access="public" output="false">
		<cfreturn variables.publickey>
	</cffunction>
</cfcomponent>