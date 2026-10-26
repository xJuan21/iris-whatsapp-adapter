/// Business Service for the WhatsApp webhook. Invoked by WhatsAppMeta.API.Webhook with the
/// verified JSON payload; sends one WhatsAppMeta.Message.Inbound per received message.
/// Run it with PoolSize 0: it has no job of its own, the web request drives it.
Class WhatsAppMeta.Service.Webhook Extends Ens.BusinessService
{

Parameter ADAPTER = "WhatsAppMeta.Adapter.Inbound";

Parameter SETTINGS = "TargetConfigNames:Basic:selector?multiSelect=1&context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

Property Adapter As WhatsAppMeta.Adapter.Inbound;

/// Items that receive each WhatsAppMeta.Message.Inbound.
Property TargetConfigNames As %String(MAXLEN = 1000);

/// pInput is Meta's webhook payload as a %DynamicObject: entry[].changes[].value.messages[].
/// Delivery status updates (value.statuses[]) are ignored for now.
Method OnProcessInput(pInput As %RegisteredObject, Output pOutput As %RegisteredObject, ByRef pHint As %String) As %Status
{
	Set SC = $$$OK
	Return:('$IsObject(pInput.entry)) SC
	Set EntryIterator = pInput.entry.%GetIterator()
	While EntryIterator.%GetNext(.EntryKey, .Entry) {
		Continue:('$IsObject(Entry.changes))
		Set ChangeIterator = Entry.changes.%GetIterator()
		While ChangeIterator.%GetNext(.ChangeKey, .Change) {
			Set Value = Change.value
			Continue:(('$IsObject(Value)) || ('$IsObject(Value.messages)))
			Set ContactName = ""
			If ($IsObject(Value.contacts) && $IsObject(Value.contacts.%Get(0))) {
				Set ContactName = Value.contacts.%Get(0).profile.name
			}
			Set MessageIterator = Value.messages.%GetIterator()
			While MessageIterator.%GetNext(.MessageKey, .Message) {
				Set SC = ..SendInbound(..ToInbound(Message, ContactName))
				Return:($$$ISERR(SC)) SC
			}
		}
	}
	Return SC
}

Method ToInbound(pMessage As %DynamicObject, pContactName As %String) As WhatsAppMeta.Message.Inbound [ Private ]
{
	Set Inbound = ##class(WhatsAppMeta.Message.Inbound).%New()
	Set Inbound.FromSender = pMessage.from
	Set Inbound.ContactName = pContactName
	Set Inbound.MessageId = pMessage.id
	Set Inbound.MessageType = pMessage.type
	Set Inbound.SentAt = pMessage.timestamp
	Set:($IsObject(pMessage.text)) Inbound.Body = pMessage.text.body
	Return Inbound
}

Method SendInbound(pInbound As WhatsAppMeta.Message.Inbound) As %Status [ Private ]
{
	For Index=1:1:$Length(..TargetConfigNames, ",") {
		Set Target = $ZStrip($Piece(..TargetConfigNames, ",", Index), "<>W")
		Continue:(Target = "")
		Set SC = ..SendRequestAsync(Target, pInbound)
		Return:($$$ISERR(SC)) SC
	}
	Return $$$OK
}

}
