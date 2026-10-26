/// Outbound adapter for the WhatsApp Cloud API (Meta Graph API).
/// Posts to https://graph.facebook.com/{ApiVersion}/{PhoneNumberId}/messages
/// with a bearer Token read from Interoperability Credentials (password field).
Class WhatsAppMeta.Adapter.Outbound Extends EnsLib.HTTP.OutboundAdapter
{

Parameter SETTINGS = "PhoneNumberId:WhatsApp,ApiVersion:WhatsApp,TokenCredentials:WhatsApp:credentialsSelector";

/// Phone number ID from the Meta app dashboard (not the phone number itself).
Property PhoneNumberId As %String;

/// Graph API version segment, e.g. v25.0.
Property ApiVersion As %String [ InitialExpression = "v25.0" ];

/// Credentials entry whose Password holds the Meta access Token.
Property TokenCredentials As %String;

/// Default the inherited HTTP settings to the Graph API when left blank.
Method OnInit() As %Status
{
	set:(..HTTPServer="") ..HTTPServer = "graph.facebook.com"
	set:(..HTTPPort="") ..HTTPPort = 443
	set:(..SSLConfig="") ..SSLConfig = "WhatsApp"
	return ##super()
}

/// POST a message payload. On success pResponse holds the parsed Graph API JSON.
/// Graph API errors come back as a %Status carrying Meta's error code and message.
Method SendMessage(pPayload As %DynamicObject, Output pResponse As %DynamicObject) As %Status
{
	set SC = $$$OK, pResponse = ""
	try {
		set Token = ..GetToken()
		if Token = "" return $$$ERROR($$$GeneralError, "No access Token: set TokenCredentials to a Credentials entry")

		set RequestHTTP = ##class(%Net.HttpRequest).%New()
		set RequestHTTP.ContentType = "application/json"
		do RequestHTTP.SetHeader("Authorization", "Bearer "_Token)
		do RequestHTTP.EntityBody.Write(pPayload.%ToJSON())

		set url = "/"_..ApiVersion_"/"_..PhoneNumberId_"/messages"
		set SC = ..SendFormDataArray(.httpResp, "POST", RequestHTTP, , , url)
		// SendFormDataArray errors on non-2xx; prefer Meta's error body when present
		if $isobject($get(httpResp)) && $isobject(httpResp.Data) && (httpResp.Data.Size > 0) {
			set body = ##class(%DynamicObject).%FromJSON(httpResp.Data)
			if $isobject(body.error) {
				return $$$ERROR($$$GeneralError, "WhatsApp API error "_body.error.code_": "_body.error.message)
			}
			set pResponse = body
		}
	} catch ex {
		set SC = ex.AsStatus()
	}
	return SC
}

Method GetToken() As %String [ Private ]
{
	return:(..TokenCredentials="") ""
	set cred = ##class(Ens.Config.Credentials).%OpenId(..TokenCredentials)
	return $select($isobject(cred): cred.Password, 1: "")
}

}
