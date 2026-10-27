/// Outbound request classes build the JSON body Meta's Cloud API expects. No network needed.
Class WhatsAppMeta.UnitTest.Payload Extends %UnitTest.TestCase
{

Method TestTextPayload()
{
	Set Request = ##class(WhatsAppMeta.Message.SendTextRequest).%New()
	Set Request.ToRecipient = "15551234567", Request.Body = "Hello"
	Set Payload = Request.ToPayload()
	Do $$$AssertEquals(Payload."messaging_product", "whatsapp")
	Do $$$AssertEquals(Payload.to, "15551234567")
	Do $$$AssertEquals(Payload.type, "text")
	Do $$$AssertEquals(Payload.text.body, "Hello")
	Do $$$AssertEquals(Payload.text.%GetTypeOf("preview_url"), "boolean", "preview_url is a JSON boolean")
}

Method TestTemplatePayload()
{
	Set Request = ##class(WhatsAppMeta.Message.SendTemplateRequest).%New()
	Set Request.ToRecipient = "15551234567", Request.TemplateName = "hello_world"
	Set Payload = Request.ToPayload()
	Do $$$AssertEquals(Payload.type, "template")
	Do $$$AssertEquals(Payload.template.name, "hello_world")
	Do $$$AssertEquals(Payload.template.language.code, "en_US")
	Do $$$AssertNotTrue($IsObject(Payload.template.components), "No components without parameters")
}

Method TestTemplateParameters()
{
	Set Request = ##class(WhatsAppMeta.Message.SendTemplateRequest).%New()
	Set Request.ToRecipient = "15551234567", Request.TemplateName = "order_update"
	Do Request.BodyParameters.Insert("Juan")
	Do Request.BodyParameters.Insert("#1234")
	Set Parameters = Request.ToPayload().template.components.%Get(0).parameters
	Do $$$AssertEquals(Parameters.%Size(), 2)
	Do $$$AssertEquals(Parameters.%Get(0).text, "Juan")
	Do $$$AssertEquals(Parameters.%Get(1).text, "#1234")
}

}
