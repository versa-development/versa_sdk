local bridge = {}
local types = require 'utils/types'

--- Structure the central character object
local function structureResponse(data)
  return types.character({
    identifier = data.PlayerData.citizenid,
    source = data.PlayerData.source,
    firstname = data.PlayerData.charinfo.firstname,
    lastname = data.PlayerData.charinfo.lastname,
    metadata = data.PlayerData.metadata
  })
end

bridge.Name = 'qbox'

function bridge.GetPlayer(source)
  local player = exports.qbx_core:GetPlayer(source)
  if not player then return false end

  return structureResponse(player)
end

function bridge.GetPlayerFromIdentifier(identifier)
  local player = exports.qbx_core:GetPlayerByCitizenId(identifier)
  if not player then return false end

  return structureResponse(player)
end

function bridge.GetPlayers()
  local data = {}
  local players = exports.qbx_core:GetQBPlayers()
  
  for i = 1, #players do
    data[#data + 1] = structureResponse(players[i])
  end

  return data
end

function bridge.GetMetaDataValue(source, key)
  return exports.qbx_core:GetMetadata(source, key)
end

function bridge.SetMetaDataValue(source, key, value)
  return exports.qbx_core:SetMetadata(source, key, value)
end

function bridge.AddMoney(source, type, amount, reason)
  return exports.qbx_core:AddMoney(source, type, amount, reason)
end

function bridge.RemoveMoney(source, type, amount, reason)
  return exports.qbx_core:RemoveMoney(source, type, amount, reason)
end

return bridge