local HttpService = game:GetService("HttpService")

local function requestData(url)
    local success, response = pcall(function()
        return request({ Url = url, Method = "GET" }).Body
    end)
    
    if success then
        return response
    else
        return nil
    end
end

local function getCurrentlyWearing(userId)
    local url = "https://avatar.roblox.com/v1/users/" .. userId .. "/currently-wearing"
    local data = requestData(url)
    task.wait(.3)

    if data then
        local decodedData = HttpService:JSONDecode(data)
        return decodedData.assetIds
    end

    return nil
end

local function getAssetType(assetId)
    local url = "your.proxy/?assetId=" .. assetId
    local data = requestData(url)
    task.wait(2)

    if data then
        local jsonData = HttpService:JSONDecode(data)
        return jsonData and jsonData.type or nil
    end

    return nil
end

local function getTextureIdFromXML(assetId)
    local url = "https://assetdelivery.roblox.com/v1/asset/?id=" .. assetId
    local response = requestData(url)
    task.wait(2)

    if response then
        return response:match('<url>(.-)</url>')
    end

    return nil
end

function applyTextureToCharacter(character, assetType, textureId)
    if assetType == 11 then
        local shirt = character:FindFirstChildOfClass("Shirt")
        if shirt then
            shirt.ShirtTemplate = textureId
        end
    elseif assetType == 12 then 
        local pants = character:FindFirstChildOfClass("Pants")
        if pants then
            pants.PantsTemplate = textureId
        end
    elseif assetType == 2 then 
        local tshirt = character:FindFirstChildOfClass("ShirtGraphic")
        if tshirt then
            tshirt.Graphic = textureId
        end
    end
end

function attachHatToCharacter(character, hat)
    hat.Parent = character
    local handle = hat:FindFirstChild("Handle")
    if handle then
        local attachment = handle:FindFirstChildOfClass("Attachment")
        if attachment then
            local matchingAttachment = character:FindFirstChild(attachment.Name, true)
            if matchingAttachment then
                local weld = Instance.new("Weld")
                weld.Part0 = matchingAttachment.Parent
                weld.Part1 = handle
                weld.C0 = matchingAttachment.CFrame
                weld.C1 = attachment.CFrame
                weld.Parent = matchingAttachment.Parent
            end
        else
            local head = character:FindFirstChild("Head")
            if head then
                local weld = Instance.new("Weld")
                weld.Part0 = head
                weld.Part1 = handle
                weld.C0 = CFrame.new(0, 0, 0)
                weld.C1 = hat.AttachmentPoint
                weld.Parent = head
            end
        end
    end
end

local userId = 1 -- user id here
local assetIds = getCurrentlyWearing(userId)

if assetIds then
    for _, assetId in ipairs(assetIds) do
        task.wait(2)

        local assetType = getAssetType(assetId)
        if assetType then
            if assetType == 11 or assetType == 12 or assetType == 2 then
                local textureId = getTextureIdFromXML(assetId)
                if textureId then
                    applyTextureToCharacter(game.Players.LocalPlayer.Character, assetType, textureId)
                end
            end
            if assetType == 8 or (assetType >= 41 and assetType <= 47) then
                local hat = game:GetObjects("rbxassetid://" .. tostring(assetId))[1]
                attachHatToCharacter(game.Players.LocalPlayer.Character, hat)
            end
        end
    end
end
