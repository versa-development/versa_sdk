-- Global created entities cache
CreatedEntities = {}

local keyToZoneId = {} 

-- Module imports
local Target = require 'modules/target'
local log = require 'utils/logger'

-- Register Net Events
RegisterNetEvent('versa_sdk:chunks:createEntities')
RegisterNetEvent('versa_sdk:chunks:editEntities')
RegisterNetEvent('versa_sdk:chunks:deleteEntities')

--- Create a chunk entity
-- @param string zoneId The zone ID
-- @param table data The chunk entity data
-- @return number The created object ID
local function createChunkEntity(zoneId, data)
  if not CreatedEntities[zoneId] then
    CreatedEntities[zoneId] = {}
  end

  -- Check if the model exists before adding it to the cache
  if not lib.requestModel(data.model, 10000) then
    log.error('Failed to load model for chunk entity:', data.model)
    return false, 'Failed to load model'
  end

  local objectId
  if data.type == 'object' then
    objectId = CreateObject(data.model, data.coords.x, data.coords.y, data.coords.z, false, false, false)
  elseif data.type == 'ped' then
    objectId = CreatePed(0, data.model, data.coords.x, data.coords.y, data.coords.z, (data.coords.w or 0), false, false)
    SetPedCanRagdoll(objectId, false)
    SetBlockingOfNonTemporaryEvents(objectId, true) -- stops ped from fleeing, fighting, running etc
  else
    log.error('Invalid chunk entity type:', data.type, 'for key:', data.key)
    return nil
  end

  log.debug('Created chunk entity:', data.key, 'in zone:', zoneId, 'with object ID:', objectId)

  CreatedEntities[zoneId][data.key] = objectId
  SetEntityHeading(objectId, (data.coords.w or 0))
  FreezeEntityPosition(objectId, true)
  SetEntityInvincible(objectId, true)
  SetEntityAsMissionEntity(objectId, true, true)
  
  if data.rotation then
    SetEntityRotation(objectId, data.rotation.x, data.rotation.y, data.rotation.z, (data.rotation.order or 2), (data.rotation.relative or true))
  end

  if data.target then
    data.target.entity = objectId
    Target.AddEntity(data.target)
  end

  SetModelAsNoLongerNeeded(data.model)

  return objectId
end

--- Delete a chunk entity
-- @param string zoneId The zone ID
-- @param string key The unique key for the chunk entity to delete
-- @return boolean True if deleted successfully, false otherwise
local function deleteChunkEntity(zoneId, key)
  if CreatedEntities[zoneId] and CreatedEntities[zoneId][key] then
    local objectId = CreatedEntities[zoneId][key]

    -- if object is ped then DeletePed, else DeleteObject
    local entityType = GetEntityType(objectId)
    if entityType == 1 then -- 1 = Ped
      if DoesEntityExist(objectId) then
        DeletePed(objectId)
      end
    elseif entityType == 3 then -- 3 = Object
      if DoesEntityExist(objectId) then
        DeleteObject(objectId)
      end
    else
      log.warn('Unknown entity type for chunk entity with key:', key, 'in zone:', zoneId)
    end

    Target.RemoveEntity({ entity = objectId })

    CreatedEntities[zoneId][key] = nil
    log.debug('Deleted chunk entity:', key, 'in zone:', zoneId)
    return true
  end

  log.error('No created entity found for key:', key, 'in zone:', zoneId)
  return false
end

--- Edit a chunk entity
-- @param string key The unique key for the chunk entity
-- @param table data The chunk entity data to update
local function editChunkEntity(key, data)
  for zoneId, entities in pairs(CreatedEntities) do
    if entities[key] then
      local objectId = entities[key]

      -- If new coords are sent through- we update the coords and heading
      if data.coords then 
        SetEntityCoords(objectId, data.coords.x, data.coords.y, data.coords.z, false, false, false, true) 
        if data.coords.w then SetEntityHeading(objectId, data.coords.w) end
      end

      if data.rotation then
        SetEntityRotation(objectId, data.rotation.x, data.rotation.y, data.rotation.z, (data.rotation.order or 2), (data.rotation.relative or true))
      end

      if data.target then
        Target.RemoveEntity({ entity = objectId })
        data.target.entity = objectId

        Target.AddEntity(data.target)
      elseif data.target == false then
        Target.RemoveEntity({ entity = objectId })
      end

      if data.model then
        local changedModel = false
        local cachedEntityData = nil
        for i = 1, #Zones[zoneId].entities do
          if Zones[zoneId].entities[i].key == key then
            deleteChunkEntity(zoneId, key)
            createChunkEntity(zoneId, Zones[zoneId].entities[i])
            changedModel = true
            break
          end
        end

        if not changedModel then
          log.error('Failed to change model for chunk entity with key:', key, 'in zone:', zoneId)
          return false
        end
      end

      log.debug('Edited chunk entity:', key, 'in zone:', zoneId)
      return true
    end
  end

  log.error('No created entity found for key:', key)
  return false
end

--- Create a chunk entity
-- @param table data The chunk entity data
-- @return boolean True if created successfully, false otherwise
-- @return string|nil Error message if creation failed, nil if successful
local function cacheChunkEntity(data)
  -- Get the zone ID for the chunk entity
  local chunkId = GetZoneIdFromCoords(data.coords)
  if not chunkId then
    log.error('No zone found for chunk entity at coords:', json.encode(data.coords))
    return false, 'No zone found for the given coordinates'
  end
  
  -- Add to the zone cache
  Zones[chunkId].entities[#Zones[chunkId].entities + 1] = data
  keyToZoneId[data.key] = chunkId

  -- Check if the entity is in any of the zones the player is in/surrounding
  if chunkId == CurrentZoneId or (CurrentSurroundingZones and lib.table.contains(CurrentSurroundingZones, chunkId)) then
    createChunkEntity(chunkId, data)
  end

  return true
end

--- Edit a cached chunk entity
-- @param string key The unique key for the chunk entity
-- @param table data The chunk entity data to update
local function editCachedChunkEntity(key, data)
  local zoneId = keyToZoneId[key]
  if not zoneId then
    log.error('No zone found for chunk entity with key:', key)
    return false, 'No zone found for the given key'
  end

  -- Update the zone cache
  local zone = Zones[zoneId]
  for i = 1, #zone.entities do
    if zone.entities[i].key == key then
      if data.coords then zone.entities[i].coords = data.coords end
      if data.model then zone.entities[i].model = data.model end
      if data.rotation then zone.entities[i].rotation = data.rotation end

      if data.target then
        zone.entities[i].target = data.target
      elseif data.target == false then
        zone.entities[i].target = nil
      end

      break
    end
  end

  -- If the entity is currently created, update it
  if CreatedEntities[zoneId] and CreatedEntities[zoneId][key] then
    editChunkEntity(key, data)
  end

  return true
end

--- Uncache a chunk entity
-- @param string key The unique key for the chunk entity to uncache
-- @return boolean True if uncached successfully, false otherwise
local function uncacheChunkEntity(key)
  local zoneId = keyToZoneId[key]
  if not zoneId then
    log.error('No zone found for chunk entity with key:', key)
    return false, 'No zone found for the given key'
  end

  -- Remove from the zone cache
  if Zones[zoneId] then
    for i = #Zones[zoneId].entities, 1, -1 do
      if Zones[zoneId].entities[i].key == key then
        table.remove(Zones[zoneId].entities, i)
        break
      end
    end
  end
  keyToZoneId[key] = nil

  -- Delete the entity if it is currently created
  if CreatedEntities[zoneId] and CreatedEntities[zoneId][key] then
    deleteChunkEntity(zoneId, key)
  end

  return true
end

--- Unload chunk entities for a given zone
-- @param string zoneId The zone ID
local function unloadChunkEntities(zoneId)
  log.debug('Unloading chunk entities for zone:', zoneId)

  if CreatedEntities[zoneId] then
    for key, _ in pairs(CreatedEntities[zoneId]) do
      deleteChunkEntity(zoneId, key)
    end
    CreatedEntities[zoneId] = nil
  end
end

--- Load chunk entities for a given zone
-- @param string zoneId The zone ID
local function loadChunkEntities(zoneId)
  log.debug('Loading chunk entities for zone:', zoneId)
  
  -- Fallback in case entities were not unloaded properly for whatever reason
  if CreatedEntities[zoneId] then
    unloadChunkEntities(zoneId)
    Wait(1000)
  end

  -- Create all entities for the zone
  for i = 1, #Zones[zoneId].entities do
    local entityData = Zones[zoneId].entities[i]
    createChunkEntity(zoneId, entityData)
  end
end

--- Check if an entity is a created chunk entity
-- @param number entity The entity ID to check
-- @return boolean True if it is a created chunk entity, false otherwise
-- @return string|nil key The unique key for the chunk entity if it is a created
local function isEntityChunkEntity(entity)
  for _, entities in pairs(CreatedEntities) do
    for key, objectId in pairs(entities) do
      if objectId == entity then
        return true, key
      end
    end
  end
  return false
end

exports('IsEntityChunkEntity', isEntityChunkEntity)

--- Get the entity ID from key
-- @param string key The unique key for the chunk entity
-- @return number|nil The entity ID if found, nil otherwise
local function getEntityFromKey(key)
  local zoneId = keyToZoneId[key]
  if zoneId and CreatedEntities[zoneId] and CreatedEntities[zoneId][key] then
    return CreatedEntities[zoneId][key]
  end
  return nil
end

exports('GetEntityFromKey', getEntityFromKey)

--- Events
-- Event handler from sdk/zones/client when stepping into a new zone
-- @param string zoneId The zone ID that was entered
AddEventHandler('versa_sdk:zones:enteredZone', function(zoneId)
  local zone = Zones[zoneId]

  -- Check which surrounding zones we need to unload
  for i = 1, #CurrentSurroundingZones do
    local surroundingZoneId = CurrentSurroundingZones[i]
    if not lib.table.contains(zone.surroundingZones, surroundingZoneId) and surroundingZoneId ~= zoneId then
      unloadChunkEntities(surroundingZoneId)
    end
  end

  -- Set cache variables
  CurrentZoneId = zoneId
  CurrentSurroundingZones = zone.surroundingZones

  -- Load entities for the current zone and surrounding zones if not already loaded
  if not CreatedEntities[CurrentZoneId] then
    loadChunkEntities(CurrentZoneId)
  end

  for i = 1, #CurrentSurroundingZones do
    local surroundingZoneId = CurrentSurroundingZones[i]
    if not CreatedEntities[surroundingZoneId] then
      loadChunkEntities(surroundingZoneId)
    end
  end
end)

-- Envent Handler from server to cache entities
-- @param table data The chunk entity data or list of chunk entity data
AddEventHandler('versa_sdk:chunks:createEntities', function(data)
  if type(data[1]) == 'table' then
    for i, entity in ipairs(data) do
      cacheChunkEntity(entity)
    end
  else
    cacheChunkEntity(data)
  end
end)

-- Event Handler from server to edit entities
-- @param string key The unique key for the chunk entity
-- @param table data The chunk entity data to update
AddEventHandler('versa_sdk:chunks:editEntities', function(key, data)
  editCachedChunkEntity(key, data)
end)

-- Event Handler from server to delete entities
-- @param string|table key The unique key or list of keys for the chunk entities to delete
AddEventHandler('versa_sdk:chunks:deleteEntities', function(key)
  if type(key) == 'table' then
    for i, entityKey in ipairs(key) do
      uncacheChunkEntity(entityKey)
    end
  else
    uncacheChunkEntity(key)
  end
end)

-- Delete all objects when versa_sdk is stopped/restarted
AddEventHandler('onResourceStop', function(resourceName)
  if resourceName == GetCurrentResourceName() then
    for zoneId, _ in pairs(CreatedEntities) do
      unloadChunkEntities(zoneId)
    end
  end
end)

-- Load all chunk entities into cache when all the world zones have been created
AddEventHandler('versa_sdk:zones:created', function()
  local allChunks = lib.callback.await('versa_sdk:chunks:getAll', false)
  for key, data in pairs(allChunks) do
    cacheChunkEntity(data)
  end
end)