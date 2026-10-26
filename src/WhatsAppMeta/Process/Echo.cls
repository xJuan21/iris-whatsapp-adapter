/// Demo Business Process: replies "Echo: <text>" to every inbound text message.
/// The reply is free-form text, allowed because the sender just opened the 24h window.
Class WhatsAppMeta.Process.Echo Extends Ens.BusinessProcess
{

Parameter SETTINGS = "TargetConfigName:Basic:selector?context={Ens.ContextSearch/ProductionItems?targets=1&productionName=@productionId}";

/// Operation that sends the reply.
Property TargetConfigName As %String(MAXLEN = 256) [ InitialExpression = "WhatsAppMeta.Operation.SendMessage" ];

Method OnRequest(pRequest As WhatsAppMeta.Message.Inbound, Output pResponse As Ens.Response) As %Status
{
	Return:(pRequest.MessageType '= "text") $$$OK
	Set Reply = ##class(WhatsAppMeta.Message.SendTextRequest).%New()
	Set Reply.ToRecipient = pRequest.FromSender
	Set Reply.Body = "Echo: "_pRequest.Body
	Return ..SendRequestAsync(..TargetConfigName, Reply, 0)
}

Storage Default
{
<Data name="EchoDefaultData">
<Subscript>"Echo"</Subscript>
<Value name="1">
<Value>TargetConfigName</Value>
</Value>
</Data>
<DefaultData>EchoDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}
