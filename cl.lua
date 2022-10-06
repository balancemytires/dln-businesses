QBCore = nil
isLoggedIn = false

companies = {}

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(10)
        if QBCore == nil then
            TriggerEvent('QBCore:GetObject', function(obj) QBCore = obj end)
            Citizen.Wait(200)
        end
    end
end)

RegisterNetEvent("QBCore:Client:OnPlayerUnload")
AddEventHandler("QBCore:Client:OnPlayerUnload", function()
    isLoggedIn = false
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded")
AddEventHandler("QBCore:Client:OnPlayerLoaded", function()
	isLoggedIn = true
	PlayerData = QBCore.Functions.GetPlayerData()
	
    TriggerServerEvent('dln-businesses:retreiveCompanies')
end)

RegisterNetEvent('dln-businesses:onJobUpdate')
AddEventHandler('dln-businesses:onJobUpdate', function(newJob, newJobLevel)
    myJob = newJob
    myJobLevel = newJobLevel
end)

RegisterNetEvent('dln-businesses:returnCompanies')
AddEventHandler('dln-businesses:returnCompanies', function(comp)
    companies = comp
end)

RegisterNetEvent('dln-businesses:updatejob')
AddEventHandler('dln-businesses:updatejob', function(jobname, jobgrade)
	
end)