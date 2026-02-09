local createdBlips = {}

-- Hilfsfunktion: Blip erstellen
local function createBlip(data)
    local blip = AddBlipForCoord(data.x, data.y, data.z)
    SetBlipSprite(blip, data.sprite or Config.DefaultBlip.sprite)
    SetBlipColour(blip, data.color or Config.DefaultBlip.color)
    SetBlipScale(blip, data.scale or Config.DefaultBlip.scale)
    SetBlipAsShortRange(blip, data.shortRange ~= false)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(data.label)
    EndTextCommandSetBlipName(blip)

    createdBlips[data.label] = blip

    print(("[clp_blips] Blip erstellt (client): %s @ %.1f, %.1f, %.1f"):format(data.label, data.x, data.y, data.z))
end

-- Alle Blips vom Server erhalten → beim Join / Reload
RegisterNetEvent('clp_blips:loadBlips')
AddEventHandler('clp_blips:loadBlips', function(blipsData)
    -- Alte Blips löschen
    for _, blip in pairs(createdBlips) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
    createdBlips = {}

    -- Neue Blips erstellen
    for _, data in ipairs(blipsData or {}) do
        createBlip(data)
    end

    print(("[clp_blips] %d Blips vom Server geladen"):format(#blipsData))
end)

-- Ein einzelner neuer Blip wurde erstellt
RegisterNetEvent('clp_blips:addSingleBlip')
AddEventHandler('clp_blips:addSingleBlip', function(data)
    createBlip(data)
end)

-- Ein Blip wurde gelöscht
RegisterNetEvent('clp_blips:removeBlipByLabel')
AddEventHandler('clp_blips:removeBlipByLabel', function(label)
    if createdBlips[label] and DoesBlipExist(createdBlips[label]) then
        RemoveBlip(createdBlips[label])
        createdBlips[label] = nil
        print(("[clp_blips] Blip entfernt (client): %s"):format(label))
    end
end)

-- Resource-Start → Blips anfordern
AddEventHandler('onClientResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
    TriggerServerEvent('clp_blips:requestBlips')
end)