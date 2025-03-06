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
    local url = "https://economyproxyapi.tr6ffic-5a7.workers.dev/?assetId=" .. assetId
    local data = requestData(url)
    return data and data.AssetTypeId or nil
end

local function getTextureId(assetId)
    local url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId
    local xmlData = requestData(url)

    if not xmlData then
        warn("Failed to fetch asset content for:", assetId)
        return nil
    end

    local textureUrl = string.match(xmlData, "<url>(.-)</url>")
    if not textureUrl then
        warn("Failed to extract texture URL for asset:", assetId)
        return nil
    end

    local textureId = string.match(textureUrl, "id=(%d+)")
    if not textureId then
        warn("Failed to extract texture ID from URL for asset:", assetId)
        return nil
    end

    return "rbxassetid://" .. textureId
end

local function updateClothingTexture(character, assetId, assetType)
    local textureId = getTextureId(assetId)
    if not textureId then return end

    if assetType == 2 then
        local tshirt = character:FindFirstChildOfClass("ShirtGraphic")
        if tshirt then
            tshirt.Graphic = textureId
        end

    elseif assetType == 11 then 
        local shirt = character:FindFirstChildOfClass("Shirt")
        if shirt then
            shirt.ShirtTemplate = textureId
        end

    elseif assetType == 12 then
        local pants = character:FindFirstChildOfClass("Pants")
        if pants then
            pants.PantsTemplate = textureId
        end
    end
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
    local character = game.Players.LocalPlayer.Character
    if not character then
        warn("Character not found.")
        return
    end

    print("Asset Types:")
    for _, assetId in ipairs(assetIds) do
        local assetType = getAssetType(assetId)
        if assetType then
            assetTypes[assetId] = assetType
            print("Asset ID:", assetId, "Type:", assetType)

            -- Attach Hats (8, 41-47)
            if assetType == 8 or (assetType >= 41 and assetType <= 47) then
                local hatId = assetId
                local hat = game:GetObjects("rbxassetid://" .. tostring(hatId))[1]
                attachHatToCharacter(character, hat)

            -- Update Existing Clothing (Shirts, T-Shirts, Pants)
            elseif assetType == 11 or assetType == 2 or assetType == 12 then
                updateClothingTexture(character, assetId, assetType)
            end
        end
    end
else
    print("Failed to retrieve asset IDs.")
end
