/// Outbound adapter for the WhatsApp Cloud API (Meta Graph API).
/// Posts to https://graph.facebook.com/{ApiVersion}/{PhoneNumberId}/messages
/// with a bearer token read from Interoperability Credentials (password field).
Class WhatsAppMeta.Adapter.Outbound Extends EnsLib.HTTP.OutboundAdapter
{

Parameter SETTINGS = "PhoneNumberId:WhatsApp,ApiVersion:WhatsApp,TokenCredentials:WhatsApp:credentialsSelector";

/// Phone number ID from the Meta app dashboard (not the phone number itself).
Property PhoneNumberId As %String;

/// Graph API version segment, e.g. v25.0.
Property ApiVersion As %String [ InitialExpression = "v25.0" ];

/// Credentials entry whose Password holds the Meta access token.
Property TokenCredentials As %String;

/// Default the inherited HTTP settings to the Graph API when left blank.
Method OnInit() As %Status
{
	Set:(..HTTPServer="") ..HTTPServer = "graph.facebook.com"
	Set:(..HTTPPort="") ..HTTPPort = 443
	Set:(..SSLConfig="") ..SSLConfig = "WhatsApp"
	Return ##super()
}

/// POST a message payload. On success pResponse holds the parsed Graph API JSON.
/// Graph API errors come back as a %Status carrying Meta's error code and message.
Method SendMessage(pPayload As %DynamicObject, Output pResponse As %DynamicObject) As %Status
{
	Set SC = $$$OK, pResponse = ""
	Try {
		Set Token = ..GetToken()
		If Token = "" Return $$$ERROR($$$GeneralError, "No access token: set TokenCredentials to a Credentials entry")

		Set RequestHTTP = ##class(%Net.HttpRequest).%New()
		Set RequestHTTP.ContentType = "application/json"
		Do RequestHTTP.SetHeader("Authorization", "Bearer "_Token)
		Do RequestHTTP.EntityBody.Write(pPayload.%ToJSON())

		Set URL = "/"_..ApiVersion_"/"_..PhoneNumberId_"/messages"
		Set SC = ..SendFormDataArray(.ResponseHTTP, "POST", RequestHTTP, , , URL)
		// SendFormDataArray errors on non-2xx; prefer Meta's error body when present
		If $IsObject($Get(ResponseHTTP)) && $IsObject(ResponseHTTP.Data) && (ResponseHTTP.Data.Size > 0) {
			Set Body = ##class(%DynamicObject).%FromJSON(ResponseHTTP.Data)
			If $IsObject(Body.error) {
				Return $$$ERROR($$$GeneralError, "WhatsApp API error "_Body.error.code_": "_Body.error.message)
			}
			Set pResponse = Body
		}
	} Catch Ex {
		Set SC = Ex.AsStatus()
	}
	Return SC
}

Method GetToken() As %String [ Private ]
{
	Return:(..TokenCredentials="") ""
	Set Credential = ##class(Ens.Config.Credentials).%OpenId(..TokenCredentials)
	Return $Select($IsObject(Credential): Credential.Password, 1: "")
}

}
