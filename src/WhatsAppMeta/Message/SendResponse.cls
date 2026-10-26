Class WhatsAppMeta.Message.SendResponse Extends Ens.Response
{

/// wamid.* returned by Meta; correlates with later status webhooks.
Property MessageId As %String(MAXLEN = 256);

/// WhatsApp ID Meta resolved the recipient to.
Property WaId As %String(MAXLEN = 32);

Storage Default
{
<Data name="SendResponseDefaultData">
<Subscript>"SendResponse"</Subscript>
<Value name="1">
<Value>MessageId</Value>
</Value>
<Value name="2">
<Value>WaId</Value>
</Value>
</Data>
<DefaultData>SendResponseDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
