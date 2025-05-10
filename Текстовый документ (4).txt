--[[ 
    Teleport Behind Nearest Player — Key 'E' (ПК) + Touch (мобильные)
    Работает через executor (например, Xeno).
    ПК: клавиша 'E'
    Телефон: одиночный тап по экрану
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local Camera = workspace.CurrentCamera

-- Настройки
local TELEPORT_DISTANCE = 3
local MAX_TELEPORT_RANGE = 50
local TELEPORT_KEY = Enum.KeyCode.E

-- Обновляем ссылки при респавне
Player.CharacterAdded:Connect(function(char)
    Character = char
    Humanoid = char:WaitForChild("Humanoid")
end)

-- Поиск ближайшего живого игрока
local function findNearestPlayer()
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return nil end

    local origin = root.Position
    local best, bestDist = nil, MAX_TELEPORT_RANGE + 1

    for _, other in ipairs(Players:GetPlayers()) do
        if other ~= Player and other.Character then
            local oRoot = other.Character:FindFirstChild("HumanoidRootPart")
            local oHum = other.Character:FindFirstChild("Humanoid")
            if oRoot and oHum and oHum.Health > 0 then
                local dist = (oRoot.Position - origin).Magnitude
                if dist < bestDist then
                    bestDist, best = dist, other
                end
            end
        end
    end

    return best, bestDist
end

-- Полный сброс импульсов
local function clearMovement()
    local root = Character:FindFirstChild("HumanoidRootPart")
    if not root then return end

    root.Velocity = Vector3.zero
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero

    for _, v in ipairs(root:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyForce")
        or v:IsA("VectorForce") or v:IsA("LinearVelocity") then
            v:Destroy()
        end
    end
    for _, part in ipairs(Character:GetDescendants()) do
        if part:IsA("BodyVelocity") or part:IsA("LinearVelocity") then
            part:Destroy()
        end
    end
end

-- Телепорт за спину цели
local function teleportBehind(target)
    local root = Character:FindFirstChild("HumanoidRootPart")
    local tRoot = target.Character and target.Character:FindFirstChild("HumanoidRootPart")
    if not root or not tRoot then return end

    local offset = root.CFrame:Inverse() * Camera.CFrame

    local backPos = tRoot.Position - tRoot.CFrame.LookVector * TELEPORT_DISTANCE
    backPos = Vector3.new(backPos.X, tRoot.Position.Y, backPos.Z)
    local cf = CFrame.new(backPos, tRoot.Position)

    root.CFrame = cf
    clearMovement()

    Camera.CameraType = Enum.CameraType.Scriptable
    Camera.CFrame = cf * offset
    Camera.CameraType = Enum.CameraType.Custom
end

-- Общая функция попытки телепорта
local function tryTeleport()
    if Humanoid.Health <= 0 then return end
    local target, dist = findNearestPlayer()
    if target and dist and dist <= MAX_TELEPORT_RANGE then
        teleportBehind(target)
    end
end

-- ПК: клавиша 'E'
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == TELEPORT_KEY then
        tryTeleport()
    end
end)

-- 📱 Мобильные устройства: одиночный тап
UserInputService.TouchTap:Connect(function(touchPositions, isProcessed)
    if isProcessed then return end
    tryTeleport()
end)
