local mod_gui = require("mod-gui")

global.playerCraftTime = global.playerCraftTime or {}

-- Because of my supreme laziness this is a modified version of: https://stackoverflow.com/a/45376848
function FormatTime(time)
    local days = math.floor(time/86400)
    local hours = math.floor(math.fmod(time, 86400)/3600)
    local minutes = math.floor(math.fmod(time, 3600)/60)
    local seconds = math.floor(math.fmod(time, 60))

    local printDays = days > 0
    local printHours = hours > 0 or printDays
    local printMinutes = minutes > 0 or printHours

    return "" .. (printDays and (days .. "d ") or "") .. (printHours and (hours .. "h ") or "") .. (printMinutes and (string.format("%02d", minutes) .. "m ") or "") .. seconds .. "s"
end

function GetCraftTime(player)
    if player.character == nil then
        return 0.0
    end
    
    local queue = player.crafting_queue

    if not queue then
        return 0.0
    end

    local craftTime = 0.0
    
    for i, qItem in ipairs(queue) do
        local recipe = game.recipe_prototypes[qItem.recipe]
        local qItemCraftTime = recipe.energy * qItem.count / (1.0 + player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier)
        craftTime = craftTime + qItemCraftTime

        -- Reduce the crafting time using the progress on the current item being crafted
        if i == 1 then
            craftTime = craftTime - ((recipe.energy / (1.0 + player.force.manual_crafting_speed_modifier + player.character_crafting_speed_modifier)) * player.crafting_queue_progress)
        end
        
    end

    return craftTime;
end

-- This will get a player's craft time and assign it to them
function SetPlayerCraftTime(player)
    global.playerCraftTime = global.playerCraftTime or {}
    global.playerCraftTime[player.index] = GetCraftTime(player)
end

function GetPlayerCraftTime(player)
    local cT = global.playerCraftTime[player.index] or 0.0
    if cT < 0.0 then cT = 0.0 end
    return cT
end

-- Reduce player craft time each frame
function DecrementPlayerCraftTime(player)
    local cT = GetPlayerCraftTime(player)
    if cT > 0.0 then
        global.playerCraftTime[player.index] = cT - (1.0 / 60.0) -- TODO: Test this during poor UPS
    end
end

function RemoveOldEl(player)
    if global.player_time_text and global.player_time_text[player.index] then
        rendering.destroy(global.player_time_text[player.index])
        global.player_time_text[player.index] = nil
    end
end

function PrintCraftTime()
    global.playerCraftTime = global.playerCraftTime or {}
    local elName = "craft_time"

    -- Go back to using the for loop to make this multiplayer compatible
    for i, player in ipairs(game.connected_players) do
        
        if player and player.character then
            RemoveOldEl(player)
            local superUI = player.gui.left -- Makes it easy to change which ui we want to add the element to
            local ui = superUI[elName] or superUI.add{type = "frame", name = elName, caption = "", direction = "horizontal", style = mod_gui.frame_style}
            
            if ui then
                ui.style.bottom_padding = 4
                local time = GetPlayerCraftTime(player)
                DecrementPlayerCraftTime(player)
                ui.caption = ((time > 0.1) and ("Crafting Time: " .. FormatTime(time)) or "")
                ui.visible = time > 0.1
            end
        end
    end
end

function PlayerCancelledCrafting(e)
    SetPlayerCraftTime(game.get_player(e.player_index))
end

function PlayerAddItemToQueue(e)
    SetPlayerCraftTime(game.get_player(e.player_index))
end

function PlayerJoinedGame(e)
    SetPlayerCraftTime(game.get_player(e.player_index))
end

script.on_event(defines.events.on_tick, PrintCraftTime)
script.on_event(defines.events.on_player_cancelled_crafting, PlayerCancelledCrafting)
script.on_event(defines.events.on_pre_player_crafted_item, PlayerAddItemToQueue)
script.on_event(defines.events.on_player_joined_game, PlayerJoinedGame)
