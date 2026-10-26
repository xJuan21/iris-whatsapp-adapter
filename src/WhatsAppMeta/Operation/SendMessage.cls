/// Business Operation that sends WhatsApp messages through the Cloud API.
Class WhatsAppMeta.Operation.SendMessage Extends Ens.BusinessOperation
{

Parameter ADAPTER = "WhatsAppMeta.Adapter.Outbound";

Parameter INVOCATION = "Queue";

Property Adapter As WhatsAppMeta.Adapter.Outbound;

Method SendText(pRequest As WhatsAppMeta.Message.SendTextRequest, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status
{
	return ..Send(pRequest.ToPayload(), .pResponse)
}

Method SendTemplate(pRequest As WhatsAppMeta.Message.SendTemplateRequest, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status
{
	return ..Send(pRequest.ToPayload(), .pResponse)
}

Method Send(pPayload As %DynamicObject, Output pResponse As WhatsAppMeta.Message.SendResponse) As %Status [ Private ]
{
	set sc = ..Adapter.SendMessage(pPayload, .json)
	return:$$$ISERR(sc) sc
	set pResponse = ##class(WhatsAppMeta.Message.SendResponse).%New()
	if $isobject(json) {
		set:$isobject(json.messages) pResponse.MessageId = json.messages.%Get(0).id
		set:$isobject(json.contacts) pResponse.WaId = json.contacts.%Get(0)."wa_id"
	}
	return $$$OK
}

XData MessageMap
{
<MapItems>
  <MapItem MessageType="WhatsAppMeta.Message.SendTextRequest"><Method>SendText</Method></MapItem>
  <MapItem MessageType="WhatsAppMeta.Message.SendTemplateRequest"><Method>SendTemplate</Method></MapItem>
</MapItems>
}

}
