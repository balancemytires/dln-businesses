QBCore = nil
TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)

RegisterNetEvent('dln-businesses:payCompany')
AddEventHandler('dln-businesses:payCompany', function(company, amount)
    exports['ghmattimysql']:execute('SELECT * FROM `businesses` WHERE `name` = @name', {['@name'] = company}, function(results)
        if results[1] then
            if results[1].name == company then
                local newamt = tonumber(amount) + results[1].companyfunds
                exports['ghmattimysql']:execute('UPDATE `businesses` SET `companyfunds` = @amt WHERE `name` = @name', {
                    ['@amt'] = newamt,
                    ['@name'] = company
                })
            end
        end
    end)
end)

QBCore.Functions.CreateCallback('dln-businesses:canChargeCompany', function(source, cb, company, amount)
    exports['ghmattimysql']:execute('SELECT * FROM `businesses` WHERE `name` = @name', {['@name'] = company}, function(results)
        if results[1] then
            if results[1].name == company then
                local companyfunds = results[1].companyfunds
                if companyfunds - amount > 0 then
                    cb(true)
                else
                    cb(false)
                end
            end
        end
    end)
end)

RegisterNetEvent('dln-businesses:chargeCompany')
AddEventHandler('dln-businesses:chargeCompany', function(company, amount)
    exports['ghmattimysql']:execute('SELECT * FROM `businesses` WHERE `name` = @company', {['@company'] = company}, function(results)
        if results[1] then
            if results[1].name == company then
                local newamt = results[1].companyfunds - amount
                exports['ghmattimysql']:execute('UPDATE `businesses` SET `companyfunds` = @amt WHERE `name` = @name', {
                    ['@amt'] = newamt,
                    ['@name'] = company
                })
            end
        end
    end)
end)


RegisterNetEvent('dln-businesses:logSomething')
AddEventHandler('dln-businesses:logSomething', function(company, newlog, type)
    exports['ghmattimysql']:execute('SELECT * FROM `businesses` WHERE `name` = @company', {['@company'] = company}, function(results)
        if results[1] then
            if results[1].name == company then
                companylog = json.decode(results[1].companylogs)
                if table.size(companylog) >= 300 then
                    table.remove(companylog, 1)
                end
                table.insert(companylog, {type = type, text = newlog})
                exports['ghmattimysql']:execute("UPDATE `businesses` SET `companylogs` = @companylog WHERE `name` = @name", {
                    ['@companylog'] = json.encode(companylog),
                    ['@name'] = company
                })
            end
        end
    end)
end)



function getCompanyLogs(company)
    local companylogs = nil
    exports['ghmattimysql']:execute('SELECT * FROM `businesses` WHERE `name` = @company', {['@company'] = company}, function(results)
        if results[1] then
            if results[1].name == company then
                companylogs = json.decode(results[1].companylogs)
            end
        end
    end)
    return companylogs
end

function table.size(tab)
    local length = 0
    for _ in pairs(tab) do length = length + 1 end
    return length
end

RegisterNetEvent('dln-businesses:changerank')
AddEventHandler('dln-businesses:changerank', function(citizenid, rank)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.level >= Cfg.Ranks[Player.PlayerData.job.name].promoteRank and tonumber(rank) < Player.PlayerData.job.level then
        promotePerson(citizenid, Player.PlayerData.job.name, rank, src)
    end
end)


function promotePerson(citizenid, company, newrank, src)
    for k,v in pairs(QBCore.Functions.GetPlayers()) do
        local pData = QBCore.Functions.GetPlayer(v)
        if pData.PlayerData.citizenid == citizenid then
            pData.Functions.SetJob(company, newrank)
            TriggerEvent('dln-businesses:logSomething', company,  GetCharacterName(src) .. ' has promoted or demoted ' .. GetCharacterName(v) ' to '.. newrank ..'.')
            TriggerClientEvent('dln-phone:updateCompanyPage', src)
        end
    end
end

function GetCharacterName(source)
	local src = source
	local ply = QBCore.Functions.GetPlayer(src)
	local firstname = ply.PlayerData.charinfo.firstname
	local lastname = ply.PlayerData.charinfo.lastname
	local name = firstname .. ' ' .. lastname
	return name
end

QBCore.Commands.Add("hire", "Hire someone", {{name="id", help="Player ID"}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.level >= 5 and tonumber(args[1]) ~= src then
        hirePerson(tonumber(args[1]), Player.PlayerData.job.name, src)
    end
end)

function hirePerson(pid, company, src)
    local otherPly = QBCore.Functions.GetPlayer(pid)
    if not otherPly then return end
    local srcPly = QBCore.Functions.GetPlayer(src)
    if not srcPly then return end

    if otherPly.PlayerData.job.name == "unemployed" then
        otherPly.Functions.SetJob(company, 1)
        TriggerClientEvent('QBCore:Notify', src, "You have hired "..otherPly.PlayerData.citizenid.."/"..pid)
        TriggerEvent('dln-businesses:logSomething', company, GetCharacterName(pid) .. ' has been hired by '.. GetCharacterName(src)..'.')
        TriggerClientEvent('QBCore:Notify', pid, "You have been hired")
    else
        TriggerClientEvent('QBCore:Notify', src, "The person you are trying to hire already has a job.")
    end

end


QBCore.Commands.Add("fire", "Fire someone", {{name="id", help="Player ID"}}, false, function(source, args)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player.PlayerData.job.level >= 5 and tonumber(args[1]) ~= src then
        firePerson(tonumber(args[1]), Player.PlayerData.job.name, src)
    end
end)

function firePerson(pid, company, src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local OPlayer = QBCore.Functions.GetPlayer(pid)
    if not OPlayer then return end

    if OPlayer.PlayerData.job.name == company then
        if OPlayer.PlayerData.job.level >= Player.PlayerData.job.level then
            TriggerClientEvent('QBCore:Notify', src, "You are either equal to this persons rank or they are higher than you.")
        else
            OPlayer.Functions.SetJob("unemployed", 0)
            TriggerClientEvent('QBCore:Notify', v, "You have been fired")
            TriggerEvent('dln-businesses:logSomething', company, GetCharacterName(pid) .. ' has been fired by '.. GetCharacterName(src)..'.')
            TriggerClientEvent('QBCore:Notify', src, "You have fired "..OPlayer.PlayerData.citizenid.."/"..pid)
        end
    else
        TriggerClientEvent('QBCore:Notify', src, "The person you are trying to fire doesn't work for you.")
    end
end

QBCore.Commands.Add("quitjob", "Quit your job", {}, false, function(source, args)
    local pData = QBCore.Functions.GetPlayer(source)
    if pData.PlayerData.job.name ~= "unemployed" then
        TriggerClientEvent('QBCore:Notify', source, "You have quit your job. You are now unemployed.")
        pData.Functions.SetJob("unemployed", 0)
    else
        TriggerClientEvent('QBCore:Notify', source, "You are already unemployed.")
    end
end)