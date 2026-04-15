-- EMS Dispatch Server Logic
local function hasEMSJob(source)
    local player = exports.qbx_core:GetPlayer(source)
    if player and player.PlayerData and player.PlayerData.job and Config.EMSJobs[player.PlayerData.job.name] then
        return true
    end
    return false
end

MySQL.ready(function()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `ems_calls` (
            `id` INT AUTO_INCREMENT PRIMARY KEY,
            `citizenid` VARCHAR(50),
            `name` VARCHAR(100),
            `message` TEXT,
            `street` VARCHAR(255),
            `responder` VARCHAR(100) DEFAULT NULL,
            `coords` TEXT,
            `time` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
            `status` VARCHAR(20) DEFAULT 'pending'
        );
    ]])
    -- Self-healing: Ensure columns exist
    pcall(function()
        MySQL.query.await("ALTER TABLE ems_calls ADD COLUMN IF NOT EXISTS street VARCHAR(255) AFTER message")
    end)
    pcall(function()
        MySQL.query.await("ALTER TABLE ems_calls ADD COLUMN IF NOT EXISTS responder VARCHAR(100) DEFAULT NULL AFTER street")
    end)
    print("^3[EMS-Dispatch]^7 Database Updated. Responder Tracking & Time Filter Active.")
end)

local callCooldowns = {}

RegisterNetEvent('ems-dispatch:server:sendCall', function(data)
    local src = source
    local player = exports.qbx_core:GetPlayer(src)
    if not player then return end

    local citizenid = player.PlayerData.citizenid
    local currentTime = os.time()

    -- 2 Minute Cooldown Check (120 seconds)
    if callCooldowns[citizenid] and (currentTime - callCooldowns[citizenid]) < 120 then
        local timeLeft = 120 - (currentTime - callCooldowns[citizenid])
        TriggerClientEvent('ox_lib:notify', src, {
            title = 'Dispatch Cooldown',
            description = ('You must wait %d seconds before sending another signal.'):format(timeLeft),
            type = 'error'
        })
        return
    end

    local name = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname
    
    local callData = {
        name = name,
        citizenid = citizenid,
        message = data.message or "Medical Emergency!",
        street = data.street or "Unknown Street",
        coords = data.coords,
        time = os.date('%H:%M')
    }

    -- Update Cooldown
    callCooldowns[citizenid] = currentTime

    -- Save to Database and get ID
    local insertId = MySQL.insert.await('INSERT INTO ems_calls (citizenid, name, message, street, coords) VALUES (?, ?, ?, ?, ?)', {
        citizenid, name, callData.message, callData.street, json.encode(callData.coords)
    })
    
    callData.id = insertId

    -- Notify all on-duty EMS
    local players = exports.qbx_core:GetQBPlayers()
    for _, p in pairs(players) do
        if p.PlayerData.job and Config.EMSJobs[p.PlayerData.job.name] and p.PlayerData.job.onduty then
            TriggerClientEvent('ems-dispatch:client:incomingCall', p.PlayerData.source, callData)
        end
    end

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'EMS Dispatch',
        description = 'Your emergency call has been transmitted to clinical staff.',
        type = 'success'
    })
end)

-- Acknowledge Call
RegisterNetEvent('ems-dispatch:server:acknowledgeCall', function(callId)
    local src = source
    if not hasEMSJob(src) then return end
    
    local player = exports.qbx_core:GetPlayer(src)
    local medicName = player.PlayerData.charinfo.firstname .. " " .. player.PlayerData.charinfo.lastname

    MySQL.update('UPDATE ems_calls SET responder = ?, status = ? WHERE id = ? AND (responder IS NULL OR responder = "")', {
        medicName, 'responded', callId
    })
end)

-- Callback to get history (Last 5 minutes only)
lib.callback.register('ems-dispatch:server:getHistory', function(source)
    if not hasEMSJob(source) then return {} end
    
    -- Filter by 5 minutes
    local results = MySQL.query.await('SELECT * FROM ems_calls WHERE time > (NOW() - INTERVAL 5 MINUTE) ORDER BY time DESC')
    local formatted = {}
    
    if results then
        for i=1, #results do
            local timeStr = os.date('%H:%M')
            if results[i].time then
                if type(results[i].time) == 'number' then
                    timeStr = os.date('%H:%M', math.floor(results[i].time / 1000))
                else
                    timeStr = tostring(results[i].time):sub(12, 16)
                    if timeStr == "" then timeStr = os.date('%H:%M') end
                end
            end

            table.insert(formatted, {
                id = results[i].id,
                name = results[i].name,
                message = results[i].message,
                street = results[i].street or "Unknown",
                responder = results[i].responder,
                coords = json.decode(results[i].coords),
                time = timeStr,
                status = results[i].status
            })
        end
    end
    
    return formatted
end)

-- Waypoint Trigger
RegisterNetEvent('ems-dispatch:server:setWaypoints', function(coords)
    local src = source
    if not hasEMSJob(src) then return end
    TriggerClientEvent('ems-dispatch:client:setGPS', src, coords)
end)
