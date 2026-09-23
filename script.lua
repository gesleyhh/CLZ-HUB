local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local muscleEvent = nil
local leaderstats = nil
local strengthStat = nil

local function AtualizarReferencias()
    muscleEvent = player:FindFirstChild("muscleEvent")
    leaderstats = player:FindFirstChild("leaderstats")
    strengthStat = leaderstats and leaderstats:FindFirstChild("Strength")
end
AtualizarReferencias()

----------------------------------------------------------------
-- CONFIGURAÇÃO
----------------------------------------------------------------

local isFarming = false
local REPS_PER_FRAME = 50
local Minimizado = false
local Encerrado = false

----------------------------------------------------------------
-- ESCONDER BOTÕES LATERAIS
----------------------------------------------------------------

local sideButtonsConnection = nil

local function hideSideButtons()
    local gameGui = playerGui:FindFirstChild("gameGui")
    local sideButtons = gameGui and gameGui:FindFirstChild("sideButtons", true)
    if not sideButtons or not sideButtons:IsA("GuiObject") then return end
    if sideButtonsConnection then sideButtonsConnection:Disconnect() end
    sideButtons.Visible = false
    sideButtonsConnection = sideButtons:GetPropertyChangedSignal("Visible"):Connect(function()
        if sideButtons.Visible then sideButtons.Visible = false end
    end)
end

playerGui.DescendantAdded:Connect(function(obj)
    if obj.Name == "sideButtons" then hideSideButtons() end
end)
hideSideButtons()

----------------------------------------------------------------
-- MANTER TAMANHO
----------------------------------------------------------------

task.spawn(function()
    local rEvents = ReplicatedStorage:WaitForChild("rEvents")
    local remote = rEvents:WaitForChild("changeSpeedSizeRemote")
    RunService.RenderStepped:Connect(function()
        if Encerrado then return end
        remote:InvokeServer("changeSize", 1)
    end)
end)

----------------------------------------------------------------
-- CACHE DE PETS
----------------------------------------------------------------

local petCache = {}

local function rebuildPetCache()
    table.clear(petCache)
    if Encerrado then return end
    local petsFolder = player:FindFirstChild("petsFolder")
    if not petsFolder then return end
    for _, folder in ipairs(petsFolder:GetChildren()) do
        if folder:IsA("Folder") then
            for _, pet in ipairs(folder:GetChildren()) do
                if not petCache[pet.Name] then petCache[pet.Name] = {} end
                table.insert(petCache[pet.Name], pet)
            end
        end
    end
end

rebuildPetCache()
local petsFolder = player:FindFirstChild("petsFolder")
if petsFolder then
    petsFolder.DescendantAdded:Connect(rebuildPetCache)
    petsFolder.DescendantRemoving:Connect(rebuildPetCache)
end

----------------------------------------------------------------
-- EQUIPAR PETS
----------------------------------------------------------------

local function equipRareBossPets()
    if Encerrado then return end
    local rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    if not rEvents then return end
    local equipRemote = rEvents:FindFirstChild("equipPetEvent")
    if not equipRemote then return end
    rebuildPetCache()
    local petName = "Rare Boss Pet"
    local pets = petCache[petName] or {}
    local amount = math.min(8, #pets)
    for i = 1, amount do
        equipRemote:FireServer("equipPet", pets[i])
    end
end

----------------------------------------------------------------
-- FARM — CORRIGIDO DEFINITIVAMENTE ✅
----------------------------------------------------------------

local farmConnection = nil

-- PARA TUDO — DESCONECTA E LIMPA
local function PararFarm()
    isFarming = false
    if farmConnection ~= nil then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

-- INICIA — SÓ SE NÃO TIVER RODANDO
local function IniciarFarm()
    if farmConnection ~= nil then return end -- Já rodando → ignora
    AtualizarReferencias()
    if not muscleEvent then return end
    isFarming = true
    farmConnection = RunService.RenderStepped:Connect(function()
        -- CORREÇÃO: Verificação direta, sem passar por nada
        if not isFarming then return end
        if Encerrado then return end
        for i = 1, REPS_PER_FRAME do
            muscleEvent:FireServer("rep")
        end
    end)
end

----------------------------------------------------------------
-- FORMATO DE NÚMEROS
----------------------------------------------------------------

local function formatNumber(num)
    if num >= 1e15 then return string.format("%.2fQ", num / 1e15)
    elseif num >= 1e12 then return string.format("%.2fT", num / 1e12)
    elseif num >= 1e9 then return string.format("%.2fB", num / 1e9)
    elseif num >= 1e6 then return string.format("%.2fM", num / 1e6)
    elseif num >= 1e3 then return string.format("%.2fK", num / 1e3) end
    return string.format("%.0f", num)
end

----------------------------------------------------------------
-- CORES
----------------------------------------------------------------

local AZUL_ESCURO = Color3.fromRGB(15, 23, 42)
local AZUL_BASE = Color3.fromRGB(59, 130, 246)
local AZUL_BRILHANTE = Color3.fromRGB(96, 165, 250)
local AZUL_NEON = Color3.fromRGB(147, 197, 253)
local TEXTO_BRANCO = Color3.fromRGB(255, 255, 255)
local TEXTO_CLARO = Color3.fromRGB(209, 213, 219)
local SUCESSO_VERDE = Color3.fromRGB(16, 185, 129)
local ERRO_VERMELHO = Color3.fromRGB(239, 68, 68)
local FECHAR_VERMELHO = Color3.fromRGB(220, 38, 38)

----------------------------------------------------------------
-- INTERFACE
----------------------------------------------------------------

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CLZ_SPEED_FARM"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Name = "CLZ_SPEED_FARM"
frame.Size = UDim2.new(0, 430, 0, 360)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0.5, 0.5, 0)
frame.BackgroundColor3 = AZUL_ESCURO
frame.BackgroundTransparency = 0.06
frame.BorderSizePixel = 0
frame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = frame

local stroke = Instance.new("UIStroke")
stroke.Color = AZUL_BRILHANTE
stroke.Thickness = 2
stroke.Transparency = 0.4
stroke.Parent = frame

local topGlow = Instance.new("Frame")
topGlow.Size = UDim2.new(1, 0, 0, 3)
topGlow.Position = UDim2.new(0, 0, 0, 0)
topGlow.BackgroundColor3 = AZUL_BASE
topGlow.Parent = frame

local title = Instance.new("TextLabel")
title.Name = "Titulo"
title.Size = UDim2.new(1, -110, 0, 35)
title.Position = UDim2.new(0, 17, 0, 15)
title.BackgroundTransparency = 1
title.Text = "⚡ CLZ SPEED FARM"
title.TextColor3 = AZUL_NEON
title.TextSize = 24
title.Font = Enum.Font.GothamBlack
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = frame

-- Botão MINIMIZAR
local BtnMin = Instance.new("TextButton")
BtnMin.Size = UDim2.new(0, 36, 0, 36)
BtnMin.Position = UDim2.new(1, -89, 0, 12)
BtnMin.Text = "−"
BtnMin.Font = Enum.Font.GothamBold
BtnMin.TextSize = 20
BtnMin.TextColor3 = TEXTO_CLARO
BtnMin.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
BtnMin.AutoLocalize = false
BtnMin.Parent = frame
Instance.new("UICorner", BtnMin).CornerRadius = UDim.new(0, 10)

-- Botão FECHAR
local BtnFechar = Instance.new("TextButton")
BtnFechar.Size = UDim2.new(0, 36, 0, 36)
BtnFechar.Position = UDim2.new(1, -47, 0, 12)
BtnFechar.Text = "✕"
BtnFechar.Font = Enum.Font.GothamBold
BtnFechar.TextSize = 18
BtnFechar.TextColor3 = Color3.new(1, 1, 1)
BtnFechar.BackgroundColor3 = FECHAR_VERMELHO
BtnFechar.AutoLocalize = false
BtnFechar.Parent = frame
Instance.new("UICorner", BtnFechar).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Name = "StatusLabel"
status.Size = UDim2.new(1, -34, 0, 25)
status.Position = UDim2.new(0, 17, 0, 58)
status.BackgroundTransparency = 1
status.Text = "🔴 FARM PAUSADO"
status.TextColor3 = ERRO_VERMELHO
status.TextSize = 15
status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local strengthLabel = Instance.new("TextLabel")
strengthLabel.Size = UDim2.new(1, -34, 0, 50)
strengthLabel.Position = UDim2.new(0, 17, 0, 95)
strengthLabel.BackgroundTransparency = 1
strengthLabel.Text = "FORÇA: 0"
strengthLabel.TextColor3 = TEXTO_BRANCO
strengthLabel.TextSize = 28
strengthLabel.Font = Enum.Font.GothamBlack
strengthLabel.TextXAlignment = Enum.TextXAlignment.Left
strengthLabel.Parent = frame

local petsLabel = Instance.new("TextLabel")
petsLabel.Size = UDim2.new(1, -34, 0, 30)
petsLabel.Position = UDim2.new(0, 17, 0, 155)
petsLabel.BackgroundTransparency = 1
petsLabel.Text = "🐾 PETS: 8 × Rare Boss Pet"
petsLabel.TextColor3 = AZUL_BRILHANTE
petsLabel.TextSize = 16
petsLabel.Font = Enum.Font.GothamBold
petsLabel.TextXAlignment = Enum.TextXAlignment.Left
petsLabel.Parent = frame

local sessionLabel = Instance.new("TextLabel")
sessionLabel.Size = UDim2.new(1, -34, 0, 30)
sessionLabel.Position = UDim2.new(0, 17, 0, 190)
sessionLabel.BackgroundTransparency = 1
sessionLabel.Text = "⏱️ SESSÃO: 00:00:00"
sessionLabel.TextColor3 = TEXTO_CLARO
sessionLabel.TextSize = 15
sessionLabel.Font = Enum.Font.GothamBold
sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
sessionLabel.Parent = frame

-- Botão LIGAR/DESLIGAR
local BotaoToggle = Instance.new("TextButton")
BotaoToggle.Name = "BotaoToggle"
BotaoToggle.Size = UDim2.new(1, -34, 0, 52)
BotaoToggle.Position = UDim2.new(0, 17, 0, 235)
BotaoToggle.Text = "▶️ LIGAR FARM"
BotaoToggle.Font = Enum.Font.GothamBold
BotaoToggle.TextSize = 17
BotaoToggle.TextColor3 = Color3.new(1, 1, 1)
BotaoToggle.BackgroundColor3 = AZUL_BASE
BotaoToggle.AutoLocalize = false
BotaoToggle.Parent = frame
Instance.new("UICorner", BotaoToggle).CornerRadius = UDim.new(0, 14)

local watermark = Instance.new("TextLabel")
watermark.Size = UDim2.new(0, 430, 0, 25)
watermark.AnchorPoint = Vector2.new(0.5, 1)
watermark.Position = UDim2.new(0.5, 0, 1, -5)
watermark.BackgroundTransparency = 1
watermark.Text = "💧 CRIADO POR THOMAZ"
watermark.TextColor3 = AZUL_BASE
watermark.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
watermark.TextStrokeTransparency = 0.2
watermark.TextSize = 17
watermark.Font = Enum.Font.GothamBlack
watermark.Parent = screenGui

----------------------------------------------------------------
-- FECHAR SCRIPT
----------------------------------------------------------------

local function FecharScript()
    Encerrado = true
    PararFarm()
    if sideButtonsConnection then sideButtonsConnection:Disconnect() end
    if screenGui then screenGui:Destroy() end
end

BtnFechar.MouseButton1Click:Connect(FecharScript)

----------------------------------------------------------------
-- ALTERNAR — CORRIGIDO ✅
----------------------------------------------------------------

local AlternarFarm = function()
    if Encerrado then return end
    
    if isFarming then
        -- DESCER → PARA TUDO
        PararFarm()
        BotaoToggle.Text = "▶️ LIGAR FARM"
        BotaoToggle.BackgroundColor3 = AZUL_BASE
        status.Text = "🔴 FARM PAUSADO"
        status.TextColor3 = ERRO_VERMELHO
    else
        -- SUBIR → INICIA
        IniciarFarm()
        if isFarming then
            BotaoToggle.Text = "⏸️ DESLIGAR FARM"
            BotaoToggle.BackgroundColor3 = SUCESSO_VERDE
            status.Text = "🟢 FARMANDO REP • VELOCIDADE MÁXIMA"
            status.TextColor3 = SUCESSO_VERDE
        end
    end
end

BotaoToggle.MouseButton1Click:Connect(AlternarFarm)

----------------------------------------------------------------
-- MINIMIZAR / MAXIMIZAR
----------------------------------------------------------------

local function AtualizarMinimizado()
    if Encerrado then return end
    if Minimizado then
        frame.Size = UDim2.new(0, 280, 0, 70)
        status.Visible = false
        strengthLabel.Visible = false
        petsLabel.Visible = false
        sessionLabel.Visible = false
        BotaoToggle.Visible = false
        title.Text = "⚡ CLZ SPEED FARM"
        BtnMin.Text = "+"
        watermark.Visible = false
    else
        frame.Size = UDim2.new(0, 430, 0, 360)
        status.Visible = true
        strengthLabel.Visible = true
        petsLabel.Visible = true
        sessionLabel.Visible = true
        BotaoToggle.Visible = true
        BtnMin.Text = "−"
        watermark.Visible = true
    end
end

BtnMin.MouseButton1Click:Connect(function()
    Minimizado = not Minimizado
    AtualizarMinimizado()
end)

----------------------------------------------------------------
-- ARRASTAR
----------------------------------------------------------------

local dragging = false
local dragStartPos = Vector2.new()
local frameStartPos = UDim2.new()

local function IniciarArrasto(input)
    if Encerrado then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStartPos = input.Position
        frameStartPos = frame.Position
    end
end

local function PararArrasto(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end

title.InputBegan:Connect(IniciarArrasto)
title.InputEnded:Connect(PararArrasto)
BtnMin.InputBegan:Connect(IniciarArrasto)
BtnMin.InputEnded:Connect(PararArrasto)
BtnFechar.InputBegan:Connect(IniciarArrasto)
BtnFechar.InputEnded:Connect(PararArrasto)

UserInputService.InputChanged:Connect(function(input)
    if not dragging or Encerrado then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        local delta = input.Position - dragStartPos
        frame.Position = UDim2.new(
            frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X,
            frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y
        )
    end
end)

----------------------------------------------------------------
-- ATUALIZAR HUD
----------------------------------------------------------------

local startTime = tick()

task.spawn(function()
    while not Encerrado do
        if strengthStat then
            strengthLabel.Text = "FORÇA: " .. formatNumber(strengthStat.Value)
        end
        local totalSeconds = math.floor(tick() - startTime)
        local h = math.floor(totalSeconds / 3600)
        local m = math.floor((totalSeconds % 3600) / 60)
        local s = totalSeconds % 60
        sessionLabel.Text = string.format("⏱️ SESSÃO: %02d:%02d:%02d", h, m, s)
        task.wait(0.1)
    end
end)

----------------------------------------------------------------
-- INICIALIZAÇÃO
----------------------------------------------------------------

local function initialize()
    if Encerrado then return end
    AtualizarReferencias()
    PararFarm()
    equipRareBossPets()
end

player.CharacterAdded:Connect(function()
    if Encerrado then return end
    PararFarm()
    task.wait(0.15)
    initialize()
end)

initialize()
