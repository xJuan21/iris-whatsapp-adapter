/// Inbound adapter for the WhatsApp Cloud API webhook.
/// Meta calls the webhook over HTTPS; WhatsAppMeta.API.Webhook receives the call and
/// uses this adapter to check the verify token (GET) and the X-Hub-Signature-256 (POST).
/// Both secrets are read from Interoperability Credentials (password field).
Class WhatsAppMeta.Adapter.Inbound Extends Ens.InboundAdapter
{

Parameter SETTINGS = "VerifyTokenCredentials:WhatsApp:credentialsSelector,AppSecretCredentials:WhatsApp:credentialsSelector";

/// Credentials entry whose Password holds the verify token entered in the Meta webhook setup.
Property VerifyTokenCredentials As %String;

/// Credentials entry whose Password holds the Meta App Secret (App settings, Basic).
Property AppSecretCredentials As %String;

/// True when pToken matches the configured verify token.
Method IsValidVerifyToken(pToken As %String) As %Boolean
{
	Set Expected = ..GetSecret(..VerifyTokenCredentials)
	Return ((Expected '= "") && (pToken = Expected))
}

/// True when pSignature ("sha256=<hex>") is the HMAC-SHA256 of the raw body with the App Secret.
/// pBody must be the raw bytes Meta sent, before any charset conversion.
Method IsValidSignature(pBody As %String, pSignature As %String) As %Boolean
{
	Set Secret = ..GetSecret(..AppSecretCredentials)
	Return:((Secret = "") || ($Extract(pSignature, 1, 7) '= "sha256=")) 0
	Set HMAC = $System.Encryption.HMACSHA(256, pBody, Secret)
	Set Hex = ""
	For Index=1:1:$Length(HMAC) {
		Set Hex = Hex_$Translate($Justify($ZHex($Ascii(HMAC, Index)), 2), " ", "0")
	}
	Return ($ZConvert(Hex, "L") = $ZConvert($Extract(pSignature, 8, *), "L"))
}

Method GetSecret(pCredentialsId As %String) As %String [ Private ]
{
	Return:(pCredentialsId = "") ""
	Set Credential = ##class(Ens.Config.Credentials).%OpenId(pCredentialsId)
	Return $Select($IsObject(Credential): Credential.Password, 1: "")
}

}
