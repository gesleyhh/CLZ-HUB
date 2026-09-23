-- ⚡ CLZ ULTRA FARM | 32/QUADRO + SEM KICK + SEM REINICIAR
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

if not game:IsLoaded() then game.Loaded:Wait() end
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local rEvents, muscleEvent, rebirthRemote, equipPetEvent, changeSizeRemote = nil, nil, nil, nil, nil

local function BuscarEventos()
    rEvents = ReplicatedStorage:FindFirstChild("rEvents")
    if not rEvents then return end
    muscleEvent = player:FindFirstChild("muscleEvent")
    rebirthRemote = rEvents:FindFirstChild("rebirthRemote")
    equipPetEvent = rEvents:FindFirstChild("equipPetEvent")
    changeSizeRemote = rEvents:FindFirstChild("changeSpeedSizeRemote")
end
BuscarEventos()

local isFarming = false
local AutoRebirth = false
local GraficosOtimizados = false

-- ✅ 32 POR QUADRO + PROTEÇÃO = RÁPIDO E ESTÁVEL
local REPS_POR_QUADRO = 32
local LIMITE_SEGURANCA = 1900 -- não passa disso por segundo
local Minimizado = false
local Encerrado = false

-- Contador pra não acumular tráfego
local contadorAcoes = 0
local ultimoReset = tick()

----------------------------------------------------------------
-- ⚡ OTIMIZAÇÃO TOTAL — TIRA TODO LAG
----------------------------------------------------------------
local graficosOriginais = {
    GlobalShadows = Lighting.GlobalShadows,
    Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    Technology = Lighting.Technology
}
local efeitosSalvos = {}
local partesComTextura = {}

local function DesligarTudoPesado()
    if GraficosOtimizados then return end
    GraficosOtimizados = true

    efeitosSalvos = {}
    for _, e in ipairs(Lighting:GetChildren()) do
        if e:IsA("BloomEffect") or e:IsA("BlurEffect") or e:IsA("SunRaysEffect") 
        or e:IsA("DepthOfFieldEffect") or e:IsA("ColorCorrectionEffect") then
            efeitosSalvos[e] = {Enabled = e.Enabled}
            e.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    Lighting.Ambient = Color3.fromRGB(255, 255, 255)
    Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
    Lighting.Brightness = 2
    Lighting.Technology = Enum.Technology.Compatibility

    partesComTextura = {}
    pcall(function()
        for _, d in ipairs(workspace:GetDescendants()) do
            if d:IsA("BasePart") then
                partesComTextura[d] = {Texture = d.Texture, CastShadow = d.CastShadow}
                d.CastShadow = false
                d.Texture = ""
            elseif d:IsA("Decal") or d:IsA("Texture") then
                partesComTextura[d] = {Transparency = d.Transparency}
                d.Transparency = 1
            end
        end
    end)

    task.spawn(function()
        while GraficosOtimizados and not Encerrado do
            pcall(function()
                for _, d in ipairs(workspace:GetDescendants()) do
                    if d:IsA("BasePart") then d.CastShadow = false end
                    if d:IsA("Decal") or d:IsA("Texture") then d.Transparency = 1 end
                end
            end)
            task.wait(0.3)
        end
    end)
end

local function RestaurarTudo()
    if not GraficosOtimizados then return end
    GraficosOtimizados = false
    Lighting.GlobalShadows = graficosOriginais.GlobalShadows
    Lighting.Brightness = graficosOriginais.Brightness
    Lighting.Ambient = graficosOriginais.Ambient
    Lighting.OutdoorAmbient = graficosOriginais.OutdoorAmbient
    Lighting.Technology = graficosOriginais.Technology
    for e, estado in pairs(efeitosSalvos) do if e then e.Enabled = estado.Enabled end end
    for d, estado in pairs(partesComTextura) do
        if not d then continue end
        pcall(function()
            if d:IsA("BasePart") then d.CastShadow = estado.CastShadow; if estado.Texture then d.Texture = estado.Texture end
            elseif d:IsA("Decal") or d:IsA("Texture") then d.Transparency = estado.Transparency end
        end)
    end
end

----------------------------------------------------------------
-- MANTER TAMANHO 1
----------------------------------------------------------------
task.spawn(function()
    repeat BuscarEventos() task.wait(0.5) until changeSizeRemote or Encerrado
    RunService.Heartbeat:Connect(function()
        if Encerrado or not changeSizeRemote then return end
        pcall(function() changeSizeRemote:InvokeServer("changeSize", 1) end)
    end)
end)

----------------------------------------------------------------
-- PETS
----------------------------------------------------------------
local petCache = {}
local function rebuildPetCache()
    table.clear(petCache)
    local petsFolder = player:FindFirstChild("petsFolder")
    if not petsFolder then return end
    pcall(function()
        for _, f in ipairs(petsFolder:GetChildren()) do
            if f:IsA("Folder") then
                for _, p in ipairs(f:GetChildren()) do
                    if not petCache[p.Name] then petCache[p.Name] = {} end
                    table.insert(petCache[p.Name], p)
                end
            end
        end
    end)
end
rebuildPetCache()
local petsFolder = player:FindFirstChild("petsFolder")
if petsFolder then
    pcall(function()
        petsFolder.DescendantAdded:Connect(rebuildPetCache)
        petsFolder.DescendantRemoving:Connect(rebuildPetCache)
    end)
end
local function equipRareBossPets()
    BuscarEventos()
    if not equipPetEvent then return end
    rebuildPetCache()
    local pets = petCache["Rare Boss Pet"] or {}
    for i = 1, math.min(8, #pets) do
        pcall(function() equipPetEvent:FireServer("equipPet", pets[i]) end)
    end
end

----------------------------------------------------------------
-- ⚡ FARM — 32/QUADRO + PROTEÇÃO DE TRÁFEGO
----------------------------------------------------------------
local farmConnection = nil
local function PararFarm()
    isFarming = false
    if farmConnection then farmConnection:Disconnect() farmConnection = nil end
    contadorAcoes = 0
    ultimoReset = tick()
end
local function IniciarFarm()
    if farmConnection then return end
    BuscarEventos()
    if not muscleEvent then return end
    isFarming = true
    contadorAcoes = 0
    ultimoReset = tick()
    
    farmConnection = RunService.Heartbeat:Connect(function()
        if not isFarming or Encerrado or not muscleEvent then return end
        
        -- ✅ RESETA CONTADOR A CADA SEGUNDO
        if tick() - ultimoReset >= 1 then
            contadorAcoes = 0
            ultimoReset = tick()
        end
        
        -- ✅ PARA SE PASSAR DO LIMITE SEGURO
        if contadorAcoes >= LIMITE_SEGURANCA then return end
        
        -- ✅ CALCULA QUANTIDADE SEM EXCEDER
        local quantoFazer = math.min(REPS_POR_QUADRO, LIMITE_SEGURANCA - contadorAcoes)
        
        for _ = 1, quantoFazer do
            pcall(function() muscleEvent:FireServer("rep") end)
            contadorAcoes = contadorAcoes + 1
        end
    end)
end

----------------------------------------------------------------
-- ⚡ RENASCIMENTO — SEM COOLDOWN + ESTÁVEL
----------------------------------------------------------------
local RebirthConnection = nil
local function PararRenascimento()
    AutoRebirth = false
    if RebirthConnection then RebirthConnection:Disconnect() RebirthConnection = nil end
end

local function TentarRenascer()
    pcall(function()
        for _, gui in ipairs(playerGui:GetChildren()) do
            if gui:FindFirstChild("RENASCER") or gui.Name:find("Rebirth") or gui.Name:find("Renascer") then
                for _, btn in ipairs(gui:GetDescendants()) do
                    if btn:IsA("TextButton") and (btn.Text == "CONFIRME" or btn.Text:find("Confirm") or btn.Text:find("Renascer") or btn.Text:find("Rebirth")) then
                        task.spawn(function() pcall(function() btn:Activate() end) end)
                    end
                end
            end
        end
    end)
    BuscarEventos()
    if rebirthRemote then
        task.spawn(function()
            pcall(function()
                rebirthRemote:InvokeServer("rebirthRequest")
                task.wait(0.15) -- espaçamento estável
                rebirthRemote:FireServer("rebirthRequest")
            end)
        end)
    end
end

local function IniciarRenascimento()
    if RebirthConnection then return end
    AutoRebirth = true
    RebirthConnection = RunService.Heartbeat:Connect(function()
        if not AutoRebirth or Encerrado then return end
        local leaderstats = player:FindFirstChild("leaderstats")
        local strength = leaderstats and leaderstats:FindFirstChild("Strength")
        if strength and strength.Value > 0 then
            TentarRenascer()
        end
    end)
end

----------------------------------------------------------------
-- FORMATO NÚMEROS
----------------------------------------------------------------
local function formatNumber(n)
    if n >= 1e18 then return string.format("%.2fQi", n/1e18)
    elseif n >= 1e15 then return string.format("%.2fQ", n/1e15)
    elseif n >= 1e12 then return string.format("%.2fT", n/1e12)
    elseif n >= 1e9 then return string.format("%.2fB", n/1e9)
    elseif n >= 1e6 then return string.format("%.2fM", n/1e6)
    elseif n >= 1e3 then return string.format("%.2fK", n/1e3) end
    return string.format("%.0f", n)
end

----------------------------------------------------------------
-- 📱 INTERFACE — TUDO IGUAL
----------------------------------------------------------------
local AZUL_ESCURO = Color3.fromRGB(15, 23, 42)
local AZUL_BASE = Color3.fromRGB(59, 130, 246)
local AZUL_BRILHANTE = Color3.fromRGB(96, 165, 250)
local SUCESSO_VERDE = Color3.fromRGB(16, 185, 129)
local ERRO_VERMELHO = Color3.fromRGB(239, 68, 68)
local FECHAR_VERMELHO = Color3.fromRGB(220, 38, 38)
local REBIRTH_ROXO = Color3.fromRGB(168, 85, 247)
local BRANCO = Color3.fromRGB(255, 255, 255)
local CINZA = Color3.fromRGB(200, 200, 200)
local OTIMIZAR_VERDE = Color3.fromRGB(52, 211, 153)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "CLZ_ULTRA_FARM"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local miniButton = Instance.new("TextButton")
miniButton.Name = "MiniButton"
miniButton.Size = UDim2.new(0, 52, 0, 52)
miniButton.Position = UDim2.new(0, 185, 0, 55)
miniButton.BackgroundColor3 = Color3.fromRGB(15, 82, 186)
miniButton.Text = "CLZ"
miniButton.TextColor3 = BRANCO
miniButton.TextSize = 24
miniButton.Font = Enum.Font.GothamBlack
miniButton.Visible = false
miniButton.Parent = screenGui
Instance.new("UICorner", miniButton).CornerRadius = UDim.new(0, 12)
local miniStroke = Instance.new("UIStroke")
miniStroke.Color = AZUL_BRILHANTE
miniStroke.Thickness = 3
miniStroke.Parent = miniButton

local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 310, 0, 350)
frame.AnchorPoint = Vector2.new(0.5, 0.5)
frame.Position = UDim2.new(0.5, 0, 0.5, 0)
frame.BackgroundColor3 = AZUL_ESCURO
frame.Parent = screenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)
local stroke = Instance.new("UIStroke")
stroke.Color = AZUL_BRILHANTE
stroke.Thickness = 2
stroke.Parent = frame

local topBar = Instance.new("Frame")
topBar.Size = UDim2.new(1, 0, 0, 40)
topBar.BackgroundColor3 = Color3.fromRGB(30, 41, 59)
topBar.Parent = frame
Instance.new("UICorner", topBar).CornerRadius = UDim.new(0, 16)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -85, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "⚡ CLZ ULTRA FARM"
title.TextColor3 = AZUL_BRILHANTE
title.TextSize = 16
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = topBar

local BtnMin = Instance.new("TextButton")
BtnMin.Size = UDim2.new(0, 34, 0, 32)
BtnMin.Position = UDim2.new(1, -76, 0, 4)
BtnMin.Text = "−"
BtnMin.Font = Enum.Font.GothamBold
BtnMin.TextSize = 20
BtnMin.TextColor3 = BRANCO
BtnMin.BackgroundColor3 = Color3.fromRGB(51, 65, 85)
BtnMin.Parent = topBar
Instance.new("UICorner", BtnMin).CornerRadius = UDim.new(0, 8)

local BtnFechar = Instance.new("TextButton")
BtnFechar.Size = UDim2.new(0, 34, 0, 32)
BtnFechar.Position = UDim2.new(1, -38, 0, 4)
BtnFechar.Text = "✕"
BtnFechar.Font = Enum.Font.GothamBold
BtnFechar.TextSize = 18
BtnFechar.TextColor3 = BRANCO
BtnFechar.BackgroundColor3 = FECHAR_VERMELHO
BtnFechar.Parent = topBar
Instance.new("UICorner", BtnFechar).CornerRadius = UDim.new(0, 8)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -24, 0, 22)
status.Position = UDim2.new(0, 12, 0, 52)
status.BackgroundTransparency = 1
status.Text = "🔴 FARM PAUSADO"
status.TextColor3 = ERRO_VERMELHO
status.TextSize = 13
status.Font = Enum.Font.GothamBold
status.TextXAlignment = Enum.TextXAlignment.Left
status.Parent = frame

local rebirthStatus = Instance.new("TextLabel")
rebirthStatus.Size = UDim2.new(1, -24, 0, 22)
rebirthStatus.Position = UDim2.new(0, 12, 0, 76)
rebirthStatus.BackgroundTransparency = 1
rebirthStatus.Text = "🔴 RENASCIMENTO DESLIGADO"
rebirthStatus.TextColor3 = ERRO_VERMELHO
rebirthStatus.TextSize = 13
rebirthStatus.Font = Enum.Font.GothamBold
rebirthStatus.TextXAlignment = Enum.TextXAlignment.Left
rebirthStatus.Parent = frame

local strengthLabel = Instance.new("TextLabel")
strengthLabel.Size = UDim2.new(1, -24, 0, 36)
strengthLabel.Position = UDim2.new(0, 12, 0, 100)
strengthLabel.BackgroundTransparency = 1
strengthLabel.Text = "FORÇA: 0"
strengthLabel.TextColor3 = BRANCO
strengthLabel.TextSize = 22
strengthLabel.Font = Enum.Font.GothamBlack
strengthLabel.TextXAlignment = Enum.TextXAlignment.Left
strengthLabel.Parent = frame

local sessionLabel = Instance.new("TextLabel")
sessionLabel.Size = UDim2.new(1, -24, 0, 18)
sessionLabel.Position = UDim2.new(0, 12, 0, 140)
sessionLabel.BackgroundTransparency = 1
sessionLabel.Text = "⏱️ 00:00:00"
sessionLabel.TextColor3 = CINZA
sessionLabel.TextSize = 12
sessionLabel.Font = Enum.Font.GothamBold
sessionLabel.TextXAlignment = Enum.TextXAlignment.Left
sessionLabel.Parent = frame

local BotaoGrafico = Instance.new("TextButton")
BotaoGrafico.Size = UDim2.new(1, -24, 0, 38)
BotaoGrafico.Position = UDim2.new(0, 12, 0, 168)
BotaoGrafico.Text = "📉 TIRAR TODO LAG"
BotaoGrafico.Font = Enum.Font.GothamBold
BotaoGrafico.TextSize = 14
BotaoGrafico.TextColor3 = BRANCO
BotaoGrafico.BackgroundColor3 = Color3.fromRGB(107, 114, 128)
BotaoGrafico.Parent = frame
Instance.new("UICorner", BotaoGrafico).CornerRadius = UDim.new(0, 10)

local BotaoToggle = Instance.new("TextButton")
BotaoToggle.Size = UDim2.new(1, -24, 0, 42)
BotaoToggle.Position = UDim2.new(0, 12, 0, 214)
BotaoToggle.Text = "▶️ LIGAR FARM"
BotaoToggle.Font = Enum.Font.GothamBold
BotaoToggle.TextSize = 16
BotaoToggle.TextColor3 = BRANCO
BotaoToggle.BackgroundColor3 = AZUL_BASE
BotaoToggle.Parent = frame
Instance.new("UICorner", BotaoToggle).CornerRadius = UDim.new(0, 12)

local BotaoRebirth = Instance.new("TextButton")
BotaoRebirth.Size = UDim2.new(1, -24, 0, 42)
BotaoRebirth.Position = UDim2.new(0, 12, 0, 266)
BotaoRebirth.Text = "🔄 LIGAR RENASCIMENTO"
BotaoRebirth.Font = Enum.Font.GothamBold
BotaoRebirth.TextSize = 16
BotaoRebirth.TextColor3 = BRANCO
BotaoRebirth.BackgroundColor3 = REBIRTH_ROXO
BotaoRebirth.Parent = frame
Instance.new("UICorner", BotaoRebirth).CornerRadius = UDim.new(0, 12)

----------------------------------------------------------------
-- FUNÇÕES
----------------------------------------------------------------
local function FecharScript()
    Encerrado = true
    PararFarm()
    PararRenascimento()
    RestaurarTudo()
    pcall(function() screenGui:Destroy() end)
end
BtnFechar.MouseButton1Click:Connect(FecharScript)

local function AtualizarMinimizado()
    if Encerrado then return end
    frame.Visible = not Minimizado
    miniButton.Visible = Minimizado
end

BtnMin.MouseButton1Click:Connect(function()
    Minimizado = true
    AtualizarMinimizado()
end)

miniButton.MouseButton1Click:Connect(function()
    Minimizado = false
    AtualizarMinimizado()
end)

local AlternarGrafico = function()
    if Encerrado then return end
    if GraficosOtimizados then
        RestaurarTudo()
        BotaoGrafico.Text = "📉 TIRAR TODO LAG"
        BotaoGrafico.BackgroundColor3 = Color3.fromRGB(107, 114, 128)
    else
        DesligarTudoPesado()
        BotaoGrafico.Text = "✅ LAG TIRADO TOTALMENTE"
        BotaoGrafico.BackgroundColor3 = OTIMIZAR_VERDE
    end
end
BotaoGrafico.MouseButton1Click:Connect(AlternarGrafico)

local AlternarFarm = function()
    if Encerrado then return end
    if isFarming then
        PararFarm()
        BotaoToggle.Text = "▶️ LIGAR FARM"
        BotaoToggle.BackgroundColor3 = AZUL_BASE
        status.Text = "🔴 FARM PARADO"
        status.TextColor3 = ERRO_VERMELHO
    else
        IniciarFarm()
        BotaoToggle.Text = "⏸️ PARAR FARM"
        BotaoToggle.BackgroundColor3 = SUCESSO_VERDE
        status.Text = "🟢 FARMANDO • 32/quadro + SEM KICK ⚡"
        status.TextColor3 = SUCESSO_VERDE
    end
end
BotaoToggle.MouseButton1Click:Connect(AlternarFarm)

local AlternarRebirth = function()
    if Encerrado then return end
    if AutoRebirth then
        PararRenascimento()
        BotaoRebirth.Text = "🔄 LIGAR RENASCIMENTO"
        BotaoRebirth.BackgroundColor3 = REBIRTH_ROXO
        rebirthStatus.Text = "🔴 DESLIGADO"
        rebirthStatus.TextColor3 = ERRO_VERMELHO
    else
        IniciarRenascimento()
        BotaoRebirth.Text = "⏹️ PARAR RENASCIMENTO"
        BotaoRebirth.BackgroundColor3 = SUCESSO_VERDE
        rebirthStatus.Text = "🟢 RENASCENDO • ESTÁVEL ⚡"
        rebirthStatus.TextColor3 = SUCESSO_VERDE
    end
end
BotaoRebirth.MouseButton1Click:Connect(AlternarRebirth)

local dragging, dragStart, frameStart = false, Vector2.new(), UDim2.new()
local function IniciarArrasto(input)
    if Encerrado or Minimizado then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        frameStart = frame.Position
    end
end
local function PararArrasto() dragging = false end
topBar.InputBegan:Connect(IniciarArrasto)
topBar.InputEnded:Connect(PararArrasto)
UserInputService.InputChanged:Connect(function(input)
    if dragging and not Encerrado and not Minimizado then
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(frameStart.X.Scale, frameStart.X.Offset + delta.X, frameStart.Y.Scale, frameStart.Y.Offset + delta.Y)
        end
    end
end)

local startTime = tick()
task.spawn(function()
    while not Encerrado do
        task.wait(0.1)
        if not Minimizado then
            local leaderstats = player:FindFirstChild("leaderstats")
            local strengthStat = leaderstats and leaderstats:FindFirstChild("Strength")
            if strengthStat then strengthLabel.Text = "FORÇA: " .. formatNumber(strengthStat.Value) end
            local t = math.floor(tick() - startTime)
            sessionLabel.Text = string.format("⏱️ %02d:%02d:%02d", math.floor(t/3600), math.floor((t%3600)/60), t%60)
        end
    end
end)

player.CharacterAdded:Connect(function()
    if Encerrado then return end
    PararFarm()
    PararRenascimento()
    task.wait(0.5)
    BuscarEventos()
    if AutoRebirth then IniciarRenascimento() end
    if isFarming then IniciarFarm() end
    equipRareBossPets()
end)

equipRareBossPets()
