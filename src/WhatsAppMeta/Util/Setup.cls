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
