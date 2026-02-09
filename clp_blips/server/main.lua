local blips = {}
local blipsFile = 'blips.json'

-- HIER DEINE erlaubten Rockstar-Licenses einfügen (nach /mylicense kopieren!)
-- Format: 'license:dein40-stelliger-hash'
local allowedLicenses = {
 'license:354ea42d19f14262e7e0f4e0397c5451d6351fd7',  -- Beispiel (aus deiner cfg)
    -- 'license:xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',  -- ← HIER DEINE EINFÜGEN!
    -- 'license:yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy',  -- zweite Person, falls nötig
}

-- Prüft ob der Spieler in der Liste ist
local function isAllowed(source)
    if #allowedLicenses == 0 then
        print("[clp_blips] WARNUNG: allowedLicenses ist leer! Niemand darf Commands nutzen.")
        return false
    end

    local playerIdents = GetPlayerIdentifiers(source)
    for _, ident in ipairs(playerIdents) do
        if string.match(ident, '^license:') then  -- nur license: Zeilen
            for _, allowed in ipairs(allowedLicenses) do
                if ident == allowed then
                    return true
                end
            end
        end
    end
    return false
end

-- Datei laden
local function loadBlips()
    local content = LoadResourceFile(GetCurrentResourceName(), blipsFile)
    if not content or content == "" then
        print("[clp_blips] blips.json leer/neu → erstelle []")
        SaveResourceFile(GetCurrentResourceName(), blipsFile, '[]', -1)
        blips = {}
        return
    end

    local decoded = json.decode(content)
    if type(decoded) == 'table' then
        blips = decoded
        print(("[clp_blips] Geladen: %d Blips"):format(#blips))
    else
        print("[clp_blips] JSON kaputt → leere Liste")
        blips = {}
    end
end

-- Datei speichern
local function saveBlips()
    local encoded = json.encode(blips, { indent = true })
    
    print("[clp_blips] SAVE VERSUCH:")
    print("Pfad: " .. GetResourcePath(GetCurrentResourceName()) .. "\\" .. blipsFile)
    print("Inhalt: " .. encoded)
    
    local success = SaveResourceFile(GetCurrentResourceName(), blipsFile, encoded, -1)
    print("[clp_blips] Save-Ergebnis: " .. tostring(success))  -- true oder false/nil
end

RegisterNetEvent('clp_blips:requestBlips')
AddEventHandler('clp_blips:requestBlips', function()
    TriggerClientEvent('clp_blips:loadBlips', source, blips)
end)

-- /createblip
RegisterCommand('createblip', function(source, args)
    if not isAllowed(source) then
        TriggerClientEvent('chat:addMessage', source, { color = {255,50,50}, args = {'[clp_blips]', 'Kein Zugriff – License nicht erlaubt.'} })
        return
    end

    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, { color = {255,200,100}, args = {'[clp_blips]', 'Nutze: /createblip "Name des Blips"'} })
        return
    end

    local label = table.concat(args, " ")
    TriggerClientEvent('clp_blips:createBlipAtPos', source, label)
end, false)

RegisterNetEvent('clp_blips:createBlipAtPos')
AddEventHandler('clp_blips:createBlipAtPos', function(label)
    local src = source
    local ped = GetPlayerPed(src)
    local coords = GetEntityCoords(ped)

    local data = {
        label = label,
        x = coords.x, y = coords.y, z = coords.z,
        sprite = Config.DefaultBlip.sprite,
        color = Config.DefaultBlip.color,
        scale = Config.DefaultBlip.scale,
        shortRange = Config.DefaultBlip.shortRange
    }

    table.insert(blips, data)
    saveBlips()
    TriggerClientEvent('clp_blips:addSingleBlip', -1, data)

    TriggerClientEvent('chat:addMessage', src, { color = {50,200,50}, args = {'[clp_blips]', 'Blip erstellt: ' .. label} })
end)

-- /deleteblip
RegisterCommand('deleteblip', function(source, args)
    if not isAllowed(source) then
        TriggerClientEvent('chat:addMessage', source, { color = {255,50,50}, args = {'[clp_blips]', 'Kein Zugriff – License nicht erlaubt.'} })
        return
    end

    if #args == 0 then
        TriggerClientEvent('chat:addMessage', source, { color = {255,200,100}, args = {'[clp_blips]', 'Nutze: /deleteblip "Genauer Name"'} })
        return
    end

    local label = table.concat(args, " ")

    for i = #blips, 1, -1 do
        if blips[i].label == label then
            table.remove(blips, i)
            saveBlips()
            TriggerClientEvent('clp_blips:removeBlipByLabel', -1, label)
            TriggerClientEvent('chat:addMessage', source, { color = {255,150,50}, args = {'[clp_blips]', 'Gelöscht: ' .. label} })
            return
        end
    end

    TriggerClientEvent('chat:addMessage', source, { color = {255,50,50}, args = {'[clp_blips]', 'Nicht gefunden: ' .. label} })
end, false)

-- Debug: Deine License anzeigen
RegisterCommand('mylicense', function(source)
    local idents = GetPlayerIdentifiers(source)
    local license = "Keine license: gefunden"

    for _, id in ipairs(idents) do
        if string.match(id, '^license:') then
            license = id
            break
        end
    end

    TriggerClientEvent('chat:addMessage', source, {
        color = {100,180,255},
        multiline = true,
        args = {'[clp_blips DEBUG]', 'Deine License:\n' .. license .. '\n\nKopiere das und füge es in server/main.lua -> allowedLicenses ein!'}
    })
end, false)

-- Start
AddEventHandler('onResourceStart', function(res)
    if res == GetCurrentResourceName() then
        print("[clp_blips] Gestartet – lade Blips...")
        loadBlips()
    end
end)