local framework = require 'modules/framework'

if framework.Name == 'qbox' then
  AddEventHandler('QBCore:Server:PlayerLoaded', function(Player)
    TriggerEvent('versa_sdk:framework:playerLoaded', Player.PlayerData.source)
    TriggerClientEvent('versa_sdk:framework:playerLoaded', Player.PlayerData.source)
  end)

  AddEventHandler('QBCore:Server:OnPlayerUnload', function(source)
    TriggerEvent('versa_sdk:framework:playerUnloaded', source)
    TriggerClientEvent('versa_sdk:framework:playerUnloaded', source)
  end)
elseif framework.Name == 'qbcore' then

elseif framework.Name == 'esx' then
  
else
  CreateThread(function()
    while true do
      error('Missing Framework Runtime setup for framework: ' .. tostring(framework.Name))
      Wait(5000)
    end
  end)
end