local function requestData(url)
    local success, response = pcall(function()
        return request({ Url = url, Method = "GET" }).Body
    end)
    
    if success then
        return game:GetService("HttpService"):JSONDecode(response)
    else
        warn("Failed to fetch data: " .. tostring(response))
        return nil
    end
end

local function getCurrentlyWearing(userId)
    local url = "https://avatar.roblox.com/v1/users/" .. userId .. "/currently-wearing"
    local data = requestData(url)
    return data and data.assetIds or nil
end

local function getAssetType(assetId)
    local url = "https://economy.roblox.com/v2/assets/" .. assetId .. "/details"
    local data = requestData(url)
    return data and data.AssetTypeId or nil
end

function createWeld(partA, partB)
    local weld = Instance.new("Weld")
    weld.Part0 = partA.Parent
    weld.Part1 = partB.Parent
    weld.C0 = partA.CFrame
    weld.C1 = partB.CFrame
    weld.Parent = partA.Parent
    return weld
end

local function createNamedWeld(weldName, parent, part0, part1, c0, c1)
    local weld = Instance.new("Weld")
    weld.Name = weldName
    weld.Part0 = part0
    weld.Part1 = part1
    weld.C0 = c0
    weld.C1 = c1
    weld.Parent = parent
    return weld
end

local function findAttachmentInDescendants(object, attachmentName)
    for _, child in pairs(object:GetChildren()) do
        if child:IsA("Attachment") and child.Name == attachmentName then
            return child
        elseif not child:IsA("Accoutrement") and not child:IsA("Tool") then
            local foundAttachment = findAttachmentInDescendants(child, attachmentName)
            if foundAttachment then
                return foundAttachment
            end
        end
    end
end

function attachHatToCharacter(character, hat)
    hat.Parent = character
    local handle = hat:FindFirstChild("Handle")
    if handle then
        local attachment = handle:FindFirstChildOfClass("Attachment")
        if attachment then
            local matchingAttachment = findAttachmentInDescendants(character, attachment.Name)
            if matchingAttachment then
                createWeld(matchingAttachment, attachment)
            end
        else
            local head = character:FindFirstChild("Head")
            if head then
                local defaultCFrame = CFrame.new(0, 0, 0)
                local attachmentPoint = hat.AttachmentPoint
                createNamedWeld("HeadWeld", head, head, handle, defaultCFrame, attachmentPoint)
            end
        end
    end
end

local userId = 1 -- Replace with the actual user ID
local assetIds = getCurrentlyWearing(userId)
local assetTypes = {}

if assetIds then
    print("Asset Types:")
    for _, assetId in ipairs(assetIds) do
        local assetType = getAssetType(assetId)
        if assetType then
            assetTypes[assetId] = assetType
            print("Asset ID:", assetId, "Type:", assetType)
            
            if assetType == 8 then -- Hat asset type
                local hatId = assetId
                local hat = game:GetObjects("rbxassetid://" .. tostring(hatId))[1]
                attachHatToCharacter(game.Players.LocalPlayer.Character, hat)
            end
        end
    end
else
    print("Failed to retrieve asset IDs.")
end
