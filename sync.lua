managerUser = peripheral.wrap("bottom")
managerFarm = peripheral.wrap("right")

toTransferItems = {"minecraft:bread","farmersdelight:pasta_with_meatballs"}

isCrafting = {}

asdf = managerUser.getCraftingCPUs()
-- textutils.slowPrint(textutils.serialize(asdf))

function concatTables(t1, t2)
    local newTable = {}
    for i = 1, #t1 do table.insert(newTable, t1[i]) end
    for i = 1, #t2 do table.insert(newTable, t2[i]) end
    return newTable
end

function findInTable(t, v)
    for i = 1, #t do if t[i] == v then return i end end
    return 0
end

function isItemCrafting(manager)
    local cpus, err = manager.getCraftingCPUs()
    if err then
        print(err)
        return
    end

    local found = {}

    for i = 1, #cpus do
        local cpu = cpus[i]

        job = cpu["craftingJob"]

        for t = 1, #toTransferItems do
            local item = toTransferItems[t]
            -- textutils.slowPrint(textutils.serialize(job))
            if not (job == nil) and not (job.storage == nil) then

                if job.storage.name == item then
                    found[item] = cpu
                    -- print(textutils.serialize(job))
                    break

                end
            end
        end
    end
    return found
end

function transfer()
    local isUserCrafting = isItemCrafting(managerUser)
    local isFarmCrafting = isItemCrafting(managerFarm)

    if (isUserCrafting == nil) then return end
    if (isFarmCrafting == nil) then return end

    -- textutils.slowPrint(textutils.serialize(isUserCrafting))
    for k, cpu in pairs(isUserCrafting) do
        if not isFarmCrafting[k] then

            print("starting crafting job for " .. k)

            if (isCrafting[cpu.storage] == nil) then
                isCrafting[cpu.storage] = math.huge
            end

            print(isCrafting[cpu.storage])
            print(cpu.craftingJob.elapsedTimeNanos)

            if (isCrafting[cpu.storage] < cpu.craftingJob.elapsedTimeNanos) then
                print("already crafting")

                isCrafting[cpu.storage] = cpu.craftingJob.elapsedTimeNanos
            else

                success, err = managerFarm.craftItem({
                    name = k,
                    count = cpu.craftingJob.storage.amount
                })
                if err then 
                  print(err)
                end
                if success and not err then
                    print("started crafting " .. k)
                    isCrafting[cpu.storage] = cpu.craftingJob.elapsedTimeNanos
                end
            end
        end
    end
    -- clear isCrafting for cpus that are done crafting

    for cStorage, time in pairs(isCrafting) do
        local isDone = true
        for k, cpu in pairs(isUserCrafting) do
            if cpu.storage == cStorage then
                isDone = false
                break
            end
        end
        if isDone then
            -- print("done crafting " .. cStorage)
            isCrafting[cStorage] = math.huge
        end
    end

end

while true do
    transfer()
    sleep(1)
end
