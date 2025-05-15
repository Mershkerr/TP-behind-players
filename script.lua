--[[
    Roblox Script with Key System & Dual-Mode Teleport
    Author: [Your Name/Pseudonym]
    Version: 2.0 (with Key System)
]]

-- Сервисы Roblox
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

-- Конфигурация системы ключей
local KEY_SYSTEM_ENABLED = true -- Установите false, чтобы временно отключить систему ключей для тестов
local AD_LINK_URL = "YOUR_WORK_INK_OR_LOOTLABS_LINK_HERE" -- ЗАМЕНИТЕ ЭТО ВАШЕЙ РЕКЛАМНОЙ ССЫЛКОЙ
local KEY_VALIDATION_URL = "YOUR_RAW_PASTEBIN_OR_GIST_LINK_CONTAINING_THE_CURRENT_KEY" -- ЗАМЕНИТЕ ЭТО ССЫЛКОЙ НА ФАЙЛ С АКТУАЛЬНЫМ КЛЮЧОМ

local isVerified = false -- Флаг, показывающий, прошел ли пользователь проверку ключа

-- Функция для загрузки основного скрипта (выбор режима телепорта и т.д.)
local function loadMainScript()
    --[[
        Dual-Mode Teleport Script: Default vs. Legit
        Эта часть загружается ПОСЛЕ успешной проверки ключа.
    ]]
    if not isVerified then
        warn("Attempted to load main script without verification!")
        return
    end
    
    print("Key Verified! Loading main script modules...")

    -- Создаём выбор режима
    local modeSelectGui = Instance.new("ScreenGui", PlayerGui)
    modeSelectGui.Name = "ModeSelectGui"
    modeSelectGui.ResetOnSpawn = false -- Не сбрасывать GUI при возрождении

    local frame = Instance.new("Frame", modeSelectGui)
    frame.Size = UDim2.new(0, 300, 0, 150)
    frame.Position = UDim2.new(0.5, -150, 0.5, -75)
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    frame.BorderSizePixel  = 0

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,0,0,40)
    title.Position = UDim2.new(0,0,0,0)
    title.BackgroundTransparency = 1
    title.Text = "Select Teleport Mode"
    title.Font = Enum.Font.SourceSansBold
    title.TextSize = 24
    title.TextColor3 = Color3.new(1,1,1)

    local function createModeButton(text, posY)
        local btn = Instance.new("TextButton", frame)
        btn.Size = UDim2.new(0, 260, 0, 40)
        btn.Position = UDim2.new(0, 20, 0, posY)
        btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        btn.TextColor3 = Color3.new(1,1,1)
        btn.Font = Enum.Font.SourceSans
        btn.TextSize = 20
        btn.Text = text
        return btn
    end

    local defaultBtn = createModeButton("Default", 50)
    local legitBtn   = createModeButton("Legit",  100)

    local function hideSelector()
        if modeSelectGui and modeSelectGui.Parent then
            modeSelectGui:Destroy()
        end
    end

    -------------------------
    -- Default implementation
    -------------------------
    local function runDefault()
        local CurrentCharacter = nil
        local CurrentHumanoid  = nil
        local Camera           = workspace.CurrentCamera
        local TELEPORT_DISTANCE  = 3
        local MAX_TELEPORT_RANGE = 50
        local TELEPORT_KEY

        local bindPromptGui = nil
        local mobileButtonGui = nil
        local inputConnectionDefault = nil -- Для отслеживания соединения ввода

        local function updateDefaultCharacterReferences(characterModel)
            CurrentCharacter = characterModel
            CurrentHumanoid = CurrentCharacter and CurrentCharacter:FindFirstChildOfClass("Humanoid") or nil
        end

        if LocalPlayer.Character then updateDefaultCharacterReferences(LocalPlayer.Character) end
        LocalPlayer.CharacterAdded:Connect(updateDefaultCharacterReferences)

        local function tryTeleportDefault()
            if not TELEPORT_KEY or not CurrentHumanoid or CurrentHumanoid.Health <= 0 then return end
            local root = CurrentCharacter and CurrentCharacter:FindFirstChild("HumanoidRootPart")
            if not root then return end

            local origin = root.Position
            local bestTarget, bestDist = nil, MAX_TELEPORT_RANGE + 1

            for _, otherPlayer in ipairs(Players:GetPlayers()) do
                if otherPlayer ~= LocalPlayer and otherPlayer.Character then
                    local oRoot = otherPlayer.Character:FindFirstChild("HumanoidRootPart")
                    local oHum  = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
                    if oRoot and oHum and oHum.Health > 0 then
                        local dist = (oRoot.Position - origin).Magnitude
                        if dist < bestDist and dist <= MAX_TELEPORT_RANGE then
                            bestDist, bestTarget = dist, otherPlayer
                        end
                    end
                end
            end

            if bestTarget then
                local tRoot = bestTarget.Character:FindFirstChild("HumanoidRootPart")
                if not tRoot then return end

                local cameraOffset = root.CFrame:ToObjectSpace(Camera.CFrame)
                local targetLookVector = tRoot.CFrame.LookVector
                if targetLookVector.Magnitude < 0.1 then targetLookVector = Vector3.new(0,0,-1) end
                
                local backPos = tRoot.Position - (targetLookVector * TELEPORT_DISTANCE)
                backPos = Vector3.new(backPos.X, tRoot.Position.Y, backPos.Z)
                local newPlayerCFrame = CFrame.new(backPos, tRoot.Position)
                
                root.CFrame = newPlayerCFrame
                
                -- Clear movement
                root.Velocity = Vector3.zero; root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
                for _, v in ipairs(root:GetChildren()) do
                    if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("VectorForce") or v:IsA("LinearVelocity") then
                        v:Destroy()
                    end
                end

                RunService.RenderStepped:Wait()
                Camera.CameraType = Enum.CameraType.Scriptable
                Camera.CFrame     = newPlayerCFrame * cameraOffset
                Camera.CameraType = Enum.CameraType.Custom
            end
        end

        local function createDefaultBindPrompt()
            if bindPromptGui and bindPromptGui.Parent then bindPromptGui:Destroy() end
            bindPromptGui = Instance.new("ScreenGui", PlayerGui)
            bindPromptGui.Name = "DefaultBindPrompt"; bindPromptGui.ResetOnSpawn = false
            local label = Instance.new("TextLabel", bindPromptGui)
            label.Size = UDim2.new(0, 400, 0, 50); label.Position = UDim2.new(0.5, -200, 0.5, -25)
            label.BackgroundTransparency = 0.5; label.BackgroundColor3 = Color3.fromRGB(0,0,0)
            label.TextColor3 = Color3.new(1,1,1); label.Font = Enum.Font.SourceSansBold
            label.TextSize = 24; label.Text = "Press any key to bind teleport (Default)"
            local conn
            conn = UserInputService.InputBegan:Connect(function(input, processed)
                if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then return end
                TELEPORT_KEY = input.KeyCode
                if bindPromptGui and bindPromptGui.Parent then bindPromptGui:Destroy() end
                conn:Disconnect()
            end)
        end
        
        local function createDefaultMobileButton()
            if not UserInputService.TouchEnabled then return end
            if mobileButtonGui and mobileButtonGui.Parent then mobileButtonGui:Destroy() end
            mobileButtonGui = Instance.new("ScreenGui", PlayerGui)
            mobileButtonGui.Name = "DefaultTeleportButtonGui"; mobileButtonGui.ResetOnSpawn = false
            local btn = Instance.new("TextButton", mobileButtonGui)
            btn.Name = "TeleportButton"; btn.Text = "Teleport (D)"
            btn.Font = Enum.Font.SourceSansBold; btn.TextSize = 20
            btn.TextColor3 = Color3.new(1,1,1); btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.BackgroundTransparency = 0.2; btn.Size = UDim2.new(0,130,0,45)
            btn.Position = UDim2.new(1,-145,1,-75); btn.ZIndex = 10
            btn.MouseButton1Click:Connect(tryTeleportDefault)
        end

        createDefaultBindPrompt()
        createDefaultMobileButton()
        
        LocalPlayer.CharacterAdded:Connect(function() -- Ensure UI is present after respawn
            task.wait(0.2) -- Give character time to load
             if TELEPORT_KEY then -- Only recreate mobile button if key was bound
                createDefaultMobileButton()
            else -- Re-prompt for keybind if not yet bound
                createDefaultBindPrompt()
             end
        end)

        if inputConnectionDefault then inputConnectionDefault:Disconnect() end -- Disconnect previous if any
        inputConnectionDefault = UserInputService.InputBegan:Connect(function(input, processed)
            if processed or not TELEPORT_KEY or input.KeyCode ~= TELEPORT_KEY then return end
            tryTeleportDefault()
        end)
    end

    -----------------------
    -- Legit implementation
    -----------------------
    local function runLegit()
        local Players_Service = game:GetService("Players")
        local UIS = game:GetService("UserInputService")
        local RS = game:GetService("RunService")
        local LocalPlayer_Legit = Players_Service.LocalPlayer
        local Character_Legit, Humanoid_Legit
        local Camera_Legit = workspace.CurrentCamera
        local TELE_KEY_LEGIT = nil
        local IS_BINDING_LEGIT = false
        local IS_TELEPORTING_LEGIT = false
        local LAST_TELE_TIME_LEGIT = 0
        local keybindGuiLegit, mobileGuiLegit
        local inputConnectionLegit = nil -- For tracking input connection
        local fakeCallsConnection = nil -- For tracking heartbeat connection

        local function updateLegitCharacterRefs(char)
            Character_Legit = char
            Humanoid_Legit = Character_Legit and Character_Legit:FindFirstChildOfClass("Humanoid") or nil
            IS_TELEPORTING_LEGIT = false -- Reset teleport state on respawn
        end

        if LocalPlayer_Legit.Character then updateLegitCharacterRefs(LocalPlayer_Legit.Character) end
        LocalPlayer_Legit.CharacterAdded:Connect(updateLegitCharacterRefs)
        
        local function AttemptTeleportLegit()
            if not Humanoid_Legit or Humanoid_Legit.Health <= 0 then return end
            local myRoot = Character_Legit and Character_Legit:FindFirstChild("HumanoidRootPart")
            if not myRoot then return end
            
            local closestTarget, minDist = nil, 50
            for _, player in ipairs(Players_Service:GetPlayers()) do
                if player ~= LocalPlayer_Legit and player.Character then
                    local char = player.Character
                    local root = char:FindFirstChild("HumanoidRootPart")
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if root and hum and hum.Health > 0 then
                        local dist = (myRoot.Position - root.Position).Magnitude
                        if dist < minDist then minDist = dist; closestTarget = char end
                    end
                end
            end

            if closestTarget then
                if IS_TELEPORTING_LEGIT or tick() - LAST_TELE_TIME_LEGIT < 1 then return end
                IS_TELEPORTING_LEGIT = true; LAST_TELE_TIME_LEGIT = tick()
                local tRoot = closestTarget:FindFirstChild("HumanoidRootPart")
                if not tRoot or not Character_Legit or not Humanoid_Legit or Humanoid_Legit.Health <= 0 then -- Re-check self
                    IS_TELEPORTING_LEGIT = false; return
                end
                myRoot = Character_Legit:FindFirstChild("HumanoidRootPart") -- Re-get myRoot in case of issues
                if not myRoot then IS_TELEPORTING_LEGIT = false; return end


                local startPos = myRoot.CFrame
                local endPos = tRoot.CFrame * CFrame.new(0, 0, 3) * CFrame.Angles(0, math.rad(180), 0)
                for i = 0, 1, 0.1 do
                    if not myRoot or not Humanoid_Legit or Humanoid_Legit.Health <= 0 then break end
                    myRoot.CFrame = startPos:Lerp(endPos, i)
                    RS.Heartbeat:Wait()
                end
                if myRoot and Humanoid_Legit and Humanoid_Legit.Health > 0 then myRoot.CFrame = endPos end
                IS_TELEPORTING_LEGIT = false
            end
        end
        
        local function CreateMobileUILegit()
            if not UIS.TouchEnabled then return end
            if mobileGuiLegit and mobileGuiLegit.Parent then mobileGuiLegit:Destroy() end
            mobileGuiLegit = Instance.new("ScreenGui", PlayerGui)
            mobileGuiLegit.Name = "LegitMobileUI_"..math.random(1,999); mobileGuiLegit.ResetOnSpawn = false
            local btn = Instance.new("TextButton", mobileGuiLegit)
            btn.Size = UDim2.new(0, 120, 0, 50); btn.Position = UDim2.new(1, -130, 1, -70)
            btn.Text = "TELEPORT (L)"; btn.Font = Enum.Font.SourceSansBold; btn.TextSize = 18
            btn.TextColor3 = Color3.new(1,1,1); btn.BackgroundColor3 = Color3.fromRGB(50,50,50)
            btn.MouseButton1Click:Connect(AttemptTeleportLegit)
        end

        local function CreateKeybindUILegit()
            if keybindGuiLegit and keybindGuiLegit.Parent then keybindGuiLegit:Destroy() end
            IS_BINDING_LEGIT = true
            keybindGuiLegit = Instance.new("ScreenGui", PlayerGui)
            keybindGuiLegit.Name = "LegitKeybindUI_"..math.random(1,999); keybindGuiLegit.ResetOnSpawn = false
            local fr = Instance.new("Frame", keybindGuiLegit)
            fr.Size = UDim2.new(0,300,0,60); fr.Position = UDim2.new(0.5,-150,0.5,-30); fr.BackgroundTransparency=0.7
            local lbl = Instance.new("TextLabel", fr)
            lbl.Size = UDim2.new(1,0,0.6,0); lbl.Text="PRESS KEY TO BIND (LEGIT)"; lbl.Font=Enum.Font.SourceSansBold; lbl.TextSize=18
            local conn
            conn = UIS.InputBegan:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.Keyboard then
                    TELE_KEY_LEGIT = inp.KeyCode; conn:Disconnect()
                    if keybindGuiLegit and keybindGuiLegit.Parent then keybindGuiLegit:Destroy() end
                    IS_BINDING_LEGIT = false; CreateMobileUILegit()
                end
            end)
        end
        
        if inputConnectionLegit then inputConnectionLegit:Disconnect() end
        inputConnectionLegit = UIS.InputBegan:Connect(function(input, processed)
            if processed or IS_BINDING_LEGIT or not TELE_KEY_LEGIT or input.KeyCode ~= TELE_KEY_LEGIT then return end
            AttemptTeleportLegit()
        end)
        
        LocalPlayer_Legit.CharacterAdded:Connect(function(char)
            updateLegitCharacterRefs(char)
            if not IS_BINDING_LEGIT and TELE_KEY_LEGIT then CreateMobileUILegit()
            elseif not TELE_KEY_LEGIT then CreateKeybindUILegit()
            end
        end)

        if not TELE_KEY_LEGIT then CreateKeybindUILegit() else CreateMobileUILegit() end
        
        if fakeCallsConnection then fakeCallsConnection:Disconnect() end
        fakeCallsConnection = RS.Heartbeat:Connect(function()
            if not modeSelectGui.Parent and not (mobileGuiLegit and mobileGuiLegit.Parent) and not (keybindGuiLegit and keybindGuiLegit.Parent) then
                if fakeCallsConnection then fakeCallsConnection:Disconnect(); fakeCallsConnection = nil; end
                return
            end
            if math.random(1, 300) == 1 then -- Approx every 5 seconds
                pcall(function() game:GetService("MarketplaceService"):GetProductInfo(math.random(1e4, 2e4)) end)
            end
        end)
    end

    -- Подключаем кнопки выбора режима
    defaultBtn.MouseButton1Click:Connect(function()
        hideSelector()
        runDefault()
    end)
    legitBtn.MouseButton1Click:Connect(function()
        hideSelector()
        runLegit()
    end)

    -- Опционально: Помечаем, что ключ был проверен для этой сессии (для некоторых эксплоитов)
    if getgenv then getgenv().KeyVerifiedForThisSession = true end
    print("Main script GUI loaded and functionalities active.")
end


-- GUI Системы Ключей
local function createKeySystemGui()
    local keyGui = Instance.new("ScreenGui", PlayerGui)
    keyGui.Name = "KeySystemVerificationGui"
    keyGui.ResetOnSpawn = false -- Не сбрасывать при возрождении, пока ключ не введен

    local mainFrame = Instance.new("Frame", keyGui)
    mainFrame.Size = UDim2.new(0, 360, 0, 230)
    mainFrame.Position = UDim2.new(0.5, -180, 0.5, -115)
    mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    mainFrame.BorderSizePixel = 1
    mainFrame.BorderColor3 = Color3.fromRGB(55, 55, 55)
    mainFrame.ClipsDescendants = true
    Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 8)


    local titleLabel = Instance.new("TextLabel", mainFrame)
    titleLabel.Size = UDim2.new(1, 0, 0, 40)
    titleLabel.Position = UDim2.new(0, 0, 0, 5)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 20
    titleLabel.Text = "Требуется Верификация"

    local infoLabel = Instance.new("TextLabel", mainFrame)
    infoLabel.Size = UDim2.new(0.9, 0, 0, 40)
    infoLabel.Position = UDim2.new(0.05, 0, 0, 45)
    infoLabel.BackgroundTransparency = 1
    infoLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    infoLabel.Font = Enum.Font.SourceSans
    infoLabel.TextSize = 14
    infoLabel.TextWrapped = true
    infoLabel.Text = "Чтобы использовать скрипт, получите ключ, нажав кнопку ниже, и введите его."

    local getKeyButton = Instance.new("TextButton", mainFrame)
    getKeyButton.Size = UDim2.new(0.8, 0, 0, 35)
    getKeyButton.Position = UDim2.new(0.1, 0, 0, 90)
    getKeyButton.BackgroundColor3 = Color3.fromRGB(70, 130, 230) -- Синий цвет
    getKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    getKeyButton.Font = Enum.Font.SourceSansSemibold
    getKeyButton.TextSize = 16
    getKeyButton.Text = "Получить Ключ"
    Instance.new("UICorner", getKeyButton).CornerRadius = UDim.new(0, 6)

    local keyInputBox = Instance.new("TextBox", mainFrame)
    keyInputBox.Size = UDim2.new(0.8, 0, 0, 35)
    keyInputBox.Position = UDim2.new(0.1, 0, 0, 130)
    keyInputBox.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    keyInputBox.TextColor3 = Color3.fromRGB(230, 230, 230)
    keyInputBox.Font = Enum.Font.SourceSans
    keyInputBox.TextSize = 14
    keyInputBox.PlaceholderText = "Введите ключ здесь..."
    keyInputBox.ClearTextOnFocus = false
    Instance.new("UICorner", keyInputBox).CornerRadius = UDim.new(0, 6)
    local padding = Instance.new("UIPadding", keyInputBox)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)


    local checkKeyButton = Instance.new("TextButton", mainFrame)
    checkKeyButton.Size = UDim2.new(0.8, 0, 0, 35)
    checkKeyButton.Position = UDim2.new(0.1, 0, 0, 170)
    checkKeyButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80) -- Зеленый цвет
    checkKeyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    checkKeyButton.Font = Enum.Font.SourceSansSemibold
    checkKeyButton.TextSize = 16
    checkKeyButton.Text = "Проверить Ключ"
    Instance.new("UICorner", checkKeyButton).CornerRadius = UDim.new(0, 6)

    local statusLabel = Instance.new("TextLabel", mainFrame)
    statusLabel.Size = UDim2.new(0.9, 0, 0, 20)
    statusLabel.Position = UDim2.new(0.05, 0, 1, -22)
    statusLabel.BackgroundTransparency = 1
    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
    statusLabel.Font = Enum.Font.SourceSansItalic
    statusLabel.TextSize = 13
    statusLabel.Text = ""

    -- Функционал кнопки "Получить Ключ"
    getKeyButton.MouseButton1Click:Connect(function()
        if AD_LINK_URL == "YOUR_WORK_INK_OR_LOOTLABS_LINK_HERE" or not AD_LINK_URL:match("^https?://") then
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            statusLabel.Text = "Ошибка: Ссылка для получения ключа не настроена разработчиком."
            return
        end
        
        if setclipboard then
            pcall(setclipboard, AD_LINK_URL)
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            statusLabel.Text = "Ссылка скопирована! Вставьте ее в браузер."
        else
            -- Если setclipboard недоступен, показываем ссылку пользователю
            infoLabel.Text = "Скопируйте вручную: " .. AD_LINK_URL
            infoLabel.Selectable = true -- Позволяет выделить текст для копирования
            statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
            statusLabel.Text = "Скопируйте ссылку из поля выше."
        end
        task.delay(3, function() if statusLabel.Text == "Ссылка скопирована! Вставьте ее в браузер." or statusLabel.Text == "Скопируйте ссылку из поля выше." then statusLabel.Text = "" end end)
    end)

    -- Функционал кнопки "Проверить Ключ"
    checkKeyButton.MouseButton1Click:Connect(function()
        if KEY_VALIDATION_URL == "YOUR_RAW_PASTEBIN_OR_GIST_LINK_CONTAINING_THE_CURRENT_KEY" or not KEY_VALIDATION_URL:match("^https?://") then
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            statusLabel.Text = "Ошибка: URL для проверки ключа не настроен."
            return
        end

        local enteredKey = keyInputBox.Text
        if not enteredKey or string.gsub(enteredKey, "%s+", "") == "" then
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            statusLabel.Text = "Пожалуйста, введите ключ."
            return
        end

        statusLabel.TextColor3 = Color3.fromRGB(200, 200, 100)
        statusLabel.Text = "Проверка ключа..."
        checkKeyButton.Text = "Проверка..."
        checkKeyButton.Enabled = false
        getKeyButton.Enabled = false

        task.spawn(function() -- Используем task.spawn для асинхронного запроса
            local success, result = pcall(function()
                return HttpService:GetAsync(KEY_VALIDATION_URL, true) -- true для игнорирования кэша
            end)

            if success and type(result) == "string" then
                local actualKey = string.gsub(result, "%s+", "") -- Удаляем пробелы из полученного ключа
                local processedEnteredKey = string.gsub(enteredKey, "%s+", "") -- И из введенного

                if actualKey == processedEnteredKey then
                    statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
                    statusLabel.Text = "Ключ принят! Загрузка скрипта..."
                    isVerified = true
                    task.delay(1, function() -- Небольшая задержка перед уничтожением GUI
                        if keyGui and keyGui.Parent then keyGui:Destroy() end
                        loadMainScript() -- Загружаем основной функционал скрипта
                    end)
                else
                    statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                    statusLabel.Text = "Неверный ключ. Попробуйте снова."
                    keyInputBox.Text = "" -- Очищаем поле ввода
                end
            else
                statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
                statusLabel.Text = "Ошибка проверки ключа. Проверьте соединение или URL."
                warn("Key validation HTTP error or invalid response: ", result)
            end
            checkKeyButton.Text = "Проверить Ключ"
            checkKeyButton.Enabled = true
            getKeyButton.Enabled = true
        end)
    end)
end


-- Логика первоначальной загрузки скрипта
if KEY_SYSTEM_ENABLED and not isVerified then
    -- Простая проверка, был ли ключ уже верифицирован в этой сессии (для некоторых эксплоитов)
    if getgenv and getgenv().KeyVerifiedForThisSession then
        isVerified = true
        print("Key already verified this session. Loading main script.")
        loadMainScript()
    else
        print("Key system enabled. Creating verification GUI.")
        createKeySystemGui()
    end
else
    isVerified = true -- Если система ключей отключена, считаем, что проверка пройдена
    print("Key system disabled or already verified. Loading main script directly.")
    loadMainScript()
end