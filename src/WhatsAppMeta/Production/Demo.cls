/// Demo production: inbound webhook -> Echo -> SendMessage.
/// Before starting: set PhoneNumberId on WhatsAppMeta.Operation.SendMessage and run
/// WhatsAppMeta.Util.Setup (SSL config, SetAccessToken, SetSecrets, CreateWebApp, SubscribeApp).
Class WhatsAppMeta.Production.Demo Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="WhatsAppMeta.Production.Demo" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>WhatsApp Cloud API demo</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="WhatsAppMeta.Service.Webhook" Category="" ClassName="WhatsAppMeta.Service.Webhook" PoolSize="0" Enabled="true">
    <Setting Target="Adapter" Name="VerifyTokenCredentials">WhatsAppVerify</Setting>
    <Setting Target="Adapter" Name="AppSecretCredentials">WhatsAppSecret</Setting>
    <Setting Target="Host" Name="TargetConfigNames">WhatsAppMeta.Process.Echo</Setting>
  </Item>
  <Item Name="WhatsAppMeta.Process.Echo" Category="" ClassName="WhatsAppMeta.Process.Echo" PoolSize="1" Enabled="true">
  </Item>
  <Item Name="WhatsAppMeta.Operation.SendMessage" Category="" ClassName="WhatsAppMeta.Operation.SendMessage" PoolSize="1" Enabled="true">
    <Setting Target="Adapter" Name="TokenCredentials">WhatsApp</Setting>
  </Item>
</Production>
}

}
