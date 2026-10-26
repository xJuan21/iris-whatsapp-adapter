/// One message received through the WhatsApp Cloud API webhook.
Class WhatsAppMeta.Message.Inbound Extends Ens.Request
{

/// Sender's WhatsApp ID (phone number in international format, digits only).
Property FromSender As %String(MAXLEN = 32);

/// Sender's profile name, when Meta includes it.
Property ContactName As %String(MAXLEN = 256);

/// wamid.* assigned by Meta.
Property MessageId As %String(MAXLEN = 256);

/// Meta's message type: text, image, audio, location, ...
Property MessageType As %String(MAXLEN = 32);

/// Text body for type "text"; empty for other types.
Property Body As %String(MAXLEN = 4096);

/// Unix epoch seconds, as sent by Meta.
Property SentAt As %String(MAXLEN = 16);

Storage Default
{
<Data name="InboundDefaultData">
<Subscript>"Inbound"</Subscript>
<Value name="1">
<Value>FromSender</Value>
</Value>
<Value name="2">
<Value>ContactName</Value>
</Value>
<Value name="3">
<Value>MessageId</Value>
</Value>
<Value name="4">
<Value>MessageType</Value>
</Value>
<Value name="5">
<Value>Body</Value>
</Value>
<Value name="6">
<Value>SentAt</Value>
</Value>
</Data>
<DefaultData>InboundDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
