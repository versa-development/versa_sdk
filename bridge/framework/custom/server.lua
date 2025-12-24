local bridge = {}
local types = require 'utils/types'

--[[ 
  CUSTOM Framework BRIDGE FOR THE VERSA SDK

  EVERYWHERE MARKED WITH TODO: IN THIS FILE
  YOU NEED TO FILL IN WITH YOUR Framework FUNCTIONS

  IF YOU NEED HELP SETTING THIS UP, FEEL FREE TO JOIN OUR DISCORD
  DISCORD: https://discord.com/invite/FsrujTDbvg
]]

--- Structure the central character object
local function structureResponse(data)
  return types.character({
    identifier = -- TODO:Whatever your character object sends the identifier as, place here
    source = -- TODO:Whatever your character object sends the source as, place here
    firstname = -- TODO:Whatever your character object sends the firstname as, place here
    lastname = -- TODO:Whatever your character object sends the lastname as, place here
    metadata = -- TODO:Whatever your character object sends the metadata as, place here
  })
end

bridge.Name = 'custom'

function bridge.GetPlayer(source)
  local player = -- TODO:Function to get the character data from the source passed by the function
  if not player then return false end

  return structureResponse(player)
end

function bridge.GetPlayerFromIdentifier(identifier)
  local player = -- TODO:Function to get the character data from the identifier passed by the function
  if not player then return false end

  return structureResponse(player)
end

function bridge.GetPlayers()
  local data = {}
  local players = -- TODO:Function to get all the characters data
  
  for i = 1, #players do
    data[#data + 1] = structureResponse(players[i])
  end

  return data
end

function bridge.GetMetaDataValue(source, key)
  return -- TODO:Function to get metadata value from the source and key
end

function bridge.SetMetaDataValue(source, key, value)
  return -- TODO:Function to set metadata value from the source, key and value
end

function bridge.AddMoney(source, type, amount, reason)
  return -- TODO:Function to add money from the source, type, amount and reason
end

function bridge.RemoveMoney(source, type, amount, reason)
  return -- TODO:Function to remove money from the source, type, amount and reason
end

-- LAST STEP TODO: - EVENTS
-- You must implement your framework player loaded/unloaded events in
-- runtime/framework/server.lua, all other framework examples are already in the file

return bridge