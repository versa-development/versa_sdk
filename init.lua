local config = require 'config'
local log = require 'utils/logger'

CURRENT_VERSION = GetResourceMetadata(GetCurrentResourceName(), 'version') or '0.0.0'

exports('Framework', function()
    return config.Framework
end)

-- Duplicity checks if the code ran is the server or client. returns true if server
if IsDuplicityVersion() then
    -- ensure all random functions are properly seeded
    math.randomseed(os.time())

    -- random wait so all Versa resources print version checks at the same time!
    Wait(1673)

    -- Dependency Checks and Version Logging
    if not lib.checkDependency('ox_lib', '3.20.0', true) then error('ox_lib v3.20.0 or higher is required for Versa SDK to function properly.') end
    if not lib.checkDependency('oxmysql', '2.12.0', true) then error('oxmysql v2.12.0 or higher is required for Versa SDK to function properly.') end

    -- SDK Version Check
    PerformHttpRequest(('https://api.github.com/repos/versa-development/versa_sdk/releases/latest'), function(status, response)
        if status ~= 200 then return end

        response = json.decode(response)
        if response.prerelease then return end

        local latestVersion = response.tag_name:match('%d+%.%d+%.%d+')
        if not latestVersion or latestVersion == CURRENT_VERSION then 
            log.info('Versa SDK - Initialized (v' .. CURRENT_VERSION .. ')')
            return 
        end

        local cv = { string.strsplit('.', CURRENT_VERSION) }
        local lv = { string.strsplit('.', latestVersion) }

        for i = 1, #cv do
            local current, minimum = tonumber(cv[i]), tonumber(lv[i])

            if current ~= minimum then
                if current < minimum then
                    log.warn('Versa SDK - Update Available! You are running v' .. CURRENT_VERSION .. ' but the latest version is v' .. latestVersion .. '. Please update at ' .. response.html_url)
                    return
                else 
                    log.info('Versa SDK - Development Version Initialized (v' .. CURRENT_VERSION .. ') (latest: v' .. latestVersion .. ')')
                    return 
                end
            end
        end
    end, 'GET')
else
    return
end