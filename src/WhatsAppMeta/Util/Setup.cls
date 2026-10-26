/// One-time setup helpers. The token is passed in at the terminal, never stored in source.
Class WhatsAppMeta.Util.Setup
{

/// Create the client SSL/TLS configuration used by the adapter.
ClassMethod CreateSSLConfig(pName As %String = "WhatsApp") As %Status
{
	New $Namespace
	Set $Namespace = "%SYS"
	Return:(##class(Security.SSLConfigs).Exists(pName)) $$$OK
	Return ##class(Security.SSLConfigs).Create(pName)
}

/// Store the Meta access token as an Interoperability credential. Run in the production namespace.
ClassMethod SetToken(pToken As %String, pId As %String = "WhatsApp") As %Status
{
	Return ##class(Ens.Config.Credentials).SetCredential(pId, "meta", pToken, 1)
}

/// Store the webhook secrets as Interoperability credentials. Run in the production namespace.
/// pVerifyToken is any string you choose and also enter in the Meta webhook setup;
/// pAppSecret is the App Secret from Meta (App settings, Basic).
ClassMethod SetSecrets(pVerifyToken As %String, pAppSecret As %String) As %Status
{
	Set SC = ##class(Ens.Config.Credentials).SetCredential("WhatsAppVerify", "meta", pVerifyToken, 1)
	Return:($$$ISERR(SC)) SC
	Return ##class(Ens.Config.Credentials).SetCredential("WhatsAppSecret", "meta", pAppSecret, 1)
}

/// Role granted to the webhook web application.
Parameter ROLENAME = "WhatsAppWebhook";

/// IPM install hook (module.xml): only the outbound SSL config. The webhook endpoint
/// is never created automatically; it needs CreateWebApp() and the user's consent.
ClassMethod OnInstall() As %Status
{
	Set SC = ..CreateSSLConfig()
	Return:($$$ISERR(SC)) SC
	Write !, "iris-whatsapp-adapter installed in namespace ", $Namespace, ". Next steps:", !
	Write "  1. do ##class(WhatsAppMeta.Util.Setup).SetToken(""<Meta access token>"")", !
	Write "  2. System Default Setting PhoneNumberId on WhatsAppMeta.Operation.SendMessage", !
	Write "  3. Inbound only: SetSecrets(""<verify token>"",""<App Secret>""), then CreateWebApp()", !
	Write "See the README for details.", !
	Return $$$OK
}

/// Create (or update) the unauthenticated web application Meta calls, plus the role it runs with.
/// The role's resources are looked up from the namespace's own databases, never guessed.
/// Prints the planned changes and asks for confirmation; nothing changes unless the answer is "y".
/// Without a terminal to answer, it aborts. Scripted installs pass pConfirmed = 1 to skip the
/// question; the plan is still printed.
ClassMethod CreateWebApp(pPath As %String = "/whatsapp", pNamespace As %String = {$Namespace}, pConfirmed As %Boolean = 0) As %Status
{
	New $Namespace
	Set $Namespace = "%SYS"
	Set SC = ..PlanResources(pNamespace, .Grant, .Shared)
	Return:($$$ISERR(SC)) SC

	Set Resources = ""
	Write !, "The WhatsApp webhook needs the following changes on this instance:", !
	Write "  1. Role ", ..#ROLENAME, " with:", !
	Set Resource = ""
	For {
		Set Resource = $Order(Grant(Resource), 1, Permission)
		Quit:(Resource = "")
		Set Resources = Resources_$Select(Resources = "": "", 1: ",")_Resource_":"_Permission
		Write "       ", Resource, ":", Permission, ?45, "(", Grant(Resource, "Why"), ")", !
	}
	Write "  2. Web application ", pPath, $Select(##class(Security.Applications).Exists(pPath): " (update)", 1: " (new)"), !
	Write "       namespace ", pNamespace, ", dispatch WhatsAppMeta.API.Webhook", !
	Write "       UNAUTHENTICATED: anyone who can reach this URL can call it.", !
	Write "       Requests are rejected unless signed with your Meta App Secret.", !
	Set Resource = ""
	For {
		Set Resource = $Order(Shared(Resource), 1, Others)
		Quit:(Resource = "")
		Write "  WARNING: ", Resource, " also protects ", Others, "; ", pPath, " can access them.", !
	}

	If 'pConfirmed {
		Write "Apply these changes? (y/N) "
		// A timeout or a missing terminal leaves Answer empty, which aborts
		Set Answer = ""
		Read Answer:60
		Set Confirmed = ($ZConvert($ZStrip(Answer, "<>WC"), "L") = "y")
		Write !
		If 'Confirmed {
			Write "Aborted. Nothing was changed.", !
			Return $$$ERROR($$$GeneralError, "CreateWebApp aborted by user; nothing was changed")
		}
	}

	If ##class(Security.Roles).Exists(..#ROLENAME) {
		Set RoleProperties("Resources") = Resources
		Set SC = ##class(Security.Roles).Modify(..#ROLENAME, .RoleProperties)
	} Else {
		Set SC = ##class(Security.Roles).Create(..#ROLENAME, "WhatsApp webhook web application", Resources)
	}
	Return:($$$ISERR(SC)) SC

	Set Properties("NameSpace") = pNamespace
	Set Properties("DispatchClass") = "WhatsAppMeta.API.Webhook"
	Set Properties("Enabled") = 1
	Set Properties("AutheEnabled") = 64
	Set Properties("MatchRoles") = ":"_..#ROLENAME
	Set Properties("Description") = "WhatsApp Cloud API webhook"
	If ##class(Security.Applications).Exists(pPath) {
		Set SC = ##class(Security.Applications).Modify(pPath, .Properties)
	} Else {
		Set SC = ##class(Security.Applications).Create(pPath, .Properties)
	}
	Return:($$$ISERR(SC)) SC
	Write "Done. ", pPath, " is live in namespace ", pNamespace, ".", !
	Return $$$OK
}

/// Delete the webhook web application and its role. Removing exposure needs no confirmation.
ClassMethod RemoveWebApp(pPath As %String = "/whatsapp") As %Status
{
	New $Namespace
	Set $Namespace = "%SYS"
	If ##class(Security.Applications).Exists(pPath) {
		Set SC = ##class(Security.Applications).Delete(pPath)
		Return:($$$ISERR(SC)) SC
		Write "Removed web application ", pPath, !
	}
	If ##class(Security.Roles).Exists(..#ROLENAME) {
		Set SC = ##class(Security.Roles).Delete(..#ROLENAME)
		Return:($$$ISERR(SC)) SC
		Write "Removed role ", ..#ROLENAME, !
	}
	Return $$$OK
}

/// Work out the role's resources from where the namespace's code, data and credential
/// secrets actually live. Grant(resource) = permission, Grant(resource, "Why") = reason.
/// Shared(resource) = other databases protected by the same resource. Run in %SYS.
ClassMethod PlanResources(pNamespace As %String, Output pGrant, Output pShared) As %Status [ Private ]
{
	Kill pGrant, pShared
	Set SC = ##class(Config.Namespaces).Get(pNamespace, .NamespaceProperties)
	Return:($$$ISERR(SC)) SC

	// Code: read only, to load the dispatch class and the production's classes
	Set SC = ..AddDatabase(NamespaceProperties("Routines"), "R", "code: load the classes", .pGrant, .Databases)
	Return:($$$ISERR(SC)) SC
	// Data: Interoperability writes messages and queues here
	Set SC = ..AddDatabase(NamespaceProperties("Globals"), "RW", "data: messages and queues", .pGrant, .Databases)
	Return:($$$ISERR(SC)) SC
	// Secondary: credential passwords (^Ens.SecondaryData), read only
	Set Destination = ##class(%SYS.Namespace).GetGlobalDest(pNamespace, "Ens.SecondaryData")
	Set Directory = $Piece(Destination, "^", $Length(Destination, "^"))
	Set SC = ..AddDatabase(..DatabaseName(Directory), "R", "read the webhook secrets", .pGrant, .Databases)
	Return:($$$ISERR(SC)) SC
	Set pGrant("%Ens_Credentials") = "R"
	Set pGrant("%Ens_Credentials", "Why") = "required to read credential passwords"

	// Flag resources that also protect databases outside this namespace's set
	Set Result = ##class(%ResultSet).%New("Config.Databases:List")
	Set SC = Result.Execute("*")
	Return:($$$ISERR(SC)) SC
	While Result.Next() {
		Set Name = Result.Get("Name")
		Continue:($Data(Databases(Name)))
		Set Resource = ..DatabaseResource(Name)
		Continue:((Resource = "") || ('$Data(pGrant(Resource))))
		Set pShared(Resource) = $Get(pShared(Resource))_$Select($Get(pShared(Resource)) = "": "", 1: ", ")_Name
	}
	Return $$$OK
}

/// Add one database's resource to pGrant; RW wins over R when a resource repeats.
ClassMethod AddDatabase(pName As %String, pPermission As %String, pWhy As %String, ByRef pGrant, ByRef pDatabases) As %Status [ Private ]
{
	Set Resource = ..DatabaseResource(pName)
	Return:(Resource = "") $$$ERROR($$$GeneralError, "Cannot find the resource of database '"_pName_"'")
	Set pDatabases(pName) = ""
	If $Get(pGrant(Resource)) '= "RW" {
		Set pGrant(Resource) = pPermission
		Set pGrant(Resource, "Why") = pWhy
	}
	Return $$$OK
}

/// Resource protecting a database, by database name. Run in %SYS.
ClassMethod DatabaseResource(pName As %String) As %String [ Private ]
{
	Return:($$$ISERR(##class(Config.Databases).Get(pName, .Properties))) ""
	Set Database = ##class(SYS.Database).%OpenId(Properties("Directory"))
	Return $Select($IsObject(Database): Database.ResourceName, 1: "")
}

/// Database name for a directory, or "" if none matches. Run in %SYS.
ClassMethod DatabaseName(pDirectory As %String) As %String [ Private ]
{
	Set Result = ##class(%ResultSet).%New("Config.Databases:List")
	Do Result.Execute("*")
	While Result.Next() {
		Set Name = Result.Get("Name")
		Do ##class(Config.Databases).Get(Name, .Properties)
		Return:(##class(%File).NormalizeDirectory(Properties("Directory")) = ##class(%File).NormalizeDirectory(pDirectory)) Name
	}
	Return ""
}

/// Smoke test: send the hello_world template through the running production.
ClassMethod SendHello(pToRecipient As %String) As %Status
{
	Set Request = ##class(WhatsAppMeta.Message.SendTemplateRequest).%New()
	Set Request.ToRecipient = pToRecipient, Request.TemplateName = "hello_world"
	Set SC = ##class(EnsLib.Testing.Service).SendTestRequest("WhatsAppMeta.Operation.SendMessage", Request, .Response, .SessionId, 1)
	Write "session ", $Get(SessionId), " messageId ", $Select($IsObject($Get(Response)):Response.MessageId, 1:""), !
	Return SC
}

}
