-- EMS Dispatch Client Logic
local PlayerData = {}
local isUIOpen = false

local function getPlayerData()
    return exports.qbx_core:GetPlayerData()
end

local function hasEMSJob()
    local data = getPlayerData()
    return data.job and Config.EMSJobs[data.job.name] and data.job.onduty
end

local isEMS = false
local lastCallId = nil
local lastCallCoords = nil

-- Cache Job Status
local function updateJob()
    local playerData = exports.qbx_core:GetPlayerData()
    isEMS = playerData and playerData.job and Config.EMSJobs[playerData.job.name] and playerData.job.onduty
end

AddEventHandler('QBCore:Client:OnJobUpdate', function(job)
    updateJob()
end)

AddEventHandler('QBCore:Client:SetDuty', function(onduty)
    updateJob()
end)

AddEventHandler('onResourceStart', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        updateJob()
    end
end)

-- Incoming Call Event
RegisterNetEvent('ems-dispatch:client:incomingCall', function(data)
    if not isEMS then return end
    
    -- Play Notification Sound
    PlaySoundFrontend(-1, "Event_Message_Inbound", "GTAO_FM_Events_Soundset", 1)
    
    -- Store latest data for [E] Mark GPS & Acknowledgment
    lastCallId = data.id
    lastCallCoords = data.coords
    
    -- Create Blip on Map
    createCallBlip(data.coords)

    -- Send to NUI for Overlay
    SendNUIMessage({
        type = 'new_call',
        payload = data
    })
end)

-- Optimized Keybind [E] Listener
CreateThread(function()
    while true do
        local sleep = 1000
        if lastCallCoords and isEMS then
            sleep = 0
            if IsControlJustPressed(0, 38) then -- [E]
                SetNewWaypoint(lastCallCoords.x, lastCallCoords.y)
                
                -- Acknowledge to server
                if lastCallId then
                    TriggerServerEvent('ems-dispatch:server:acknowledgeCall', lastCallId)
                end

                lib.notify({
                    title = 'GPS Synced',
                    description = 'Responding to emergency call.',
                    type = 'success'
                })
                
                lastCallCoords = nil -- Reset after use
                lastCallId = nil
            end
        end
        Wait(sleep)
    end
end)

function createCallBlip(coords)
    local blip = AddBlipForCoord(coords.x, coords.y, coords.z)
    SetBlipSprite(blip, 280) -- Person icon
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, 1.2)
    SetBlipColour(blip, 1) -- Red
    SetBlipAsShortRange(blip, false)
    
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Medical Assistance Needed")
    EndTextCommandSetBlipName(blip)
    
    PulseBlip(blip)
    
    -- Remove after 2 minutes
    SetTimeout(120000, function()
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end)
end

-- Open History UI
local function openDispatchHistory()
    if not hasEMSJob() then return end
    
    if not isUIOpen then
        isUIOpen = true
        SetNuiFocus(true, true)
        
        -- Fetch Data from Server
        lib.callback('ems-dispatch:server:getHistory', false, function(history)
            SendNUIMessage({
                type = 'open_history',
                history = history
            })
        end)
    end
end

-- Command /311 for citizens (standard RegisterCommand)
RegisterCommand('311', function(source, args)
    local message = table.concat(args, " ")
    if message == "" then message = "Tolong pak!" end
    
    local coords = GetEntityCoords(cache.ped)
    local streetHash = GetStreetNameAtCoord(coords.x, coords.y, coords.z)
    local streetName = GetStreetNameFromHashKey(streetHash)
    local zoneName = GetLabelText(GetNameOfZone(coords.x, coords.y, coords.z))

    print("^3[EMS-Dispatch]^7 Sending /311 call...")
    TriggerServerEvent('ems-dispatch:server:sendCall', {
        message = message,
        street = streetName .. ", " .. zoneName,
        coords = { x = coords.x, y = coords.y, z = coords.z }
    })
end, false)

-- Keybind "U" using Qbox Command/Keybind system
RegisterCommand('openemscalls', function()
    print("^3[EMS-Dispatch]^7 Attempting to open history...")
    openDispatchHistory()
end, false)

RegisterKeyMapping('openemscalls', 'Open EMS Dispatch History', 'keyboard', Config.Keybind)

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    isUIOpen = false
    SetNuiFocus(false, false)
    cb('ok')
end)

RegisterNUICallback('setGPS', function(data, cb)
    if data and data.x and data.y then
        SetNewWaypoint(data.x, data.y)
        
        -- Acknowledge to server if calling from history
        if data.callId then
            TriggerServerEvent('ems-dispatch:server:acknowledgeCall', data.callId)
        end

        lib.notify({
            title = 'GPS Set',
            description = 'Responding to medical call.',
            type = 'success'
        })
    end
    cb('ok')
end)

RegisterNetEvent('ems-dispatch:client:setGPS', function(coords)
    if coords and coords.x then
        SetNewWaypoint(coords.x, coords.y)
    end
end)
