Config = {}

-- Active le mode Debug pour voir les erreurs dans la console F8 (Mettre sur false une fois que ça marche)
Config.Debug = true 

-- Choix de l'inventaire : 'default', 'core_inventory', 'ox_inventory'
-- Pour ESX Legacy, laisse souvent sur 'default' car Core se greffe dessus
Config.Inventory = 'core_inventory' 

-- Temps de rafraîchissement en ms (plus bas = plus fluide mais consomme plus)
Config.RefreshTime = 500

-- Liste des items ignorés (ne s'afficheront jamais dans le dos)
Config.IgnoredItems = {
    ['weapon_unarmed'] = true,
    ['weapon_petrolcan'] = true,
}