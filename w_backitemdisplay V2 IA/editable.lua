ESX = exports["es_extended"]:getSharedObject()
local lastDebuggedItems = {}

function GetPlayerInventory()
    local items = {}
    local foundInCycle = {}
    local playerData = ESX.GetPlayerData()

    if Config.Inventory == 'core_inventory' and playerData then
        
        -- 1. IDENTIFICATION : On prépare toutes les variantes possibles de l'ID
        -- Car on ne sait pas comment ton Core Inventory a été configuré
        local identifiersToCheck = {}
        
        if playerData.identifier then
            table.insert(identifiersToCheck, playerData.identifier) -- Ex: license:12345
            table.insert(identifiersToCheck, string.gsub(playerData.identifier, ":", "")) -- Ex: license12345
            
            -- Si c'est une license, on essaie de garder juste la partie après les deux points
            if string.match(playerData.identifier, ":") then
                local split = string.sub(playerData.identifier, string.find(playerData.identifier, ":") + 1)
                table.insert(identifiersToCheck, split) -- Ex: 12345
            end
        end

        if playerData.citizenid then
            table.insert(identifiersToCheck, playerData.citizenid) -- Spécifique à certains setups
        end

        -- 2. RECHERCHE DANS LES POCHES (Sac, Arme Principale, Secondaire)
        local inventoryPrefixes = { "content-", "primary-", "secondry-" }
        local alreadyScanned = {} -- Pour éviter de scanner 2 fois le même inventaire

        for _, id in ipairs(identifiersToCheck) do
            for _, prefix in ipairs(inventoryPrefixes) do
                local invName = prefix .. id
                
                if not alreadyScanned[invName] then
                    alreadyScanned[invName] = true
                    
                    -- On tente d'ouvrir cet inventaire
                    local success, invData = pcall(function() 
                        return exports['core_inventory']:getInventory(invName) 
                    end)

                    if success and invData then
                        for _, item in pairs(invData) do
                            local count = item.count or item.amount or 0
                            local name = item.name

                            -- Gestion format simple (juste le nom) ou objet complet
                            if type(item) == "string" then 
                                name = item 
                                count = 1 
                            end

                            if count > 0 and name then
                                -- Ajout à la liste finale
                                table.insert(items, { name = name, count = count })

                                -- DEBUG : Pour savoir quel était le bon ID
                                local debugKey = name .. "_" .. invName
                                foundInCycle[debugKey] = true
                                
                                if Config.Debug and string.find(name:lower(), "weapon") and not lastDebuggedItems[debugKey] then
                                    print("^2[DEBUG-CORE] SUCCÈS ! Arme trouvée dans [" .. invName .. "] : " .. name .. "^0")
                                    lastDebuggedItems[debugKey] = true
                                end
                            end
                        end
                    end
                end
            end
        end

    else 
        if Config.Debug then
            print("^1[ERREUR CRITIQUE] Type d'inventaire '" .. (Config.Inventory or "nil") .. "' non supporté ou données joueur introuvables.^0")
            print("^1[SOLUTION] Vérifie ton Config.Inventory (doit être 'core_inventory') et assure-toi qu'ESX est bien démarré.^0")
        end
    end

    -- Nettoyage mémoire Debug
    for key, _ in pairs(lastDebuggedItems) do
        if not foundInCycle[key] then lastDebuggedItems[key] = nil end
    end

    return items
end

function IsWeaponEquipped(weaponHash)
    local ped = PlayerPedId()
    local selectedWeapon = GetSelectedPedWeapon(ped)
    return selectedWeapon == weaponHash
end