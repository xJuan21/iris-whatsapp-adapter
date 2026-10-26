/// REST endpoint Meta calls for the WhatsApp webhook.
/// GET  /webhook: subscription handshake (hub.mode, hub.verify_token, hub.challenge).
/// POST /webhook: event delivery; rejected with 403 unless X-Hub-Signature-256 is valid.
/// Meant to be the only thing reachable through the public tunnel.
Class WhatsAppMeta.API.Webhook Extends %CSP.REST
{

/// Keep the request body as raw bytes: the signature is computed over them.
Parameter CONVERTINPUTSTREAM = 0;

Parameter CHARSET = "utf-8";

/// Largest body accepted, in bytes. Meta's payloads are far smaller.
Parameter MAXBODY = 1000000;

Parameter SERVICENAME = "WhatsAppMeta.Service.Webhook";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
  <Route Url="/webhook" Method="GET" Call="Verify"/>
  <Route Url="/webhook" Method="POST" Call="Receive"/>
</Routes>
}

ClassMethod Verify() As %Status
{
	Set Mode = %request.Get("hub.mode")
	Set Token = %request.Get("hub.verify_token")
	Set Challenge = %request.Get("hub.challenge")
	Set SC = ##class(Ens.Director).CreateBusinessService(..#SERVICENAME, .Service)
	If $$$ISERR(SC) {
		Set %response.Status = "503 Service Unavailable"
		Return $$$OK
	}
	// Only echo a plain alphanumeric challenge, never arbitrary input
	If ((Mode = "subscribe") && (Challenge?1.AN) && Service.Adapter.IsValidVerifyToken(Token)) {
		Set %response.ContentType = "text/plain"
		Write Challenge
	} Else {
		Set %response.Status = "403 Forbidden"
	}
	Return $$$OK
}

ClassMethod Receive() As %Status
{
	If ('$IsObject(%request.Content) || (%request.Content.Size > ..#MAXBODY)) {
		Set %response.Status = "413 Payload Too Large"
		Return $$$OK
	}
	Set Body = %request.Content.Read(..#MAXBODY)
	Set Signature = %request.GetCgiEnv("HTTP_X_HUB_SIGNATURE_256")
	Set SC = ##class(Ens.Director).CreateBusinessService(..#SERVICENAME, .Service)
	If $$$ISERR(SC) {
		Set %response.Status = "503 Service Unavailable"
		Return $$$OK
	}
	If 'Service.Adapter.IsValidSignature(Body, Signature) {
		Set %response.Status = "403 Forbidden"
		Return $$$OK
	}
	Try {
		Set Payload = ##class(%DynamicObject).%FromJSON($ZConvert(Body, "I", "UTF8"))
	} Catch Ex {
		Set %response.Status = "400 Bad Request"
		Return $$$OK
	}
	// Answer 200 even if processing fails: Meta retries non-2xx, errors show in the Event Log
	Do Service.ProcessInput(Payload)
	Return $$$OK
}

}
