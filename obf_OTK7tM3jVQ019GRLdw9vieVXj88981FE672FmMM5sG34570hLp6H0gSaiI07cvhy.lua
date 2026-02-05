-- LocalScript: StarterPlayer > StarterPlayerScripts
-- Skeleton: 3D Beam kemikler (duvar arkası, yeşil neon)
-- Box: Highlight outline (duvar arkası)
-- Radar + 👁️: Sürükle-bırak (Right Shift toggle, başlangıçta kilitli)
-- Max mesafe: 1500 stud
-- Can barı kaldırıldı, sadece % kaldı (renkli: yeşil/sarı/kırmızı)
-- UI boyutu küçültüldü ve sabitlendi
-- Flash atılınca görünür kalır
-- Console'da hiçbir çıktı yok
-- Ölünce ESP resetlenmez
-- Free Cam: '8' tuşu ile açılır/kapanır. WASD ile gezinilir.
-- Hız: Standart 32, Left Shift ile 50 stud/s.
-- Karakter: Free Cam açıkken olduğu yerde kilitlenir (Anchor).
-- Mouse: Free Cam açıkken kilitlenir (rahat dönmek için), kapanınca açılır.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local ESP_ENABLED = false
local radarVisible = true
local dragLocked = true 

local espData = {}
local MAX_DISTANCE = 1500

-- Free Cam Değişkenleri
local FREE_CAM_ENABLED = false
local NORMAL_SPEED = 32
local SPRINT_SPEED = 50

-- Kamera rotasyonu ve pozisyonu için değişkenler
local camPos = Vector3.new()
local camPitch = 0
local camYaw = 0

local JOINTS = {
	"Head", "UpperTorso", "LowerTorso",
	"LeftUpperArm", "LeftLowerArm", "LeftHand",
	"RightUpperArm", "RightLowerArm", "RightHand",
	"LeftUpperLeg", "LeftLowerLeg", "LeftFoot",
	"RightUpperLeg", "RightLowerLeg", "RightFoot"
}

local BONE_CONNECTIONS = {
	{"Head", "UpperTorso"},
	{"UpperTorso", "LowerTorso"},
	{"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"},
	{"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"},
	{"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"},
	{"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}
}

-- Radar ScreenGui
local radarGui = Instance.new("ScreenGui")
radarGui.Name = "ESP_Radar"
radarGui.ResetOnSpawn = false
radarGui.IgnoreGuiInset = true
radarGui.Parent = PlayerGui

local radarFrame = Instance.new("Frame")
radarFrame.Size = UDim2.new(0, 150, 0, 150)
radarFrame.Position = UDim2.new(1, -160, 1, -160)
radarFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
radarFrame.BackgroundTransparency = 0.7
radarFrame.Visible = false
radarFrame.Parent = radarGui

local radarCorner = Instance.new("UICorner")
radarCorner.CornerRadius = UDim.new(0.5, 0)
radarCorner.Parent = radarFrame

local centerDot = Instance.new("Frame")
centerDot.Size = UDim2.new(0, 6, 0, 6)
centerDot.Position = UDim2.new(0.5, -3, 0.5, -3)
centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
centerDot.Parent = radarFrame

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(0.5, 0)
centerCorner.Parent = centerDot

-- 👁️ Toggle Butonu
local eyeButton = Instance.new("TextButton")
eyeButton.Size = UDim2.new(0, 40, 0, 40)
eyeButton.Position = UDim2.new(1, -200, 1, -200)
eyeButton.BackgroundTransparency = 0.4
eyeButton.BackgroundColor3 = Color3.fromRGB(20, 20, 50)
eyeButton.Text = "👁️"
eyeButton.TextColor3 = Color3.fromRGB(200, 200, 255)
eyeButton.TextScaled = true
eyeButton.Font = Enum.Font.SourceSansBold
eyeButton.TextSize = 28
eyeButton.BorderSizePixel = 0
eyeButton.Visible = false
eyeButton.Parent = radarGui

local eyeCorner = Instance.new("UICorner")
eyeCorner.CornerRadius = UDim.new(0.5, 0)
eyeCorner.Parent = eyeButton

-- Radar ok
local function createRadarArrow()
	local arrow = Instance.new("Frame")
	arrow.Size = UDim2.new(0, 8, 0, 8)
	arrow.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
	arrow.Visible = false
	arrow.Parent = radarFrame

	local arrowCorner = Instance.new("UICorner")
	arrowCorner.CornerRadius = UDim.new(0.5, 0)
	arrowCorner.Parent = arrow

	return arrow
end

local function createESP(player)
	if player == LocalPlayer then return end

	local data = {}

	local char = player.Character or player.CharacterAdded:Wait()
	data.char = char

	-- Highlight
	local highlight = Instance.new("Highlight")
	highlight.Name = "ESPHighlight"
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Parent = char
	data.highlight = highlight

	-- Billboard
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "ESPInfo"
	billboard.Adornee = nil
	billboard.Size = UDim2.new(0, 120, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 3.8, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.Parent = char

	local mainFrame = Instance.new("Frame", billboard)
	mainFrame.Size = UDim2.new(1, 0, 1, 0)
	mainFrame.BackgroundTransparency = 1

	local nameLabel = Instance.new("TextLabel", mainFrame)
	nameLabel.Size = UDim2.new(1, 0, 0.33, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextStrokeTransparency = 0.4
	nameLabel.TextSize = 12
	nameLabel.TextScaled = false
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Text = player.Name

	local healthLabel = Instance.new("TextLabel", mainFrame)
	healthLabel.Size = UDim2.new(1, 0, 0.33, 0)
	healthLabel.Position = UDim2.new(0, 0, 0.33, -6)
	healthLabel.BackgroundTransparency = 1
	healthLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	healthLabel.TextStrokeTransparency = 0.5
	healthLabel.TextSize = 14
	healthLabel.TextScaled = false
	healthLabel.Font = Enum.Font.Gotham

	local distLabel = Instance.new("TextLabel", mainFrame)
	distLabel.Size = UDim2.new(1, 0, 0.34, 0)
	distLabel.Position = UDim2.new(0, 0, 0.66, -12)
	distLabel.BackgroundTransparency = 1
	distLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	distLabel.TextStrokeTransparency = 0.5
	distLabel.TextSize = 14
	distLabel.TextScaled = false
	distLabel.Font = Enum.Font.Gotham

	data.billboard = billboard
	data.healthLabel = healthLabel
	data.distLabel = distLabel
	data.radarArrow = createRadarArrow()

	-- Skeleton attachments
	data.attachments = {}
	for _, partName in ipairs(JOINTS) do
		local part = char:FindFirstChild(partName)
		if part then
			local att = Instance.new("Attachment")
			att.Name = "ESP_Skeleton_Att"
			att.Parent = part
			data.attachments[partName] = att
		end
	end

	-- Skeleton Beams (yeşil, parlayan, duvar arkası)
	data.beams = {}
	local skeletonFolder = Instance.new("Folder")
	skeletonFolder.Name = "ESPSkeleton"
	skeletonFolder.Parent = char

	for i, conn in ipairs(BONE_CONNECTIONS) do
		local beam = Instance.new("Beam")
		beam.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0)) -- yeşil neon
		beam.Transparency = NumberSequence.new(0.2) -- parlasın
		beam.Width0 = 0.25
		beam.Width1 = 0.25
		beam.FaceCamera = true
		beam.Enabled = false
		beam.Parent = skeletonFolder
		data.beams[i] = beam
	end

	espData[player] = data
end

local function disableAllESP()
	for _, data in pairs(espData) do
		if data.highlight then data.highlight.Enabled = false end
		if data.billboard then data.billboard.Enabled = false end
		if data.radarArrow then data.radarArrow.Visible = false end
		if data.beams then
			for _, beam in pairs(data.beams) do
				beam.Enabled = false
			end
		end
		-- Karakter şeffaflığı geri yükle
		local char = data.char
		if char and char.Parent then
			for _, part in ipairs(char:GetChildren()) do
				if part:IsA("BasePart") then
					part.LocalTransparencyModifier = 0
				end
			end
		end
	end
	radarFrame.Visible = false
	eyeButton.Visible = false
end

-- Free Cam Mantığı (Düzeltilmiş)
local function toggleFreeCam()
	FREE_CAM_ENABLED = not FREE_CAM_ENABLED

	if FREE_CAM_ENABLED then
		-- Başlangıç pozisyonunu ve açısını ayarla
		Camera.CameraType = Enum.CameraType.Scriptable
		camPos = Camera.CFrame.Position
		local rx, ry, rz = Camera.CFrame:ToEulerAnglesYXZ()
		camPitch = rx
		camYaw = ry

		-- Mouse'u kilitle (Sonsuz dönüş için şart)
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

		-- Karakteri sabitle
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.Anchored = true
		end
	else
		-- Normale dön
		Camera.CameraType = Enum.CameraType.Custom
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default

		-- Karakteri serbest bırak
		if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.Character.HumanoidRootPart.Anchored = false
		end
	end
end

local function updateFreeCam(dt)
	if not FREE_CAM_ENABLED then return end

	-- Mouse kontrolünün sürekli kilitli olduğundan emin ol (Menü açıp kapatınca bozulmasın diye)
	if UserInputService.MouseBehavior ~= Enum.MouseBehavior.LockCenter then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

	local speed = NORMAL_SPEED
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
		speed = SPRINT_SPEED
	end

	-- Rotasyonu hesapla (InputChanged'den gelen pitch ve yaw ile)
	local rotation = CFrame.fromEulerAnglesYXZ(camPitch, camYaw, 0)

	local moveDir = Vector3.new()

	-- Yönler (Kameranın baktığı yere göre)
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		moveDir = moveDir + rotation.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		moveDir = moveDir - rotation.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		moveDir = moveDir + rotation.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		moveDir = moveDir - rotation.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.E) then -- Yukarı
		moveDir = moveDir + Vector3.new(0, 1, 0)
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Q) then -- Aşağı
		moveDir = moveDir - Vector3.new(0, 1, 0)
	end

	-- Hareket varsa uygula
	if moveDir.Magnitude > 0 then
		camPos = camPos + (moveDir.Unit * speed * dt)
	end

	-- Kamerayı güncelle
	Camera.CFrame = CFrame.new(camPos) * rotation
end

-- Mouse Dönüşü (Free Cam için)
UserInputService.InputChanged:Connect(function(input)
	if FREE_CAM_ENABLED and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Delta
		local sensitivity = 0.005 -- Dönüş hızı

		camYaw = camYaw - (delta.X * sensitivity)
		camPitch = camPitch - (delta.Y * sensitivity)

		-- Yukarı/Aşağı bakmayı sınırla (Takla atmayı önler)
		camPitch = math.clamp(camPitch, -math.rad(89), math.rad(89))
	end
end)


local function updateESP(dt)
	-- Önce Free Cam'i güncelle
	updateFreeCam(dt)

	local localRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not localRoot then return end

	eyeButton.Visible = ESP_ENABLED
	radarFrame.Visible = ESP_ENABLED and radarVisible

	if not ESP_ENABLED then
		disableAllESP()
		return
	end

	local radarCenter = Vector2.new(radarFrame.AbsolutePosition.X + radarFrame.AbsoluteSize.X / 2, radarFrame.AbsolutePosition.Y + radarFrame.AbsoluteSize.Y / 2)
	local radarRadius = radarFrame.AbsoluteSize.X / 2 - 10

	for player, data in pairs(espData) do
		local char = data.char
		if not char or not char.Parent then continue end

		local hum = char:FindFirstChildOfClass("Humanoid")
		local root = char:FindFirstChild("HumanoidRootPart")
		if not hum or not root or hum.Health <= 0 then
			disableAllESP()
			continue
		end

		local dist = (localRoot.Position - root.Position).Magnitude

		if dist > MAX_DISTANCE then
			disableAllESP()
			continue
		end

		-- Highlight & Billboard
		data.highlight.Adornee = char
		data.highlight.Enabled = true
		data.billboard.Adornee = root
		data.billboard.Enabled = true

		local hpPct = hum.Health / hum.MaxHealth
		data.healthLabel.Text = "Can: " .. math.floor(hpPct * 100) .. "%"
		data.distLabel.Text = "Uzaklık: " .. math.floor(dist)

		-- Can rengi (yeşil-sarı-kırmızı)
		if hpPct > 0.5 then
			data.healthLabel.TextColor3 = Color3.fromRGB(0, 255, 0)
		elseif hpPct > 0.3 then
			data.healthLabel.TextColor3 = Color3.fromRGB(255, 255, 0)
		else
			data.healthLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
		end

		-- Radar Arrow
		local relativePos = root.Position - localRoot.Position
		local direction = Vector2.new(relativePos.X, relativePos.Z).Unit
		local radarPos = direction * (radarRadius * math.clamp(dist / MAX_DISTANCE, 0, 1))
		data.radarArrow.Position = UDim2.new(0.5, radarPos.X, 0.5, radarPos.Y)
		data.radarArrow.Rotation = math.deg(math.atan2(direction.Y, direction.X)) - 90
		data.radarArrow.Visible = radarVisible

		-- Karakter şeffaf (iskelet dışarı parlasın)
		for _, part in ipairs(char:GetChildren()) do
			if part:IsA("BasePart") then
				part.LocalTransparencyModifier = 0.8 -- şeffaf
			end
		end

		-- Skeleton Beams (yeşil, parlayan, duvar arkası)
		local atts = data.attachments
		for i, conn in ipairs(BONE_CONNECTIONS) do
			local beam = data.beams[i]
			local att1 = atts[conn[1]]
			local att2 = atts[conn[2]]
			if att1 and att1.Parent and att2 and att2.Parent then
				beam.Attachment0 = att1
				beam.Attachment1 = att2
				beam.Enabled = true
			else
				beam.Enabled = false
			end
		end
	end
end

-- 👁️ butonuna tıklama
eyeButton.MouseButton1Click:Connect(function()
	radarVisible = not radarVisible
	radarFrame.Visible = ESP_ENABLED and radarVisible
end)

-- Radar ve Göz draggable (Right Shift toggle)
local dragging = false
local dragInput, dragStart, startPos

local function updateDrag(input)
	local delta = input.Position - dragStart
	radarFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	eyeButton.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X - 40, startPos.Y.Scale, startPos.Y.Offset + delta.Y - 40)
end

radarFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 and not dragLocked then
		dragging = true
		dragStart = input.Position
		startPos = radarFrame.Position
		input.Changed:Connect(function()
			if input.UserInputState == Enum.UserInputState.End then
				dragging = false
			end
		end)
	end
end)

radarFrame.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement and dragging then
		updateDrag(input)
	end
end)

-- Right Shift: Sürükleme toggle, 8: Free Cam, 9: ESP
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.RightShift then
		dragLocked = not dragLocked
	elseif input.KeyCode == Enum.KeyCode.Nine then
		ESP_ENABLED = not ESP_ENABLED
		if not ESP_ENABLED then
			disableAllESP()
		end
	elseif input.KeyCode == Enum.KeyCode.Eight then
		toggleFreeCam()
	end
end)

-- Player yönetimi
local function onPlayerAdded(player)
	player.CharacterAdded:Connect(function(char)
		task.wait(0.5)
		if espData[player] then
			for _, obj in pairs(espData[player]) do
				if obj and obj.Destroy then obj:Destroy() end
			end
		end
		createESP(player)
	end)
	if player.Character then
		createESP(player)
	end
end

Players.PlayerRemoving:Connect(function(player)
	if espData[player] then
		for _, obj in pairs(espData[player]) do
			if obj and obj.Destroy then obj:Destroy() end
		end
		espData[player] = nil
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)

RunService.RenderStepped:Connect(updateESP)
