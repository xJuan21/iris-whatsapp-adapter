/// One-time setup helpers. The token is passed in at the terminal, never stored in source.
Class WhatsAppMeta.Util.Setup
{

/// Create the client SSL/TLS configuration used by the adapter.
ClassMethod CreateSSLConfig(pName As %String = "WhatsApp") As %Status
{
	new $namespace
	set $namespace = "%SYS"
	return:##class(Security.SSLConfigs).Exists(pName) $$$OK
	return ##class(Security.SSLConfigs).Create(pName)
}

/// Store the Meta access token as an Interoperability credential. Run in the production namespace.
ClassMethod SetToken(pToken As %String, pId As %String = "WhatsApp") As %Status
{
	return ##class(Ens.Config.Credentials).SetCredential(pId, "meta", pToken, 1)
}

/// Smoke test: send the hello_world template through the running production.
ClassMethod SendHello(pTo As %String) As %Status
{
	set req = ##class(WhatsAppMeta.Message.SendTemplateRequest).%New()
	set req.To = pTo, req.TemplateName = "hello_world"
	set sc = ##class(EnsLib.Testing.Service).SendTestRequest("WhatsAppMeta.Operation.SendMessage", req, .resp, .sessionId, 1)
	write "session ", $get(sessionId), " messageId ", $select($isobject($get(resp)):resp.MessageId, 1:""), !
	return sc
}

}
