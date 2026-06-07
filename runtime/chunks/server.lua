-- Chunks Global Cache
Chunks = {}

--- Create a new chunk entity
-- @param string type The type of chunk entity ('ped' or 'object')
-- @param string key The unique key for the chunk entity
-- @param table data The chunk entity data
-- @return boolean True if created successfully, false otherwise
-- @return string|nil Error message if creation failed, nil if successful
local function createChunkEntity(type, key, data)
  if Chunks[key] then
    return false, 'Chunk with this key already exists'
  end

  -- Assign additional properties
  data.key = key
  data.type = type

  -- Add to global cache
  Chunks[key] = data

  -- Broadcast creation event to clients
  TriggerClientEvent('versa_sdk:chunks:createEntities', -1, data)

  return true
end

--- Edit an existing chunk entity
-- @param string type The type of chunk entity ('ped' or 'object')
-- @param string key The unique key for the chunk entity
-- @param table data The chunk entity data to update
-- @return boolean True if edited successfully, false otherwise
-- @return string|nil Error message if edit failed, nil if successful
local function editChunkEntity(key, data)
  if not Chunks[key] then
    return false, 'Chunk with this key does not exist'
  end

  local oldChunkData = Chunks[key]

  if data.coords then oldChunkData.coords = data.coords end
  if data.model then oldChunkData.model = data.model end
  if data.rotation then oldChunkData.rotation = data.rotation end

  if data.target then
    oldChunkData.target = data.target
  elseif data.target == false then
    oldChunkData.target = nil
  end

  TriggerClientEvent('versa_sdk:chunks:editEntities', -1, key, data)

  return true
end

--- Delete an existing chunk entity
-- @param string key The unique key for the chunk entity to delete
-- @return boolean True if deleted successfully, false otherwise
-- @return string|nil Error message if deletion failed, nil if successful
local function deleteChunkEntity(key)
  if not Chunks[key] then
    return false, 'Chunk with this key does not exist'
  end

  Chunks[key] = nil
  TriggerClientEvent('versa_sdk:chunks:deleteEntities', -1, key)

  return true
end

--- Event Handlers
-- Cleanup chunk entities on resource stop
AddEventHandler('onResourceStop', function(resourceName)
  for key, chunkData in pairs(Chunks) do
    if chunkData.resource == resourceName then
      Chunks[key] = nil
      TriggerClientEvent('versa_sdk:chunks:deleteEntities', -1, key)
    end
  end
end)

--- Callbacks
-- Get all chunks
lib.callback.register('versa_sdk:chunks:getAll', function()
  return Chunks
end)

-- Exports
exports('CreateChunkEntity', createChunkEntity)
exports('EditChunkEntity', editChunkEntity)
exports('DeleteChunkEntity', deleteChunkEntity)