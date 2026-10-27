/// Webhook security checks: X-Hub-Signature-256 and the verify token.
/// Uses throwaway credentials, removed after each test. No network needed.
Class WhatsAppMeta.UnitTest.InboundAdapter Extends %UnitTest.TestCase
{

Parameter SECRETID = "WhatsAppUnitTestSecret";

Parameter VERIFYID = "WhatsAppUnitTestVerify";

/// RFC 4231, test case 2: HMAC-SHA256 of BODY with key "Jefe".
Parameter BODY = "what do ya want for nothing?";

Parameter EXPECTED = "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843";

Property Adapter As WhatsAppMeta.Adapter.Inbound;

Method OnBeforeOneTest(testname As %String) As %Status
{
	Set SC = ##class(Ens.Config.Credentials).SetCredential(..#SECRETID, "test", "Jefe", 1)
	Return:($$$ISERR(SC)) SC
	Set SC = ##class(Ens.Config.Credentials).SetCredential(..#VERIFYID, "test", "my-verify-token", 1)
	Return:($$$ISERR(SC)) SC
	Set ..Adapter = ##class(WhatsAppMeta.Adapter.Inbound).%New()
	Set ..Adapter.AppSecretCredentials = ..#SECRETID
	Set ..Adapter.VerifyTokenCredentials = ..#VERIFYID
	Return $$$OK
}

Method OnAfterOneTest(testname As %String) As %Status
{
	Do ##class(Ens.Config.Credentials).%DeleteId(..#SECRETID)
	Do ##class(Ens.Config.Credentials).%DeleteId(..#VERIFYID)
	Return $$$OK
}

Method TestValidSignature()
{
	Do $$$AssertTrue(..Adapter.IsValidSignature(..#BODY, "sha256="_..#EXPECTED), "RFC 4231 vector accepted")
	Do $$$AssertTrue(..Adapter.IsValidSignature(..#BODY, "sha256="_$ZConvert(..#EXPECTED, "U")), "Uppercase hex accepted")
}

Method TestRejectedSignature()
{
	Do $$$AssertNotTrue(..Adapter.IsValidSignature(..#BODY_" ", "sha256="_..#EXPECTED), "Tampered body rejected")
	Do $$$AssertNotTrue(..Adapter.IsValidSignature(..#BODY, ..#EXPECTED), "Missing sha256= prefix rejected")
	Do $$$AssertNotTrue(..Adapter.IsValidSignature(..#BODY, ""), "Missing header rejected")
	Do $$$AssertNotTrue(..Adapter.IsValidSignature(..#BODY, "sha256=00"), "Wrong signature rejected")
}

Method TestNoSecretConfigured()
{
	Set ..Adapter.AppSecretCredentials = ""
	Do $$$AssertNotTrue(..Adapter.IsValidSignature(..#BODY, "sha256="_..#EXPECTED), "No App Secret rejects everything")
}

Method TestVerifyToken()
{
	Do $$$AssertTrue(..Adapter.IsValidVerifyToken("my-verify-token"), "Correct token accepted")
	Do $$$AssertNotTrue(..Adapter.IsValidVerifyToken("wrong"), "Wrong token rejected")
	Do $$$AssertNotTrue(..Adapter.IsValidVerifyToken(""), "Empty token rejected")
	Set ..Adapter.VerifyTokenCredentials = ""
	Do $$$AssertNotTrue(..Adapter.IsValidVerifyToken(""), "Empty token rejected when none configured")
}

}
