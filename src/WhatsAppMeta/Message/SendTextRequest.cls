/// Send a free-form text message. Only allowed inside the 24h customer-service window.
Class WhatsAppMeta.Message.SendTextRequest Extends Ens.Request
{

/// Recipient in international format, digits only (e.g. 15551234567).
Property ToRecipient As %String(MAXLEN = 32) [ Required ];

Property Body As %String(MAXLEN = 4096) [ Required ];

Property PreviewUrl As %Boolean [ InitialExpression = 0 ];

Method ToPayload() As %DynamicObject
{
	Set Text = {"body": (..Body)}
	// Meta expects a JSON boolean; (''..PreviewUrl) would serialize as the number 0/1
	Do Text.%Set("preview_url", ''..PreviewUrl, "boolean")
	Return {
		"messaging_product": "whatsapp",
		"recipient_type": "individual",
		"to": (..ToRecipient),
		"type": "text",
		"text": (Text)
	}
}

Storage Default
{
<Data name="SendTextRequestDefaultData">
<Subscript>"SendTextRequest"</Subscript>
<Value name="1">
<Value>ToRecipient</Value>
</Value>
<Value name="2">
<Value>Body</Value>
</Value>
<Value name="3">
<Value>PreviewUrl</Value>
</Value>
</Data>
<DefaultData>SendTextRequestDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
