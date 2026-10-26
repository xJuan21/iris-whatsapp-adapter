/// Business Operation that sends WhatsApp messages through the Cloud API.
Class WhatsAppMeta.Operation.SendMessage Extends Ens.BusinessOperation
{

Parameter ADAPTER = "WhatsAppMeta.Adapter.Outbound";

Parameter INVOCATION = "Queue";

Property Adapter As WhatsAppMeta.Adapter.Outbound;

Method SendText(pRequest As WhatsAppMeta.Message.SendTextRequest, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status
{
	Return ..Send(pRequest.ToPayload(), .pResponse)
}

Method SendTemplate(pRequest As WhatsAppMeta.Message.SendTemplateRequest, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status
{
	Return ..Send(pRequest.ToPayload(), .pResponse)
}

Method Send(pPayload As %DynamicObject, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status [ Private ]
{
	Set SC = ..Adapter.SendMessage(pPayload, .JSON)
	Return:($$$ISERR(SC)) SC
	Set pResponse = ##class(WhatsAppMeta.Message.SendResponse).%New()
	If $IsObject(JSON) {
		Set:($IsObject(JSON.messages)) pResponse.MessageId = JSON.messages.%Get(0).id
		Set:($IsObject(JSON.contacts)) pResponse.WaId = JSON.contacts.%Get(0)."wa_id"
	}
	Return $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="WhatsAppMeta.Message.SendTextRequest"><Method>SendText</Method></MapItem>
  <MapItem MessageType="WhatsAppMeta.Message.SendTemplateRequest"><Method>SendTemplate</Method></MapItem>
</MapItems>
}

}
