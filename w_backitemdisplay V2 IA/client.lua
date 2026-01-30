local attached_objects = {} 
local item_data = {} 
local isLoaded = false

-- 1. Chargement des données + Init ESX
Citizen.CreateThread(function()
    Wait(1000)
    
    local data = LoadResourceFile(GetCurrentResourceName(), 'data.json')
    if data then
        item_data = json.decode(data)
        if Config.Debug then 
            print("^2[DEBUG] data.json chargé. Armes configurées: " .. GetTableSize(item_data) .. "^0") 
        end
    else
        print("^1[ERREUR] Impossible de charger data.json !^0")
    end
    
    while not ESX do
        Wait(100)
        ESX = exports["es_extended"]:getSharedObject()
    end
    
    while not ESX.IsPlayerLoaded() do 
        Wait(500) 
    end
    
    isLoaded = true-- On s'assure qu'ESX est bien chargé
ESX = exports["es_extended"]:getSharedObject()

-- Variable pour se souvenir des items déjà affichés dans la console (Anti-Spam)
local lastDebuggedItems = {}

function GetPlayerInventory()
    local items = {}
    local inventory = {}

    -- On récupère les données du joueur
    local playerData = ESX.GetPlayerData()

    if playerData and playerData.inventory then
        inventory = playerData.inventory
    end

    -- Liste des items trouvés dans ce cycle (pour nettoyer le cache ensuite)
    local foundInCycle = {}

    for _, item in pairs(inventory) do
        local count = item.count or item.amount or 0

        if count > 0 then
            table.insert(items, {
                name = item.name,
                count = count
            })
            
            local debugKey = item.name .. "_" .. tostring(count)
            foundInCycle[debugKey] = true

            -- DIAGNOSTIC INTELLIGENT (Anti-Spam)
            if Config.Debug and string.find(item.name:lower(), "weapon") then
                if not lastDebuggedItems[debugKey] then
                    print("^2[DEBUG] Item détecté : " .. item.name .. " (x" .. count .. ")^0")
                    lastDebuggedItems[debugKey] = true
                end
            end
        end
    end

    -- Nettoyage de la mémoire anti-spam pour les items qu'on ne possède plus
    for key, _ in pairs(lastDebuggedItems) do
        if not foundInCycle[key] then
            lastDebuggedItems[key] = nil
        end
    end

    return items
end

function IsWeaponEquipped(weaponHash)
    local ped = PlayerPedId()
    local selectedWeapon = GetSelectedPedWeapon(ped)
    return selectedWeapon == weaponHash
end
    if Config.Debug then print("^2[DEBUG] Script prêt.^0") end
end)

function GetTableSize(t)
    local count = 0
    for _, __ in pairs(t) do count = count + 1 end
    return count
end

local function AttachWeapon(model, bone, x, y, z, xR, yR, zR)
    local ped = PlayerPedId()
    local boneIndex = GetPedBoneIndex(ped, bone)
    local hash = GetHashKey(model)

    if boneIndex == -1 then
        if Config.Debug then print("^1[ERREUR] Os invalide : " .. bone .. "^0") end
        return nil
    end

    RequestModel(hash)
    local attempts = 0
    while not HasModelLoaded(hash) and attempts < 10 do
        Wait(100)
        attempts = attempts + 1
    end

    if not HasModelLoaded(hash) then
        if Config.Debug then print("^1[ERREUR] Modèle invalide : " .. model .. "^0") end
        return nil
    end

    -- Création de l'objet
    local object = CreateObject(hash, GetEntityCoords(ped), true, true, false)
    
    -- Délai de sécurité augmenté pour s'assurer que le réseau a pris en compte l'objet
    Wait(100)

    -- Désactivation totale des collisions pour éviter que l'arme ne pousse le joueur
    SetEntityCompletelyDisableCollision(object, false, true)

    -- NOUVEAUX PARAMÈTRES D'ATTACHEMENT (STRICT PINNING)
    -- On passe p9 (soft pinning) à false (0) pour forcer un collage strict
    -- AttachEntityToEntity(entity1, entity2, boneIndex, x, y, z, xRot, yRot, zRot, p9, useSoftPinning, collision, isPed, vertexIndex, fixedRot)
    AttachEntityToEntity(object, ped, boneIndex, x, y, z, xR, yR, zR, 0, 0, 0, 0, 2, 1)
    
    -- VÉRIFICATION DE SÉCURITÉ
    -- Si l'attachement a échoué (l'arme est restée sur place), on réessaie
    if not IsEntityAttached(object) then
        if Config.Debug then print("^3[DEBUG] Premier attachement échoué, nouvelle tentative...^0") end
        Wait(100)
        AttachEntityToEntity(object, ped, boneIndex, x, y, z, xR, yR, zR, 0, 0, 0, 0, 2, 1)
    end

    if Config.Debug then print("^2[DEBUG] Objet attaché (Strict) : " .. model .. "^0") end
    return object
end

Citizen.CreateThread(function()
    while true do
        local sleep = Config.RefreshTime
        local ped = PlayerPedId()

        if isLoaded and DoesEntityExist(ped) and not IsEntityDead(ped) then
            
            local inventory = GetPlayerInventory()
            local currentBackItems = {}

            for _, item in pairs(inventory) do
                local itemName = item.name:lower()
                
                if item_data[itemName] and not Config.IgnoredItems[itemName] then
                    local weaponHash = GetHashKey(itemName)
                    
                    if not IsWeaponEquipped(weaponHash) then
                        currentBackItems[itemName] = true
                        
                        if not attached_objects[itemName] then
                            local settings = item_data[itemName]
                            local obj = AttachWeapon(
                                settings.model,
                                settings.bone,
                                settings.x, settings.y, settings.z,
                                settings.xR, settings.yR, settings.zR
                            )
                            if obj then
                                attached_objects[itemName] = obj
                            end
                        end
                    else
                        if attached_objects[itemName] then
                            DeleteEntity(attached_objects[itemName])
                            attached_objects[itemName] = nil
                        end
                    end
                end
            end

            for item, objectHandle in pairs(attached_objects) do
                if not currentBackItems[item] then
                    DeleteEntity(objectHandle)
                    attached_objects[item] = nil
                end
            end
        else
            for item, objectHandle in pairs(attached_objects) do
                DeleteEntity(objectHandle)
                attached_objects[item] = nil
            end
        end

        Wait(sleep)
    end
end)

AddEventHandler('onResourceStop', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then return end
    for _, objectHandle in pairs(attached_objects) do
        DeleteEntity(objectHandle)
    end
end)