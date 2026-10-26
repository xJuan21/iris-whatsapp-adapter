/// Send an approved template message. Works outside the 24h window (e.g. hello_world).
Class WhatsAppMeta.Message.SendTemplateRequest Extends Ens.Request
{

Property ToRecipient As %String(MAXLEN = 32) [ Required ];

Property TemplateName As %String(MAXLEN = 512) [ Required ];

Property LanguageCode As %String [ InitialExpression = "en_US" ];

/// Positional body parameters ({{1}}, {{2}}, ...).
Property BodyParameters As list Of %String(MAXLEN = 1024);

Method ToPayload() As %DynamicObject
{
	Set Template = {"name": (..TemplateName), "language": {"code": (..LanguageCode)}}
	If ..BodyParameters.Count() {
		Set Parameters = []
		For Index=1:1:..BodyParameters.Count() {
			Do Parameters.%Push({"type": "text", "text": (..BodyParameters.GetAt(Index))})
		}
		Set Template.components = [{"type": "body", "parameters": (Parameters)}]
	}
	Return {"messaging_product": "whatsapp", "to": (..ToRecipient), "type": "template", "template": (Template)}
}

Storage Default
{
<Data name="SendTemplateRequestDefaultData">
<Subscript>"SendTemplateRequest"</Subscript>
<Value name="1">
<Value>ToRecipient</Value>
</Value>
<Value name="2">
<Value>TemplateName</Value>
</Value>
<Value name="3">
<Value>LanguageCode</Value>
</Value>
<Value name="4">
<Value>BodyParameters</Value>
</Value>
</Data>
<DefaultData>SendTemplateRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
