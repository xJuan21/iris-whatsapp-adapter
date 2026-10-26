/// Demo production. Before starting: set PhoneNumberId on WhatsAppMeta.Operation.SendMessage and run
/// WhatsAppMeta.Util.Setup to create the SSL config and the "WhatsApp" credentials entry.
Class WhatsAppMeta.Production.Demo Extends Ens.Production
{

XData ProductionDefinition
{
<Production Name="WhatsAppMeta.Production.Demo" TestingEnabled="true" LogGeneralTraceEvents="false">
  <Description>WhatsApp Cloud API demo</Description>
  <ActorPoolSize>1</ActorPoolSize>
  <Item Name="WhatsAppMeta.Operation.SendMessage" Category="" ClassName="WhatsAppMeta.Operation.SendMessage" PoolSize="1" Enabled="true">
    <Setting Target="Adapter" Name="TokenCredentials">WhatsApp</Setting>
  </Item>
</Production>
}

}
