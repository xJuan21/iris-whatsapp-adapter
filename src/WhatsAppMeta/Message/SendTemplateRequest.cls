/// Send an approved template message. Works outside the 24h window (e.g. hello_world).
Class WhatsAppMeta.Message.SendTemplateRequest Extends Ens.Request
{

Property To As %String(MAXLEN = 32) [ Required ];

Property TemplateName As %String(MAXLEN = 512) [ Required ];

Property LanguageCode As %String [ InitialExpression = "en_US" ];

/// Positional body parameters ({{1}}, {{2}}, ...).
Property BodyParameters As list Of %String(MAXLEN = 1024);

Method ToPayload() As %DynamicObject
{
	set tpl = {"name": (..TemplateName), "language": {"code": (..LanguageCode)}}
	if ..BodyParameters.Count() {
		set params = []
		for i=1:1:..BodyParameters.Count() {
			do params.%Push({"type": "text", "text": (..BodyParameters.GetAt(i))})
		}
		set tpl.components = [{"type": "body", "parameters": (params)}]
	}
	return {"messaging_product": "whatsapp", "to": (..To), "type": "template", "template": (tpl)}
}

Storage Default
{
<Data name="SendTemplateRequestDefaultData">
<Subscript>"SendTemplateRequest"</Subscript>
<Value name="1">
<Value>To</Value>
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
