local shownBossMenu = false
local DynamicMenuItems = {}
local jobs = exports.qbx_core:GetJobs()

-- UTIL
local function CloseMenuFull()
    lib.hideContext()
    lib.hideTextUI()
    shownBossMenu = false
end

local function AddBossMenuItem(data, id)
    local menuID = id or #DynamicMenuItems + 1
    DynamicMenuItems[menuID] = deepcopy(data)
    return menuID
end

exports("AddBossMenuItem", AddBossMenuItem)

local function RemoveBossMenuItem(id)
    DynamicMenuItems[id] = nil
end

exports("RemoveBossMenuItem", RemoveBossMenuItem)

AddEventHandler('onResourceStart', function(resource)
    if resource ~= GetCurrentResourceName() then return end
end)

RegisterNetEvent('qb-bossmenu:client:OpenMenu', function()
    if not QBX.PlayerData.job.name or not QBX.PlayerData.job.isboss then return end

    local bossMenu = {
        {
            title = "Manage Employees",
            description = "Check your Employees List",
            icon = 'fa-solid fa-list',
            event = 'qb-bossmenu:client:employeelist'
        },
        {
            title = "Hire Employees",
            description = "Hire Nearby Civilians",
            icon = 'fa-solid fa-hand-holding',
            event = 'qb-bossmenu:client:HireMenu'
        },
        {
            title = "Storage Access",
            description = "Open Storage",
            icon = 'fa-solid fa-box-open',
            event = 'qb-bossmenu:client:Stash'
        },
        {
            title = "Outfits",
            description = "See Saved Outfits",
            icon = 'fa-solid fa-shirt',
            event = 'qb-bossmenu:client:Wardrobe'
        },
        {
            title = "Money Management",
            description = "Check your Company Balance",
            icon = 'fa-solid fa-sack-dollar',
            event = 'qb-bossmenu:client:SocietyMenu'
        }
    }

    for _, v in pairs(DynamicMenuItems) do
        bossMenu[#bossMenu + 1] = v
    end

    lib.registerContext({
        id = 'qb_management_open_bossMenu',
        title = "Boss Menu - " .. string.upper(QBX.PlayerData.job.label),
        options = bossMenu
    })
    lib.showContext('qb_management_open_bossMenu')
end)

RegisterNetEvent('qb-bossmenu:client:employeelist', function()
    local EmployeesMenu = {}

    local employees = lib.callback.await('qb-bossmenu:server:GetEmployees', false, QBX.PlayerData.job.name)
    for _, v in pairs(employees) do
        EmployeesMenu[#EmployeesMenu + 1] = {
            title = v.name,
            description = v.grade.name,
            event = 'qb-bossmenu:client:ManageEmployee',
            args = {
                player = v,
                work = QBX.PlayerData.job
            }
        }
    end

    EmployeesMenu[#EmployeesMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-bossmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'qb_management_open_bossManage',
        title = "Manage Employees - " .. string.upper(QBX.PlayerData.job.label),
        options = EmployeesMenu
    })

    lib.showContext('qb_management_open_bossManage')
end)

RegisterNetEvent('qb-bossmenu:client:ManageEmployee', function(data)
    local EmployeeMenu = {}

    for k, v in pairs(jobs[data.work.name].grades) do
        EmployeeMenu[#EmployeeMenu + 1] = {
            title = v.name,
            description = "Grade: " .. k,
            serverEvent = 'qb-bossmenu:server:GradeUpdate',
            args = {
                cid = data.player.empSource,
                grade = tonumber(k),
                gradename = v.name
            }
        }
    end

    EmployeeMenu[#EmployeeMenu + 1] = {
        title = "Fire Employee",
        icon = 'fa-solid fa-user-large-slash',
        serverEvent = 'qb-bossmenu:server:FireEmployee',
        args = data.player.empSource
    }

    EmployeeMenu[#EmployeeMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-bossmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'qb_management_open_bossMember',
        title = "Manage " .. data.player.name .. " - " .. string.upper(QBX.PlayerData.job.label),
        options = EmployeeMenu
    })

    lib.showContext('qb_management_open_bossMember')
end)

RegisterNetEvent('qb-bossmenu:client:Stash', function()
    exports.ox_inventory:openInventory('stash', 'boss_' .. QBX.PlayerData.job.name)
end)

RegisterNetEvent('qb-bossmenu:client:Wardrobe', function()
    TriggerEvent('qb-clothing:client:openOutfitMenu')
end)

RegisterNetEvent('qb-bossmenu:client:HireMenu', function()
    local HireMenu = {}

    local players = lib.callback.await('qb-bossmenu:getplayers')
    for _, v in pairs(players) do
        if v and v ~= cache.playerId then
            HireMenu[#HireMenu + 1] = {
                title = v.name,
                description = "Citizen ID: " .. v.citizenid .. " - ID: " .. v.sourceplayer,
                serverEvent = 'qb-bossmenu:server:HireEmployee',
                args = v.sourceplayer
            }
        end
    end

    HireMenu[#HireMenu + 1] = {
        title = "Return",
        icon = 'fa-solid fa-angle-left',
        event = 'qb-bossmenu:client:OpenMenu'
    }

    lib.registerContext({
        id = 'qb_management_open_bossHire',
        title = "Hire Employees - " .. string.upper(QBX.PlayerData.job.label),
        options = HireMenu
    })

    lib.showContext('qb_management_open_bossHire')
end)

RegisterNetEvent('qb-bossmenu:client:SocietyMenu', function()
    local amount = lib.callback.await('qb-bossmenu:server:GetAccount', false, QBX.PlayerData.job.name)
    local SocietyMenu = {
        {
            title = "Deposit",
            icon = 'fa-solid fa-money-bill-transfer',
            description = "Deposit Money into account",
            event = 'qb-bossmenu:client:SocetyDeposit',
            args = amount
        },
        {
            title = "Withdraw",
            icon = 'fa-solid fa-money-bill-transfer',
            description = "Withdraw Money from account",
            event = 'qb-bossmenu:client:SocetyWithDraw',
            args = amount
        },
        {
            title = "Return",
            icon = 'fa-solid fa-angle-left',
            event = 'qb-bossmenu:client:OpenMenu'
        }
    }

    lib.registerContext({
        id = 'qb_management_open_bossSociety',
        title = "Balance: $" .. comma_value(amount) .. " - " .. string.upper(QBX.PlayerData.job.label),
        options = SocietyMenu
    })

    lib.showContext('qb_management_open_bossSociety')
end)

RegisterNetEvent('qb-bossmenu:client:SocetyDeposit', function(money)
    local deposit = lib.inputDialog('Deposit Money', {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = comma_value(money)
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not deposit then
        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    if not deposit[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    local depositAmount = tonumber(deposit[2])

    if depositAmount <= 0 then
        exports.qbx_core:Notify('Amount needs to be higher than zero!', 'error')

        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-bossmenu:server:depositMoney', depositAmount)
end)

RegisterNetEvent('qb-bossmenu:client:SocetyWithDraw', function(money)
    local withdraw = lib.inputDialog("Withdraw Money", {
        {
            type = 'input',
            label = "Available Balance",
            disabled = true,
            default = comma_value(money)
        },
        {
            type = 'number',
            label = "Amount"
        }
    })

    if not withdraw then
        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    if not withdraw[2] then
        exports.qbx_core:Notify('Amount value is missing!', 'error')

        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    local withdrawAmount = tonumber(withdraw[2])

    if withdrawAmount > tonumber(money) then
        exports.qbx_core:Notify('You can\'t withdraw that amount of money!', 'error')

        TriggerEvent('qb-bossmenu:client:SocietyMenu')
        return
    end

    TriggerServerEvent('qb-bossmenu:server:withdrawMoney', withdrawAmount)
end)

-- MAIN THREAD
CreateThread(function()
    if Config.UseTarget then
        for job, zones in pairs(Config.BossMenuZones) do
            for i = 1, #zones do
                local data = zones[i]
                exports.ox_target:addBoxZone({
                    coords = data.coords,
                    size = data.size,
                    rotation = data.rotation,
                    debug = Config.PolyDebug,
                    options = {
                        {
                            name = 'boss_menu',
                            event = 'qb-bossmenu:client:OpenMenu',
                            icon = "fa-solid fa-right-to-bracket",
                            label = "Boss Menu",
                            canInteract = function()
                                return job == QBX.PlayerData.job.name and QBX.PlayerData.job.isboss
                            end
                        }
                    }
                })
            end
        end
    else
        local wait
        while true do
            local pos = GetEntityCoords(cache.ped)
            local nearBossmenu = false
            wait = 1000

            if QBX.PlayerData.job then
                wait = 100
                for k, v in pairs(Config.BossMenus) do
                    for _, coords in pairs(v) do
                        if k == QBX.PlayerData.job.name and QBX.PlayerData.job.isboss then
                            if #(pos - coords) <= 1.5 then
                                nearBossmenu = true

                                if not shownBossMenu then
                                    lib.showTextUI("[E] - Open Job Management")
                                    shownBossMenu = true
                                end

                                wait = 0

                                if IsControlJustReleased(0, 38) then
                                    lib.hideTextUI()
                                    TriggerEvent('qb-bossmenu:client:OpenMenu')
                                end
                            end
                        end
                    end
                end

                if not nearBossmenu then
                    wait = 1000
                    if shownBossMenu then
                        CloseMenuFull()
                        shownBossMenu = false
                    end
                end
            end

            Wait(wait)
        end
    end
end)
