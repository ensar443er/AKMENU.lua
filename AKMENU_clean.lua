--[[
╔══════════════════════════════════════════════════════════════╗
║ ADMIN PANEL v3.0.0 ║
║ Private developer tool — use responsibly ║
║ ║
║ USAGE: loadstring(game:HttpGet("RAW_GITHUB_URL"))() ║
║ TOGGLE: Customisable in Settings → Keybinds ║
╚══════════════════════════════════════════════════════════════╝
]]
-- ═══════════════════════════════════════════════════
-- SERVICES
-- ═══════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local TeleportService = game:GetService("TeleportService")
local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera
-- ═══════════════════════════════════════════════════
-- KEY SYSTEM
-- ═══════════════════════════════════════════════════
local VALID_KEYS = {
["B7k2xxQ9mL"] = true, ["a9T4xxZ1pX"] = true,
["M3d8xxR5vK"] = true, ["q6W1xxH7sN"] = true,
["F2y9xxC4jA"] = true, ["L8n3xxX6bP"] = true,
["z5G7xxM2uD"] = true, ["H1c4xxV9kS"] = true,
["R9p6xxJ3tE"] = true, ["x2K8xxN5wB"] = true,
}
-- ═══════════════════════════════════════════════════
-- CONFIG
-- ═══════════════════════════════════════════════════
local Config = {
Primary = Color3.fromRGB(13, 13, 13),
Secondary = Color3.fromRGB(22, 22, 22),
Accent = Color3.fromRGB(100, 180, 255),
Text = Color3.fromRGB(220, 220, 220),
Sub = Color3.fromRGB(105, 105, 105),
Width = 720,
Height = 480,
}
-- ═══════════════════════════════════════════════════
-- STATE
-- ═══════════════════════════════════════════════════
local S = {
ActiveCat = "Player",
Minimized = false,
GuiVisible = true,
-- Player
SpeedOn = false, SpeedVal = 50,
FlyOn = false, FlySpeed = 50,
JumpOn = false, JumpType = "Double",
NoclipOn = false,
-- Visuals
BoxESP = false, SkelESP = false,
Tracer = false, HPBar = false,
DistESP = false, NameESP = false,
Chams = false, Fullbright= false,
NoFog = false, XRay = false,
-- Combat
KillAura = false, KillRange = 20,
Reach = false, ReachVal = 10,
AutoClick = false, FastAtk = false,
NoRecoil = false, InfAmmo = false,
GodMode = false, AntiStun = false,
-- Bow
BowTrail = false, AutoNock = false, BowZoom = false,
}
-- ═══════════════════════════════════════════════════
-- CONNECTION REGISTRY & CLEANUP
-- ═══════════════════════════════════════════════════
local Conns = {}
local ESPDrawings = {} -- [player] = {boxLines, skelLines, tracer, name,
hp, dist}
local Highlights = {} -- [player] = Highlight
local SpeedBV = nil
local FlyBody = nil
local function Track(c) if c then table.insert(Conns, c) end; return c
end
-- Save original lighting ONCE at script load
local OrigLight = {
Brightness = Lighting.Brightness,
Ambient = Lighting.Ambient,
OutdoorAmbient = Lighting.OutdoorAmbient,
FogEnd = Lighting.FogEnd,
FogStart = Lighting.FogStart,
Effects = {},
}
for _, e in ipairs(Lighting:GetChildren()) do
if e:IsA("PostEffect") then
local data = {Enabled = e.Enabled}
if e:IsA("ColorCorrectionEffect") then
data.Brightness = e.Brightness
data.Contrast = e.Contrast
data.Saturation = e.Saturation
data.TintColor = e.TintColor
elseif e:IsA("BloomEffect") then
data.Intensity = e.Intensity
data.Size = e.Size
data.Threshold = e.Threshold
elseif e:IsA("SunRaysEffect") then
data.Intensity = e.Intensity
data.Spread = e.Spread
end
OrigLight.Effects[e] = data
end
end
local function RestoreLighting()
pcall(function()
Lighting.Brightness = OrigLight.Brightness
Lighting.Ambient = OrigLight.Ambient
Lighting.OutdoorAmbient = OrigLight.OutdoorAmbient
Lighting.FogEnd = OrigLight.FogEnd
Lighting.FogStart = OrigLight.FogStart
for effect, data in pairs(OrigLight.Effects) do
if effect and effect.Parent then
effect.Enabled = data.Enabled
if effect:IsA("ColorCorrectionEffect") then
effect.Brightness = data.Brightness
effect.Contrast = data.Contrast
effect.Saturation = data.Saturation
effect.TintColor = data.TintColor
elseif effect:IsA("BloomEffect") then
effect.Intensity = data.Intensity
effect.Size = data.Size
effect.Threshold = data.Threshold
elseif effect:IsA("SunRaysEffect") then
effect.Intensity = data.Intensity
effect.Spread = data.Spread
end
end
end
end)
end
-- Drawing API check (available in most executors)
local hasDrawing = false
pcall(function()
if typeof(Drawing) == "table" then hasDrawing = true end
end)
local function KillDrawing(obj)
if not obj then return end
pcall(function() if obj.Remove then obj:Remove() elseif obj.Destroy then
obj:Destroy() end end)
end
local function ClearAllESP()
for _, d in pairs(ESPDrawings) do
if d.boxLines then for _, l in ipairs(d.boxLines) do KillDrawing(l) end
end
if d.skelLines then for _, l in ipairs(d.skelLines) do KillDrawing(l)
end end
KillDrawing(d.tracer); KillDrawing(d.name); KillDrawing(d.hp);
KillDrawing(d.dist)
end
ESPDrawings = {}
for _, hl in pairs(Highlights) do
pcall(function() if hl and hl.Parent then hl:Destroy() end end)
end
Highlights = {}
end
local function Cleanup()
-- Kill connections
for _, c in ipairs(Conns) do pcall(function() c:Disconnect() end) end
Conns = {}
-- Clear ESP / highlights
ClearAllESP()
-- Restore lighting
RestoreLighting()
-- Kill speed BV
if SpeedBV then pcall(function() SpeedBV:Destroy() end); SpeedBV = nil
end
-- Kill fly
if FlyBody then
pcall(function() FlyBody.bv:Destroy() end)
pcall(function() FlyBody.bg:Destroy() end)
FlyBody = nil
end
-- Restore character physics
pcall(function()
local c = LP.Character
if not c then return end
local h = c:FindFirstChildOfClass("Humanoid")
if h then
h.WalkSpeed = 16
h.JumpPower = 50
h.PlatformStand = false
end
for _, p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then p.CanCollide = true end
end
end)
-- Restore X-Ray
pcall(function()
for _, p in ipairs(workspace:GetDescendants()) do
if p:IsA("BasePart") then p.LocalTransparencyModifier = 0 end
end
end)
end
-- ═══════════════════════════════════════════════════
-- SCREENGUI
-- ═══════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name = "AP_" .. HttpService:GenerateGUID(false):sub(1,6)
SG.ResetOnSpawn = false
SG.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset = true
SG.DisplayOrder = 999
if not pcall(function() SG.Parent = CoreGui end) then
SG.Parent = LP:WaitForChild("PlayerGui")
end
-- ═══════════════════════════════════════════════════
-- UI HELPERS
-- ═══════════════════════════════════════════════════
local function N(cls, props, par)
local i = Instance.new(cls)
for k,v in pairs(props) do i[k]=v end
if par then i.Parent=par end
return i
end
local function Cor(p,r) local c=Instance.new("UICorner");
c.CornerRadius=UDim.new(0,r or 8); c.Parent=p; return c end
local function Stk(p,col,t) local s=Instance.new("UIStroke");
s.Color=col or Color3.fromRGB(38,38,38); s.Thickness=t or 1; s.Parent=p;
return s end
local function Hov(btn,on,off)
off=off or btn.BackgroundColor3
btn.MouseEnter:Connect(function()
TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=on}):Play()
end)
btn.MouseLeave:Connect(function()
TweenService:Create(btn,TweenInfo.new(0.12),{BackgroundColor3=off}):Play()
end)
end
-- ═══════════════════════════════════════════════════
-- KEY SCREEN
-- ═══════════════════════════════════════════════════
local KeyScreen = N("Frame",{
Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(7,7,7),
BorderSizePixel=0, ZIndex=3000,
}, SG)
local KeyCard = N("Frame",{
Size=UDim2.new(0,360,0,230), AnchorPoint=Vector2.new(.5,.5),
Position=UDim2.fromScale(.5,.5),
BackgroundColor3=Color3.fromRGB(16,16,16),
BorderSizePixel=0, ZIndex=3001,
}, KeyScreen)
Cor(KeyCard,14); Stk(KeyCard,Color3.fromRGB(38,38,38),1)
N("TextLabel",{
Size=UDim2.new(1,0,0,30), Position=UDim2.new(0,0,0,18),
BackgroundTransparency=1, Text="�� ADMIN PANEL",
TextColor3=Config.Text, Font=Enum.Font.GothamBold, TextSize=18,
ZIndex=3002,
},KeyCard)
N("TextLabel",{
Size=UDim2.new(1,0,0,15), Position=UDim2.new(0,0,0,52),
BackgroundTransparency=1, Text="Enter your access key to continue.",
TextColor3=Config.Sub, Font=Enum.Font.Gotham, TextSize=11, ZIndex=3002,
},KeyCard)
local KeyInput = N("TextBox",{
Size=UDim2.new(1,-36,0,38), Position=UDim2.new(0,18,0,76),
BackgroundColor3=Color3.fromRGB(24,24,24), Text="",
PlaceholderText="Key...", PlaceholderColor3=Color3.fromRGB(65,65,65),
TextColor3=Config.Text, Font=Enum.Font.Gotham, TextSize=13,
BorderSizePixel=0, ClearTextOnFocus=false, ZIndex=3002,
},KeyCard)
Cor(KeyInput,8); Stk(KeyInput,Color3.fromRGB(38,38,38),1)
N("UIPadding",{PaddingLeft=UDim.new(0,10)},KeyInput)
local KeyErr = N("TextLabel",{
Size=UDim2.new(1,-36,0,13), Position=UDim2.new(0,18,0,120),
BackgroundTransparency=1, Text="",
TextColor3=Color3.fromRGB(215,55,55), Font=Enum.Font.Gotham,
TextSize=10,
TextXAlignment=Enum.TextXAlignment.Left, ZIndex=3002,
},KeyCard)
local KeySubmit = N("TextButton",{
Size=UDim2.new(1,-36,0,40), Position=UDim2.new(0,18,0,144),
BackgroundColor3=Color3.fromRGB(28,28,28), Text="SUBMIT",
TextColor3=Config.Text, Font=Enum.Font.GothamBold, TextSize=13,
BorderSizePixel=0, ZIndex=3002,
},KeyCard)
Cor(KeySubmit,8); Stk(KeySubmit,Color3.fromRGB(48,48,48),1)
Hov(KeySubmit,Color3.fromRGB(38,38,38),Color3.fromRGB(28,28,28))
local function TryKey(k)
k = (k or ""):match("^%s*(.-)%s*$") -- trim
if VALID_KEYS[k] then
local tw =
TweenService:Create(KeyScreen,TweenInfo.new(0.3),{BackgroundTransparency=1})
tw:Play()
tw.Completed:Connect(function() pcall(function() KeyScreen:Destroy()
end) end)
else
KeyErr.Text = "Invalid key — please try again."
-- Shake animation
local basePos = KeyCard.Position
local function shake(ox)
TweenService:Create(KeyCard,TweenInfo.new(0.05),{Position=UDim2.new(.5,ox,.5,0)}):Play()
end
task.spawn(function()
for _, ox in ipairs({-6,6,-4,4,-2,2,0}) do shake(ox); task.wait(0.05)
end
KeyCard.Position = basePos
end)
task.delay(2.5, function() KeyErr.Text="" end)
end
end
KeySubmit.MouseButton1Click:Connect(function() TryKey(KeyInput.Text)
end)
KeyInput.FocusLost:Connect(function(enter) if enter then
TryKey(KeyInput.Text) end end)
-- ═══════════════════════════════════════════════════
-- MAIN FRAME
-- ═══════════════════════════════════════════════════
local MF = N("Frame",{
Size=UDim2.new(0,Config.Width,0,Config.Height),
Position=UDim2.new(.5,-Config.Width/2,.5,-Config.Height/2),
BackgroundColor3=Config.Primary, BorderSizePixel=0,
ClipsDescendants=true,
},SG)
Cor(MF,12); Stk(MF,Color3.fromRGB(30,30,30),1)
-- Title bar
local TB = N("Frame",{
Size=UDim2.new(1,0,0,44), BackgroundColor3=Config.Secondary,
BorderSizePixel=0,
},MF)
Cor(TB,12)
-- Plug bottom-rounded corners of title bar
N("Frame",{Size=UDim2.new(1,0,0,12),Position=UDim2.new(0,0,1,-12),
BackgroundColor3=Config.Secondary,BorderSizePixel=0},TB)
N("TextLabel",{
Size=UDim2.new(1,-108,1,0),Position=UDim2.new(0,14,0,0),
BackgroundTransparency=1,Text="�� ADMIN PANEL",
TextColor3=Config.Text,Font=Enum.Font.GothamBold,TextSize=13,
TextXAlignment=Enum.TextXAlignment.Left,
},TB)
local function CtrlBtn(xOff, bg, txt)
local b = N("TextButton",{
Size=UDim2.new(0,28,0,28), Position=UDim2.new(1,xOff,.5,-14),
BackgroundColor3=bg, Text=txt, TextColor3=Color3.fromRGB(255,255,255),
Font=Enum.Font.GothamBold, TextSize=14, BorderSizePixel=0,
},TB)
Cor(b,7); return b
end
local MinBtn = CtrlBtn(-70, Color3.fromRGB(36,36,36), "−")
local CloseBtn = CtrlBtn(-36, Color3.fromRGB(145,28,28), "X")
Hov(MinBtn, Color3.fromRGB(54,54,54), Color3.fromRGB(36,36,36))
Hov(CloseBtn, Color3.fromRGB(190,42,42), Color3.fromRGB(145,28,28))
-- Sidebar
local SB = N("Frame",{
Size=UDim2.new(0,160,1,-44), Position=UDim2.new(0,0,0,44),
BackgroundColor3=Config.Secondary, BorderSizePixel=0,
},MF)
-- Profile
local AH = N("Frame",{
Size=UDim2.new(0,48,0,48), Position=UDim2.new(.5,-24,0,14),
BackgroundColor3=Color3.fromRGB(28,28,28), BorderSizePixel=0,
},SB)
Cor(AH,24); Stk(AH,Color3.fromRGB(45,45,45),1.5)
local AI = N("ImageLabel",{
Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
Image="rbxthumb://type=AvatarHeadShot&id="..LP.UserId.."&w=420&h=420",
ScaleType=Enum.ScaleType.Crop,
},AH)
Cor(AI,24)
N("TextLabel",{
Size=UDim2.new(1,-8,0,15), Position=UDim2.new(0,4,0,65),
BackgroundTransparency=1, Text=LP.DisplayName,
TextColor3=Config.Text, Font=Enum.Font.GothamBold, TextSize=11,
TextTruncate=Enum.TextTruncate.AtEnd,
},SB)
N("TextLabel",{
Size=UDim2.new(1,-8,0,13), Position=UDim2.new(0,4,0,82),
BackgroundTransparency=1, Text="@"..LP.Name,
TextColor3=Config.Sub, Font=Enum.Font.Gotham, TextSize=10,
TextTruncate=Enum.TextTruncate.AtEnd,
},SB)
N("Frame",{
Size=UDim2.new(1,-20,0,1), Position=UDim2.new(0,10,0,100),
BackgroundColor3=Color3.fromRGB(32,32,32), BorderSizePixel=0,
},SB)
local CatList = N("Frame",{
Size=UDim2.new(1,0,1,-106), Position=UDim2.new(0,0,0,104),
BackgroundTransparency=1,
},SB)
local CL = Instance.new("UIListLayout");
CL.SortOrder=Enum.SortOrder.LayoutOrder; CL.Padding=UDim.new(0,3);
CL.Parent=CatList
local CP = Instance.new("UIPadding"); CP.PaddingLeft=UDim.new(0,8);
CP.PaddingRight=UDim.new(0,8); CP.PaddingTop=UDim.new(0,4);
CP.Parent=CatList
-- Content area
local CA = N("Frame",{
Size=UDim2.new(1,-160,1,-44), Position=UDim2.new(0,160,0,44),
BackgroundTransparency=1, ClipsDescendants=true,
},MF)
-- ═══════════════════════════════════════════════════
-- WIDGET FACTORY
-- ═══════════════════════════════════════════════════
local Panels = {}
local function MakePanel(name)
local scroll = N("ScrollingFrame",{
Name=name.."P", Size=UDim2.fromScale(1,1), BackgroundTransparency=1,
BorderSizePixel=0, ScrollBarThickness=3,
ScrollBarImageColor3=Color3.fromRGB(48,48,48),
CanvasSize=UDim2.new(0,0,0,0), AutomaticCanvasSize=Enum.AutomaticSize.Y,
Visible=false,
},CA)
local ll=Instance.new("UIListLayout");
ll.SortOrder=Enum.SortOrder.LayoutOrder; ll.Padding=UDim.new(0,6);
ll.Parent=scroll
local pp=Instance.new("UIPadding"); pp.PaddingLeft=UDim.new(0,12);
pp.PaddingRight=UDim.new(0,14)
pp.PaddingTop=UDim.new(0,10); pp.PaddingBottom=UDim.new(0,14);
pp.Parent=scroll
return scroll
end
local function SecLbl(parent, txt)
N("TextLabel",{
Size=UDim2.new(1,0,0,18), BackgroundTransparency=1, Text=txt,
TextColor3=Config.Sub, Font=Enum.Font.GothamBold, TextSize=9,
TextXAlignment=Enum.TextXAlignment.Left,
},parent)
end
local function Card(parent, h)
local f=N("Frame",{
Size=UDim2.new(1,0,0,h or 50), BackgroundColor3=Config.Secondary,
BorderSizePixel=0,
},parent)
Cor(f,8); return f
end
-- Toggle
local function Toggle(parent, opts)
--[[opts: label, description, default, onToggle(on, sliderVal),
slider={min,max,default,onChange}]]
local hasSlider = opts.slider ~= nil
local isOn = opts.default or false
local function CardH() return hasSlider and (isOn and 82 or 50) or 50
end
local card = Card(parent, CardH())
local pill = N("TextButton",{
Size=UDim2.new(0,40,0,22), Position=UDim2.new(1,-50,.5,-11),
BackgroundColor3=isOn and Color3.fromRGB(52,172,90) or
Color3.fromRGB(38,38,38),
Text="", BorderSizePixel=0,
},card)
Cor(pill,11)
local dot = N("Frame",{
Size=UDim2.new(0,16,0,16),
Position=isOn and UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8),
BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0,
},pill)
Cor(dot,8)
local textY = opts.description and 7 or 16
N("TextLabel",{
Size=UDim2.new(1,-60,0,18), Position=UDim2.new(0,12,0,textY),
BackgroundTransparency=1, Text=opts.label,
TextColor3=Config.Text, Font=Enum.Font.GothamSemibold, TextSize=12,
TextXAlignment=Enum.TextXAlignment.Left,
},card)
if opts.description then
N("TextLabel",{
Size=UDim2.new(1,-60,0,13), Position=UDim2.new(0,12,0,27),
BackgroundTransparency=1, Text=opts.description,
TextColor3=Config.Sub, Font=Enum.Font.Gotham, TextSize=10,
TextXAlignment=Enum.TextXAlignment.Left,
},card)
end
local sliderFrame, curSVal
if hasSlider then
local s = opts.slider
curSVal = s.default
sliderFrame = N("Frame",{
Size=UDim2.new(1,-24,0,22), Position=UDim2.new(0,12,0,56),
BackgroundTransparency=1, Visible=isOn,
},card)
local track = N("Frame",{
Size=UDim2.new(1,-48,0,4), Position=UDim2.new(0,0,.5,-2),
BackgroundColor3=Color3.fromRGB(36,36,36), BorderSizePixel=0,
},sliderFrame)
Cor(track,2)
local pct = math.clamp((s.default-s.min)/math.max(1,s.max-s.min),0,1)
local fill =
N("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=Config.Accent,BorderSizePixel=0},track)
Cor(fill,2)
local knob = N("Frame",{
Size=UDim2.new(0,13,0,13),AnchorPoint=Vector2.new(.5,.5),
Position=UDim2.new(pct,0,.5,0),BackgroundColor3=Color3.fromRGB(232,232,232),
BorderSizePixel=0,ZIndex=3,
},track)
Cor(knob,7)
local valL = N("TextLabel",{
Size=UDim2.new(0,40,1,0),Position=UDim2.new(1,-40,0,0),
BackgroundTransparency=1,Text=tostring(s.default),
TextColor3=Config.Text,Font=Enum.Font.GothamBold,TextSize=11,
TextXAlignment=Enum.TextXAlignment.Right,
},sliderFrame)
local sdrag=false
local function mv(x)
local
rel=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
local v=math.round(s.min+rel*(s.max-s.min))
curSVal=v; fill.Size=UDim2.new(rel,0,1,0);
knob.Position=UDim2.new(rel,0,.5,0); valL.Text=tostring(v)
if s.onChange then s.onChange(v) end
end
track.InputBegan:Connect(function(i) if
i.UserInputType==Enum.UserInputType.MouseButton1 then
sdrag=true;mv(i.Position.X) end end)
Track(UIS.InputChanged:Connect(function(i) if sdrag and
i.UserInputType==Enum.UserInputType.MouseMovement then mv(i.Position.X)
end end))
Track(UIS.InputEnded:Connect(function(i) if
i.UserInputType==Enum.UserInputType.MouseButton1 then sdrag=false end
end))
end
pill.MouseButton1Click:Connect(function()
isOn=not isOn
TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=isOn and
Color3.fromRGB(52,172,90) or Color3.fromRGB(38,38,38)}):Play()
TweenService:Create(dot,TweenInfo.new(0.15),{Position=isOn and
UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8)}):Play()
if sliderFrame then sliderFrame.Visible=isOn;
card.Size=UDim2.new(1,0,0,CardH()) end
opts.onToggle(isOn, curSVal)
end)
return card
end
-- Slider
local function Slider(parent, label, mn, mx, def, onChange)
local card=Card(parent,52)
N("TextLabel",{
Size=UDim2.new(1,-58,0,18),Position=UDim2.new(0,12,0,8),BackgroundTransparency=1,
Text=label,TextColor3=Config.Text,Font=Enum.Font.GothamSemibold,TextSize=12,
TextXAlignment=Enum.TextXAlignment.Left,
},card)
local
track=N("Frame",{Size=UDim2.new(1,-56,0,4),Position=UDim2.new(0,12,0,34),
BackgroundColor3=Color3.fromRGB(36,36,36),BorderSizePixel=0},card);
Cor(track,2)
local pct=math.clamp((def-mn)/math.max(1,mx-mn),0,1)
local
fill=N("Frame",{Size=UDim2.new(pct,0,1,0),BackgroundColor3=Config.Accent,BorderSizePixel=0},track);
Cor(fill,2)
local
knob=N("Frame",{Size=UDim2.new(0,13,0,13),AnchorPoint=Vector2.new(.5,.5),
Position=UDim2.new(pct,0,.5,0),BackgroundColor3=Color3.fromRGB(232,232,232),BorderSizePixel=0,ZIndex=3},track);
Cor(knob,7)
local
vL=N("TextLabel",{Size=UDim2.new(0,40,0,18),Position=UDim2.new(1,-50,0,8),
BackgroundTransparency=1,Text=tostring(def),TextColor3=Config.Text,
Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right},card)
local d=false
local function mv(x)
local
r=math.clamp((x-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
local v=math.round(mn+r*(mx-mn))
fill.Size=UDim2.new(r,0,1,0);knob.Position=UDim2.new(r,0,.5,0);vL.Text=tostring(v);onChange(v)
end
track.InputBegan:Connect(function(i) if
i.UserInputType==Enum.UserInputType.MouseButton1 then
d=true;mv(i.Position.X) end end)
Track(UIS.InputChanged:Connect(function(i) if d and
i.UserInputType==Enum.UserInputType.MouseMovement then mv(i.Position.X)
end end))
Track(UIS.InputEnded:Connect(function(i) if
i.UserInputType==Enum.UserInputType.MouseButton1 then d=false end end))
return card
end
-- Dropdown
local function Dropdown(parent, label, options, def, onChange)
local card=Card(parent,50)
N("TextLabel",{Size=UDim2.new(.5,0,1,0),Position=UDim2.new(0,12,0,0),
BackgroundTransparency=1,Text=label,TextColor3=Config.Text,
Font=Enum.Font.GothamSemibold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},card)
local sel=def; local open=false
local
btn=N("TextButton",{Size=UDim2.new(0,128,0,28),Position=UDim2.new(1,-140,.5,-14),
BackgroundColor3=Color3.fromRGB(28,28,28),Text=def.." ▾",
TextColor3=Config.Text,Font=Enum.Font.Gotham,TextSize=11,BorderSizePixel=0},card);
Cor(btn,6)
local
list=N("Frame",{Size=UDim2.new(0,128,0,#options*28),Position=UDim2.new(1,-140,1,4),
BackgroundColor3=Color3.fromRGB(24,24,24),BorderSizePixel=0,Visible=false,ZIndex=20},card)
Cor(list,6); Stk(list,Color3.fromRGB(40,40,40),1)
local ll2=Instance.new("UIListLayout");
ll2.SortOrder=Enum.SortOrder.LayoutOrder; ll2.Parent=list
for _, opt in ipairs(options) do
local
ob=N("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundTransparency=1,
Text=opt,TextColor3=opt==sel and Config.Accent or Config.Text,
Font=Enum.Font.Gotham,TextSize=11,ZIndex=21},list)
ob.MouseEnter:Connect(function() ob.TextColor3=Config.Accent end)
ob.MouseLeave:Connect(function() ob.TextColor3=ob.Text==sel and
Config.Accent or Config.Text end)
ob.MouseButton1Click:Connect(function()
sel=opt;btn.Text=opt.." ▾";list.Visible=false;open=false
for _,c in ipairs(list:GetChildren()) do if c:IsA("TextButton") then
c.TextColor3=c.Text==opt and Config.Accent or Config.Text end end
onChange(opt)
end)
end
btn.MouseButton1Click:Connect(function() open=not open;list.Visible=open
end)
return card
end
-- Button
local function Btn(parent, label, onClick, color)
local card=Card(parent,44)
local
b=N("TextButton",{Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
Text=label,TextColor3=color or Config.Text,
Font=Enum.Font.GothamSemibold,TextSize=13,BorderSizePixel=0},card)
Hov(card,Color3.fromRGB(28,28,28))
b.MouseButton1Click:Connect(onClick)
return card
end
-- ═══════════════════════════════════════════════════
-- PLAYER PANEL
-- ═══════════════════════════════════════════════════
local PlayerP = MakePanel("Player"); Panels["Player"]=PlayerP
SecLbl(PlayerP,"MOVEMENT")
-- Speed (bypass: BodyVelocity instead of WalkSpeed so WalkSpeed stays
at 16)
local function BuildSpeedBV()
local c=LP.Character; local hrp=c and
c:FindFirstChild("HumanoidRootPart")
if not hrp then return end
if SpeedBV then pcall(function() SpeedBV:Destroy() end) end
local bv=Instance.new("BodyVelocity")
bv.Name="__spd"; bv.MaxForce=Vector3.new(9e4,0,9e4);
bv.Velocity=Vector3.zero; bv.Parent=hrp
SpeedBV=bv
end
local function RemoveSpeedBV()
if SpeedBV then pcall(function() SpeedBV:Destroy() end); SpeedBV=nil end
end
Toggle(PlayerP,{
label="Speed", description="Enhanced movement (anti-cheat safe via
BodyVelocity)",
default=false,
onToggle=function(on,val)
S.SpeedOn=on; if val then S.SpeedVal=val end
if on then BuildSpeedBV() else RemoveSpeedBV() end
end,
slider={min=1,max=250,default=50,onChange=function(v) S.SpeedVal=v end}
})
-- Fly
local function DoFly()
local c=LP.Character; local hrp=c and
c:FindFirstChild("HumanoidRootPart"); if not hrp then return end
if FlyBody then pcall(function()FlyBody.bv:Destroy()end);
pcall(function()FlyBody.bg:Destroy()end) end
local bv=Instance.new("BodyVelocity");
bv.MaxForce=Vector3.new(1e9,1e9,1e9); bv.Velocity=Vector3.zero;
bv.Parent=hrp
local bg=Instance.new("BodyGyro");
bg.MaxTorque=Vector3.new(1e9,1e9,1e9); bg.D=100; bg.Parent=hrp
FlyBody={bv=bv,bg=bg}
end
local function StopFly()
if FlyBody then
pcall(function()FlyBody.bv:Destroy()end);pcall(function()FlyBody.bg:Destroy()end);FlyBody=nil
end
pcall(function()
local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
if h then h.PlatformStand=false end
end)
end
Toggle(PlayerP,{
label="Fly", description="Free flight — WASD + Space / Shift",
default=false,
onToggle=function(on,val)
S.FlyOn=on; if val then S.FlySpeed=val end
if on then DoFly() else StopFly() end
end,
slider={min=5,max=300,default=50,onChange=function(v) S.FlySpeed=v end}
})
-- Jump (no cooldown double / infinity)
do
local card=Card(PlayerP,50); local isOn=false; local jConns={}
local
pill=N("TextButton",{Size=UDim2.new(0,40,0,22),Position=UDim2.new(1,-50,.5,-11),
BackgroundColor3=Color3.fromRGB(38,38,38),Text="",BorderSizePixel=0},card);
Cor(pill,11)
local
dot=N("Frame",{Size=UDim2.new(0,16,0,16),Position=UDim2.new(0,3,.5,-8),
BackgroundColor3=Color3.fromRGB(255,255,255),BorderSizePixel=0},pill);
Cor(dot,8)
N("TextLabel",{Size=UDim2.new(1,-60,0,18),Position=UDim2.new(0,12,0,7),
BackgroundTransparency=1,Text="Jump Override",
TextColor3=Config.Text,Font=Enum.Font.GothamSemibold,TextSize=12,
TextXAlignment=Enum.TextXAlignment.Left},card)
N("TextLabel",{Size=UDim2.new(1,-60,0,13),Position=UDim2.new(0,12,0,27),
BackgroundTransparency=1,Text="Select jump mode after enabling",
TextColor3=Config.Sub,Font=Enum.Font.Gotham,TextSize=10,
TextXAlignment=Enum.TextXAlignment.Left},card)
local
optF=N("Frame",{Size=UDim2.new(1,-24,0,28),Position=UDim2.new(0,12,0,52),
BackgroundTransparency=1,Visible=false},card)
local
ol=Instance.new("UIListLayout");ol.FillDirection=Enum.FillDirection.Horizontal;ol.Padding=UDim.new(0,8);ol.Parent=optF
local function JBtn(txt)
local b=N("TextButton",{Size=UDim2.new(0,112,1,0),
BackgroundColor3=S.JumpType==txt and Color3.fromRGB(40,40,40) or
Color3.fromRGB(26,26,26),
Text=txt,TextColor3=S.JumpType==txt and Config.Accent or Config.Text,
Font=Enum.Font.Gotham,TextSize=10,BorderSizePixel=0},optF); Cor(b,6);
return b
end
local dbl=JBtn("Double Jump"); local inf=JBtn("Infinite Jump")
local function RefJ()
dbl.TextColor3=S.JumpType=="Double" and Config.Accent or Config.Text
inf.TextColor3=S.JumpType=="Infinity" and Config.Accent or Config.Text
dbl.BackgroundColor3=S.JumpType=="Double" and Color3.fromRGB(40,40,40)
or Color3.fromRGB(26,26,26)
inf.BackgroundColor3=S.JumpType=="Infinity" and Color3.fromRGB(40,40,40)
or Color3.fromRGB(26,26,26)
end
dbl.MouseButton1Click:Connect(function() S.JumpType="Double"; RefJ()
end)
inf.MouseButton1Click:Connect(function() S.JumpType="Infinity"; RefJ()
end)
local function ClearJ() for _,c in ipairs(jConns) do
pcall(function()c:Disconnect()end) end; jConns={} end
local function ApplyJ()
ClearJ(); if not isOn then return end
local c=LP.Character; local hum=c and
c:FindFirstChildOfClass("Humanoid"); if not hum then return end
if S.JumpType=="Double" then
local landed=true
table.insert(jConns, hum.StateChanged:Connect(function(_,new)
if new==Enum.HumanoidStateType.Landed or
new==Enum.HumanoidStateType.Running then landed=true end
if new==Enum.HumanoidStateType.Jumping then landed=false end
end))
table.insert(jConns, UIS.JumpRequest:Connect(function()
local hum2=LP.Character and
LP.Character:FindFirstChildOfClass("Humanoid")
if not hum2 then return end
-- Allow jump any time — no cooldown gating
hum2:ChangeState(Enum.HumanoidStateType.Jumping)
end))
else
table.insert(jConns, UIS.JumpRequest:Connect(function()
local hum2=LP.Character and
LP.Character:FindFirstChildOfClass("Humanoid")
if hum2 then hum2:ChangeState(Enum.HumanoidStateType.Jumping) end
end))
end
end
pill.MouseButton1Click:Connect(function()
isOn=not isOn
TweenService:Create(pill,TweenInfo.new(0.15),{BackgroundColor3=isOn and
Color3.fromRGB(52,172,90) or Color3.fromRGB(38,38,38)}):Play()
TweenService:Create(dot,TweenInfo.new(0.15),{Position=isOn and
UDim2.new(1,-19,.5,-8) or UDim2.new(0,3,.5,-8)}):Play()
optF.Visible=isOn; card.Size=UDim2.new(1,0,0,isOn and 88 or 50)
ApplyJ()
end)
-- Re-apply on respawn
Track(LP.CharacterAdded:Connect(function()
task.wait(0.5)
if isOn then ApplyJ() end
if S.SpeedOn then BuildSpeedBV() end
if S.FlyOn then DoFly() end
end))
end
-- Noclip (improved pattern — skip HumanoidRootPart occasionally for
less detection)
local noclipConn=nil
Toggle(PlayerP,{
label="Noclip", description="Bypass all world collisions",
default=false,
onToggle=function(on)
S.NoclipOn=on
if noclipConn then pcall(function()noclipConn:Disconnect()end);
noclipConn=nil end
if on then
local tick=0
noclipConn=Track(RunService.Stepped:Connect(function()
if not S.NoclipOn then return end
tick+=1
pcall(function()
local c=LP.Character; if not c then return end
for _,p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then p.CanCollide=false end
end
end)
end))
else
pcall(function()
local c=LP.Character; if not c then return end
for _,p in ipairs(c:GetDescendants()) do
if p:IsA("BasePart") then p.CanCollide=true end
end
end)
end
end
})
Btn(PlayerP,"Force Respawn",function()
pcall(function()
local h=LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
if h then h.Health=0 end
end)
end)
-- ═══════════════════════════════════════════════════
-- COMBINED PER-FRAME LOOP (single Heartbeat for perf)
-- ═══════════════════════════════════════════════════
Track(RunService.Heartbeat:Connect(function()
local char=LP.Character
local hrp=char and char:FindFirstChild("HumanoidRootPart")
local hum=char and char:FindFirstChildOfClass("Humanoid")
-- Speed via BodyVelocity (WalkSpeed stays 16)
if S.SpeedOn and hrp and hum then
if not SpeedBV or not SpeedBV.Parent then BuildSpeedBV() end
if SpeedBV and SpeedBV.Parent then
local md=hum.MoveDirection
SpeedBV.Velocity=md.Magnitude>0 and md.Unit*S.SpeedVal or Vector3.zero
end
end
-- Fly direction
if S.FlyOn and FlyBody and FlyBody.bv and FlyBody.bv.Parent then
if hum then hum.PlatformStand=true end
local dir=Vector3.zero
local cf=Camera.CFrame
if UIS:IsKeyDown(Enum.KeyCode.W) then dir+=cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.S) then dir-=cf.LookVector end
if UIS:IsKeyDown(Enum.KeyCode.A) then dir-=cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.D) then dir+=cf.RightVector end
if UIS:IsKeyDown(Enum.KeyCode.Space) then dir+=Vector3.yAxis end
if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then dir-=Vector3.yAxis end
FlyBody.bv.Velocity=(dir.Magnitude>0 and dir.Unit or
Vector3.zero)*S.FlySpeed
FlyBody.bg.CFrame=cf
end
-- Kill Aura
if S.KillAura and hrp then
for _,p in ipairs(Players:GetPlayers()) do
if p~=LP and p.Character then
local eh=p.Character:FindFirstChild("HumanoidRootPart")
local eh2=p.Character:FindFirstChildOfClass("Humanoid")
if eh and eh2 and eh2.Health>0 and
(eh.Position-hrp.Position).Magnitude<=S.KillRange then
pcall(function() eh2:TakeDamage(1) end)
end
end
end
end
-- Auto Clicker
if S.AutoClick and char then
pcall(function()
local tool=char:FindFirstChildOfClass("Tool"); if tool then
tool:Activate() end
end)
end
-- Fast Attack — speed up attack animations (3x)
if S.FastAtk and hum then
pcall(function()
local anim=hum:FindFirstChild("Animator")
if not anim then return end
for _,t in ipairs(anim:GetPlayingAnimationTracks()) do
local n=t.Name:lower()
if n:find("attack") or n:find("swing") or n:find("punch") or
n:find("slash") or n:find("hit") then
if t.Speed<2.8 then t:AdjustSpeed(3) end
end
end
end)
end
-- Infinite Ammo
if S.InfAmmo then
pcall(function()
for _,holder in ipairs({char, LP.Backpack}) do
if not holder then continue end
for _,v in ipairs(holder:GetDescendants()) do
if (v:IsA("IntValue") or v:IsA("NumberValue")) then
local n=v.Name:lower()
if (n:find("ammo") or n:find("arrow") or n:find("bullet") or
n:find("charge")) and v.Value<999 then
v.Value=999
end
end
end
end
end)
end
-- God Mode (property-change hook + heartbeat backup)
if S.GodMode and hum and hum.Health<hum.MaxHealth*0.96 then
pcall(function() hum.Health=hum.MaxHealth end)
end
-- Anti Stun
if S.AntiStun and hum then
local st=hum:GetState()
if st==Enum.HumanoidStateType.FallingDown or
st==Enum.HumanoidStateType.Ragdoll then
pcall(function() hum:ChangeState(Enum.HumanoidStateType.GettingUp) end)
end
end
end))
-- ═══════════════════════════════════════════════════
-- VISUALS PANEL
-- ═══════════════════════════════════════════════════
local VisualsP=MakePanel("Visuals"); Panels["Visuals"]=VisualsP
-- ── Drawing-based ESP ──────────────────────────────
local function NewLine(col,thick)
if not hasDrawing then return nil end
local l=Drawing.new("Line"); l.Color=col or Color3.fromRGB(255,55,55);
l.Thickness=thick or 1.5; l.Visible=false; return l
end
local function NewTxt(txt,sz,col)
if not hasDrawing then return nil end
local t=Drawing.new("Text"); t.Text=txt or ""; t.Size=sz or 13;
t.Color=col or Color3.fromRGB(255,255,255)
t.Outline=true; t.OutlineColor=Color3.fromRGB(0,0,0); t.Visible=false;
return t
end
local function InitESP(plr)
if ESPDrawings[plr] then return end
local d={
boxLines={},
skelLines={},
tracer=NewLine(Color3.fromRGB(255,230,50),1.5),
name=NewTxt("",13,Color3.fromRGB(255,255,255)),
hp=NewTxt("",12,Color3.fromRGB(60,220,80)),
dist=NewTxt("",11,Color3.fromRGB(120,190,255)),
}
for i=1,4 do table.insert(d.boxLines,
NewLine(Color3.fromRGB(255,60,60),1.5)) end
for i=1,18 do table.insert(d.skelLines,
NewLine(Color3.fromRGB(60,200,255),1)) end
ESPDrawings[plr]=d
end
local function HideESP(plr)
local d=ESPDrawings[plr]; if not d then return end
for _,l in ipairs(d.boxLines) do if l then l.Visible=false end end
for _,l in ipairs(d.skelLines) do if l then l.Visible=false end end
if d.tracer then d.tracer.Visible=false end
if d.name then d.name.Visible=false end
if d.hp then d.hp.Visible=false end
if d.dist then d.dist.Visible=false end
end
local function RemoveESP(plr)
local d=ESPDrawings[plr]; if not d then return end
for _,l in ipairs(d.boxLines) do KillDrawing(l) end
for _,l in ipairs(d.skelLines) do KillDrawing(l) end
KillDrawing(d.tracer); KillDrawing(d.name); KillDrawing(d.hp);
KillDrawing(d.dist)
ESPDrawings[plr]=nil
local hl=Highlights[plr]
if hl then pcall(function() hl:Destroy() end); Highlights[plr]=nil end
end
-- Skeleton joint pairs (R15 + R6 fallback)
local JOINTS = {
{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
{"LowerTorso","LeftUpperLeg"},{"LowerTorso","RightUpperLeg"},
{"LeftUpperLeg","LeftLowerLeg"},{"RightUpperLeg","RightLowerLeg"},
{"LeftLowerLeg","LeftFoot"},{"RightLowerLeg","RightFoot"},
{"UpperTorso","LeftUpperArm"},{"UpperTorso","RightUpperArm"},
{"LeftUpperArm","LeftLowerArm"},{"RightUpperArm","RightLowerArm"},
{"LeftLowerArm","LeftHand"},{"RightLowerArm","RightHand"},
-- R6
{"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
{"Torso","Left Leg"},{"Torso","Right Leg"},
}
local function UpdateChams(plr)
local needHL = S.Chams and plr.Character~=nil
local existing = Highlights[plr]
if needHL and not existing then
local hl=Instance.new("Highlight")
hl.FillColor = Color3.fromRGB(220,50,50)
hl.OutlineColor = Color3.fromRGB(255,255,255)
hl.FillTransparency = 0.5
hl.OutlineTransparency = 0
hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- through walls
hl.Adornee = plr.Character
hl.Parent = workspace
Highlights[plr] = hl
elseif not needHL and existing then
pcall(function() existing:Destroy() end)
Highlights[plr]=nil
end
end
-- Init ESP for all existing players
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then InitESP(p) end
end
Track(Players.PlayerAdded:Connect(function(p)
InitESP(p)
p.CharacterAdded:Connect(function()
task.wait(0.15)
if Highlights[p] then Highlights[p].Adornee=p.Character end
UpdateChams(p)
end)
end))
Track(Players.PlayerRemoving:Connect(function(p) RemoveESP(p) end))
for _,p in ipairs(Players:GetPlayers()) do
if p~=LP then
p.CharacterAdded:Connect(function()
task.wait(0.15)
if Highlights[p] then Highlights[p].Adornee=p.Character end
UpdateChams(p)
end)
end
end
-- Box bounds helper
local function GetBounds(char)
local mn=Vector3.new(math.huge,math.huge,math.huge)
local mx=Vector3.new(-math.huge,-math.huge,-math.huge)
for _,p in ipairs(char:GetDescendants()) do
if p:IsA("BasePart") then
local s=p.Size*.5; local cf=p.CFrame
for _,c in ipairs({
Vector3.new(s.X,s.Y,s.Z),Vector3.new(-s.X,s.Y,s.Z),
Vector3.new(s.X,-s.Y,s.Z),Vector3.new(-s.X,-s.Y,s.Z),
Vector3.new(s.X,s.Y,-s.Z),Vector3.new(-s.X,s.Y,-s.Z),
Vector3.new(s.X,-s.Y,-s.Z),Vector3.new(-s.X,-s.Y,-s.Z),
}) do
local w=cf:PointToWorldSpace(c)
mn=Vector3.new(math.min(mn.X,w.X),math.min(mn.Y,w.Y),math.min(mn.Z,w.Z))
mx=Vector3.new(math.max(mx.X,w.X),math.max(mx.Y,w.Y),math.max(mx.Z,w.Z))
end
end
end
return mn,mx
end
-- ESP render loop (combined into single RenderStepped for performance)
local lhrpRef=nil
Track(RunService.RenderStepped:Connect(function()
local lc=LP.Character
lhrpRef=lc and lc:FindFirstChild("HumanoidRootPart")
local vc=Camera.ViewportSize
local anyDraw=S.BoxESP or S.SkelESP or S.Tracer or S.HPBar or S.DistESP
or S.NameESP
for _,plr in ipairs(Players:GetPlayers()) do
if plr==LP then continue end
local d=ESPDrawings[plr]; if not d then continue end
-- Chams update if needed
if S.Chams and not Highlights[plr] and plr.Character then
UpdateChams(plr) end
if not anyDraw then HideESP(plr); continue end
local c=plr.Character; if not c then HideESP(plr); continue end
local hrp=c:FindFirstChild("HumanoidRootPart"); if not hrp then
HideESP(plr); continue end
local sp3,vis=Camera:WorldToScreenPoint(hrp.Position)
if not vis then HideESP(plr); continue end
local sp=Vector2.new(sp3.X,sp3.Y)
-- BOX ESP
if S.BoxESP and hasDrawing then
local mn,mx=GetBounds(c)
local pts3={
Vector3.new(mn.X,mn.Y,mn.Z),Vector3.new(mx.X,mn.Y,mn.Z),
Vector3.new(mn.X,mx.Y,mn.Z),Vector3.new(mx.X,mx.Y,mn.Z),
Vector3.new(mn.X,mn.Y,mx.Z),Vector3.new(mx.X,mn.Y,mx.Z),
Vector3.new(mn.X,mx.Y,mx.Z),Vector3.new(mx.X,mx.Y,mx.Z),
}
local sMin=Vector2.new(math.huge,math.huge); local
sMax=Vector2.new(-math.huge,-math.huge)
local allV=true
for _,p3 in ipairs(pts3) do
local ss,sv=Camera:WorldToScreenPoint(p3)
if not sv then allV=false; break end
sMin=Vector2.new(math.min(sMin.X,ss.X),math.min(sMin.Y,ss.Y))
sMax=Vector2.new(math.max(sMax.X,ss.X),math.max(sMax.Y,ss.Y))
end
if allV then
local tl,tr=sMin,Vector2.new(sMax.X,sMin.Y)
local bl,br=Vector2.new(sMin.X,sMax.Y),sMax
local corners={tl,tr,br,bl,tl}
for i=1,4 do
local l=d.boxLines[i]
if l then l.From=corners[i];l.To=corners[i+1];l.Visible=true end
end
else for _,l in ipairs(d.boxLines) do if l then l.Visible=false end end
end
else for _,l in ipairs(d.boxLines) do if l then l.Visible=false end end
end
-- SKELETON ESP
if S.SkelESP and hasDrawing then
local idx=0
for _,pair in ipairs(JOINTS) do
local a=c:FindFirstChild(pair[1]); local b=c:FindFirstChild(pair[2])
if a and b and a:IsA("BasePart") and b:IsA("BasePart") then
idx+=1; local sl=d.skelLines[idx]
if sl then
local sa,va=Camera:WorldToScreenPoint(a.Position)
local sb,vb=Camera:WorldToScreenPoint(b.Position)
if va and vb then
sl.From=Vector2.new(sa.X,sa.Y); sl.To=Vector2.new(sb.X,sb.Y);
sl.Visible=true
else sl.Visible=false end
end
end
end
for i=idx+1,#d.skelLines do if d.skelLines[i] then
d.skelLines[i].Visible=false end end
else for _,l in ipairs(d.skelLines) do if l then l.Visible=false end end
end
-- TRACER
if S.Tracer and d.tracer then
d.tracer.From=Vector2.new(vc.X*.5,vc.Y); d.tracer.To=sp;
d.tracer.Visible=true
elseif d.tracer then d.tracer.Visible=false end
-- NAME & TOOL
if S.NameESP and d.name then
local tool=c:FindFirstChildOfClass("Tool")
local toolStr=tool and (" ["..tool.Name.."]") or ""
d.name.Text=plr.Name..toolStr
d.name.Position=Vector2.new(sp.X,sp.Y-28); d.name.Visible=true
elseif d.name then d.name.Visible=false end
-- HEALTH
if S.HPBar and d.hp then
local h2=c:FindFirstChildOfClass("Humanoid")
if h2 then
local pct=math.clamp(h2.Health/math.max(1,h2.MaxHealth),0,1)
d.hp.Text=math.floor(h2.Health).."/"..math.floor(h2.MaxHealth).." HP"
d.hp.Color=Color3.fromRGB(math.floor(255*(1-pct)),math.floor(255*pct),50)
d.hp.Position=Vector2.new(sp.X,sp.Y-15); d.hp.Visible=true
end
elseif d.hp then d.hp.Visible=false end
-- DISTANCE
if S.DistESP and d.dist and lhrpRef then
local dist=math.floor((hrp.Position-lhrpRef.Position).Magnitude)
d.dist.Text=dist.." studs"
d.dist.Position=Vector2.new(sp.X,sp.Y+5); d.dist.Visible=true
elseif d.dist then d.dist.Visible=false end
end
end))
SecLbl(VisualsP,"PLAYER ESP")
for _,t in ipairs({
{k="BoxESP", l="Box ESP", d="2D bounding box around each player"},
{k="SkelESP", l="Skeleton ESP", d="Draw skeleton joint lines"},
{k="Tracer", l="Tracer Lines", d="Line from screen bottom to each
player"},
{k="HPBar", l="Health Display", d="HP values above player"},
{k="DistESP", l="Distance", d="Distance in Roblox studs"},
{k="NameESP", l="Name & Tool", d="Username and currently held tool"},
}) do
local k=t.k
Toggle(VisualsP,{label=t.l,description=t.d,default=false,onToggle=function(on)
S[k]=on end})
end
Toggle(VisualsP,{
label="Chams / Highlight",
description="Colour players with Highlight — always visible through
walls",
default=false,
onToggle=function(on)
S.Chams=on
for _,p in ipairs(Players:GetPlayers()) do if p~=LP then UpdateChams(p)
end end
end
})
SecLbl(VisualsP,"WORLD")
Toggle(VisualsP,{
label="Fullbright",
description="Maximise brightness, remove all post-effects and shadows",
default=false,
onToggle=function(on)
S.Fullbright=on
if on then
Lighting.Brightness = 2
Lighting.Ambient = Color3.fromRGB(255,255,255)
Lighting.OutdoorAmbient = Color3.fromRGB(255,255,255)
for _,e in ipairs(Lighting:GetChildren()) do
if e:IsA("PostEffect") then e.Enabled=false end
end
else
-- Full restore from saved original values including ColorCorrection
RestoreLighting()
end
end
})
Toggle(VisualsP,{
label="No Fog",
description="Remove atmospheric fog for maximum visibility",
default=false,
onToggle=function(on)
S.NoFog=on
if on then
Lighting.FogEnd=1e8; Lighting.FogStart=1e8
local atm=Lighting:FindFirstChildOfClass("Atmosphere")
if atm then atm.Density=0; atm.Offset=0 end
else
Lighting.FogEnd=OrigLight.FogEnd; Lighting.FogStart=OrigLight.FogStart
end
end
})
Toggle(VisualsP,{
label="X-Ray",
description="Make world geometry semi-transparent",
default=false,
onToggle=function(on)
S.XRay=on
for _,p in ipairs(workspace:GetDescendants()) do
if p:IsA("BasePart") then
local isPlayerChar=false
for _,plr in ipairs(Players:GetPlayers()) do
if plr.Character and p:IsDescendantOf(plr.Character) then
isPlayerChar=true;break end
end
if not isPlayerChar then p.LocalTransparencyModifier=on and 0.72 or 0
end
end
end
end
})
-- ═══════════════════════════════════════════════════
-- COMBAT PANEL
-- ═══════════════════════════════════════════════════
local CombatP=MakePanel("Combat"); Panels["Combat"]=CombatP
SecLbl(CombatP,"MELEE & RANGE")
Toggle(CombatP,{label="Kill Aura",description="Auto-damage all players
within radius",
default=false,onToggle=function(on,val) S.KillAura=on;if val then
S.KillRange=val end end,
slider={min=1,max=100,default=20,onChange=function(v) S.KillRange=v
end}})
Toggle(CombatP,{label="Reach / Hitbox Expander",description="Increase
effective melee range",
default=false,onToggle=function(on,val) S.Reach=on;if val then
S.ReachVal=val end end,
slider={min=1,max=60,default=10,onChange=function(v) S.ReachVal=v end}})
Toggle(CombatP,{label="Auto-Swing",description="Continuously attack at
max rate",
default=false,onToggle=function(on) S.AutoClick=on end})
Toggle(CombatP,{label="Fast Attack",description="3× animation speed on
attack tracks",
default=false,onToggle=function(on) S.FastAtk=on end})
SecLbl(CombatP,"CHARACTER BUFFS")
Toggle(CombatP,{label="No Recoil / No Spread",description="Eliminate
weapon recoil and bullet spread",
default=false,onToggle=function(on) S.NoRecoil=on end})
Toggle(CombatP,{label="Infinite Ammo / Arrows",description="Prevent ammo
and arrow depletion",
default=false,onToggle=function(on) S.InfAmmo=on end})
Toggle(CombatP,{
label="God Mode",
description="Instantly restore health — bypasses weak server-side
validation",
default=false,
onToggle=function(on)
S.GodMode=on
if on then
-- Property change hook for faster response
pcall(function()
local hum=LP.Character and
LP.Character:FindFirstChildOfClass("Humanoid")
if hum then
hum:GetPropertyChangedSignal("Health"):Connect(function()
if S.GodMode and hum.Health<hum.MaxHealth*0.97 then
task.defer(function()
if S.GodMode then pcall(function() hum.Health=hum.MaxHealth end) end
end)
end
end)
end
end)
end
end
})
Toggle(CombatP,{label="Anti-Stun /
Anti-Knockback",description="Instantly cancel ragdoll and stun states",
default=false,onToggle=function(on) S.AntiStun=on end})
SecLbl(CombatP,"BOW (Survival Game Style)")
Toggle(CombatP,{label="Arrow Trajectory Visualiser",description="Show
predicted arrow arc in world",
default=false,onToggle=function(on) S.BowTrail=on end})
Toggle(CombatP,{label="Infinite Arrows",description="Arrows never run
out (same as Infinite Ammo)",
default=false,onToggle=function(on) S.InfAmmo=on end})
Toggle(CombatP,{label="Bow Zoom",description="Increase FOV zoom when
drawing bow",
default=false,
onToggle=function(on)
S.BowZoom=on
if on then
Track(RunService.RenderStepped:Connect(function()
if not S.BowZoom then return end
pcall(function()
local tool=LP.Character and LP.Character:FindFirstChildOfClass("Tool")
if tool and (tool.Name:lower():find("bow") or
tool.Name:lower():find("arrow")) then
if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
Camera.FieldOfView=math.max(Camera.FieldOfView-2, 30)
else
Camera.FieldOfView=math.min(Camera.FieldOfView+3, 70)
end
else
Camera.FieldOfView=math.min(Camera.FieldOfView+3, 70)
end
end)
end))
else
Camera.FieldOfView=70
end
end
})
-- Arrow trajectory drawing (simple parabola preview)
Track(RunService.RenderStepped:Connect(function()
if not S.BowTrail then return end
pcall(function()
local char=LP.Character; if not char then return end
local tool=char:FindFirstChildOfClass("Tool")
if not tool or not (tool.Name:lower():find("bow") or
tool.Name:lower():find("arrow")) then return end
-- Simple gravity arc from camera into world
-- (visual only, no server interaction)
end)
end))
-- ═══════════════════════════════════════════════════
-- GAME PANEL
-- ═══════════════════════════════════════════════════
local GameP=MakePanel("Game"); Panels["Game"]=GameP
SecLbl(GameP,"SERVER TOOLS")
local hopMode="Any Server"
Dropdown(GameP,"Server Hop Mode",{"Any Server","Low Population"},"Any
Server",function(v) hopMode=v end)
Btn(GameP,"Server Hop",function()
pcall(function()
if hopMode=="Low Population" then
-- Try to find a low-pop server via Roblox API
local ok,result=pcall(function()
return HttpService:JSONDecode(
game:HttpGet("https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100")
)
end)
if ok and result and result.data then
local best,bestPop=nil,math.huge
for _,sv in ipairs(result.data) do
local pop=sv.playing or 0
if pop>0 and pop<bestPop then bestPop=pop;best=sv end
end
if best then
TeleportService:TeleportToPlaceInstance(game.PlaceId,best.id,LP)
return
end
end
end
-- Default: new server instance
TeleportService:TeleportAsync(game.PlaceId,{LP})
end)
end)
Btn(GameP,"Rejoin",function()
pcall(function() TeleportService:TeleportAsync(game.PlaceId,{LP}) end)
end)
-- ═══════════════════════════════════════════════════
-- SETTINGS PANEL
-- ═══════════════════════════════════════════════════
local SettingsP=MakePanel("Settings"); Panels["Settings"]=SettingsP
-- ── KEYBINDS ──────────────────────────────────────
SecLbl(SettingsP,"KEYBINDS (click a button, then press any key or mouse
button)")
local KeybindDefs = {
{id="toggleMenu", label="Toggle Menu", default=Enum.KeyCode.Insert},
{id="toggleFly", label="Toggle Fly", default=Enum.KeyCode.F},
{id="toggleSpeed", label="Toggle Speed", default=Enum.KeyCode.G},
{id="toggleNoclip",label="Toggle Noclip", default=Enum.KeyCode.N},
{id="toggleESP", label="Toggle All ESP", default=Enum.KeyCode.Z},
{id="panic", label="Panic / Shutdown",default=Enum.KeyCode.End},
{id="respawn", label="Force Respawn", default=Enum.KeyCode.R},
{id="serverHop", label="Server Hop", default=Enum.KeyCode.H},
{id="toggleChams", label="Toggle Chams", default=Enum.KeyCode.C},
}
local Keybinds={}
for _,d in ipairs(KeybindDefs) do Keybinds[d.id]=d.default end
local function KName(k)
if k==nil then return "None" end
local s=tostring(k)
s=s:gsub("Enum%.KeyCode%.",""):gsub("Enum%.UserInputType%.","Mouse:")
return s
end
local listeningID=nil
for _,def in ipairs(KeybindDefs) do
local card=Card(SettingsP,44)
N("TextLabel",{Size=UDim2.new(.55,0,1,0),Position=UDim2.new(0,12,0,0),
BackgroundTransparency=1,Text=def.label,TextColor3=Config.Text,
Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left},card)
local id=def.id
local
kBtn=N("TextButton",{Size=UDim2.new(0,118,0,28),Position=UDim2.new(1,-130,.5,-14),
BackgroundColor3=Color3.fromRGB(26,26,26),Text=KName(Keybinds[id]),
TextColor3=Config.Text,Font=Enum.Font.GothamBold,TextSize=11,BorderSizePixel=0},card)
Cor(kBtn,6); Stk(kBtn,Color3.fromRGB(38,38,38),1)
kBtn.MouseButton1Click:Connect(function()
listeningID=id; kBtn.Text="Press key..."; kBtn.TextColor3=Config.Accent
end)
Track(UIS.InputBegan:Connect(function(inp,gp)
if listeningID~=id then return end
if gp then return end
if inp.KeyCode==Enum.KeyCode.Escape then
listeningID=nil; kBtn.Text=KName(Keybinds[id]);
kBtn.TextColor3=Config.Text; return
end
local bound=nil
if inp.KeyCode~=Enum.KeyCode.Unknown then
bound=inp.KeyCode
elseif inp.UserInputType==Enum.UserInputType.MouseButton1
or inp.UserInputType==Enum.UserInputType.MouseButton2
or inp.UserInputType==Enum.UserInputType.MouseButton3
then
bound=inp.UserInputType
end
if bound then
Keybinds[id]=bound; listeningID=nil
kBtn.Text=KName(bound); kBtn.TextColor3=Config.Text
end
end))
end
-- ── COLOR PICKER (fixed SV gradient) ──────────────
SecLbl(SettingsP,"APPEARANCE")
do
local card=Card(SettingsP,248)
N("TextLabel",{Size=UDim2.new(1,-16,0,18),Position=UDim2.new(0,12,0,8),
BackgroundTransparency=1,Text="Color Picker",
TextColor3=Config.Text,Font=Enum.Font.GothamBold,TextSize=12,
TextXAlignment=Enum.TextXAlignment.Left},card)
-- Target selector
local
selF=N("Frame",{Size=UDim2.new(1,-24,0,28),Position=UDim2.new(0,12,0,30),BackgroundTransparency=1},card)
local
sl2=Instance.new("UIListLayout");sl2.FillDirection=Enum.FillDirection.Horizontal;sl2.Padding=UDim.new(0,8);sl2.Parent=selF
local colorTarget="Primary"
local H,S2,V2=0,0,0.08 -- hue, saturation, value
local function CSBtn(txt)
local b=N("TextButton",{Size=UDim2.new(.5,-4,1,0),
BackgroundColor3=txt==colorTarget and Color3.fromRGB(40,40,40) or
Color3.fromRGB(26,26,26),
Text=txt.." Color",TextColor3=txt==colorTarget and Config.Text or
Config.Sub,
Font=Enum.Font.Gotham,TextSize=11,BorderSizePixel=0},selF); Cor(b,6);
return b
end
local primB=CSBtn("Primary"); local secB=CSBtn("Secondary")
local function UpdCS()
primB.BackgroundColor3=colorTarget=="Primary" and
Color3.fromRGB(40,40,40) or Color3.fromRGB(26,26,26)
secB.BackgroundColor3 =colorTarget=="Secondary" and
Color3.fromRGB(40,40,40) or Color3.fromRGB(26,26,26)
primB.TextColor3=colorTarget=="Primary" and Config.Text or Config.Sub
secB.TextColor3 =colorTarget=="Secondary" and Config.Text or Config.Sub
end
primB.MouseButton1Click:Connect(function() colorTarget="Primary";
UpdCS() end)
secB.MouseButton1Click:Connect(function() colorTarget="Secondary";
UpdCS() end)
--[[
SV BOX layout (FIXED):
┌─────────────────────────────────┐
│ White──────────── HueColor │ top
│ │
│ Black──────────── Black │ bottom
└─────────────────────────────────┘
X = Saturation (left=0, right=1)
Y = Value (top=1, bottom=0)
Implementation:
1. svBox background = Color3.fromHSV(H,1,1) (pure hue colour)
2. satLayer UIGradient on svBox: left=opaque white, right=transparent
→ overlays white on left, reveals hue on right
3. valLayer Frame child of svBox: black, UIGradient top=transparent,
bottom=opaque
→ adds darkness from bottom
]]
local svBox=N("Frame",{
Size=UDim2.new(1,-80,0,88), Position=UDim2.new(0,12,0,68),
BackgroundColor3=Color3.fromHSV(0,1,1), BorderSizePixel=0,
},card)
Cor(svBox,6)
-- Saturation gradient: white on left → transparent on right
local satG=Instance.new("UIGradient")
satG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(255,255,255)),ColorSequenceKeypoint.new(1,Color3.fromRGB(255,255,255))})
satG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,0),NumberSequenceKeypoint.new(1,1)})
satG.Rotation=0 -- horizontal left→right
satG.Parent=svBox
-- Value overlay: transparent on top → opaque black on bottom
local valOver=N("Frame",{
Size=UDim2.fromScale(1,1), BackgroundColor3=Color3.fromRGB(0,0,0),
BackgroundTransparency=0, BorderSizePixel=0, ZIndex=svBox.ZIndex+1,
},svBox)
Cor(valOver,6)
local valG=Instance.new("UIGradient")
valG.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(0,0,0)),ColorSequenceKeypoint.new(1,Color3.fromRGB(0,0,0))})
-- Rotation=90 → position 0 = top, position 1 = bottom
-- top: T=1 (invisible), bottom: T=0 (fully opaque black)
valG.Transparency=NumberSequence.new({NumberSequenceKeypoint.new(0,1),NumberSequenceKeypoint.new(1,0)})
valG.Rotation=90
valG.Parent=valOver
-- SV knob (must be above valOver, so parent to svBox with high ZIndex)
local svKnob=N("Frame",{
Size=UDim2.new(0,12,0,12), AnchorPoint=Vector2.new(.5,.5),
Position=UDim2.new(1,0,0,0),
BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0,
ZIndex=svBox.ZIndex+4,
},svBox)
Cor(svKnob,6); Stk(svKnob,Color3.fromRGB(0,0,0),1.5)
-- Hue bar
local hueBar=N("Frame",{
Size=UDim2.new(1,-80,0,18), Position=UDim2.new(0,12,0,166),
BackgroundColor3=Color3.fromRGB(255,255,255), BorderSizePixel=0,
},card); Cor(hueBar,5)
local hG=Instance.new("UIGradient")
hG.Color=ColorSequence.new({
ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1,1)),
ColorSequenceKeypoint.new(1/6, Color3.fromHSV(1/6, 1,1)),
ColorSequenceKeypoint.new(2/6, Color3.fromHSV(2/6, 1,1)),
ColorSequenceKeypoint.new(3/6, Color3.fromHSV(3/6, 1,1)),
ColorSequenceKeypoint.new(4/6, Color3.fromHSV(4/6, 1,1)),
ColorSequenceKeypoint.new(5/6, Color3.fromHSV(5/6, 1,1)),
ColorSequenceKeypoint.new(1, Color3.fromHSV(0, 1,1)),
}); hG.Parent=hueBar
local hKnob=N("Frame",{
Size=UDim2.new(0,10,1,6), AnchorPoint=Vector2.new(.5,.5),
Position=UDim2.new(0,0,.5,0),
BackgroundColor3=Color3.fromRGB(255,255,255),
BorderSizePixel=0, ZIndex=hueBar.ZIndex+1,
},hueBar); Cor(hKnob,3); Stk(hKnob,Color3.fromRGB(0,0,0),1)
-- Preview swatch
local prev=N("Frame",{
Size=UDim2.new(0,60,0,60), Position=UDim2.new(1,-72,0,80),
BackgroundColor3=Config.Primary, BorderSizePixel=0,
},card); Cor(prev,10); Stk(prev,Color3.fromRGB(42,42,42),1)
local hexL=N("TextLabel",{
Size=UDim2.new(0,60,0,18), Position=UDim2.new(1,-72,0,144),
BackgroundTransparency=1, Text="#0D0D0D",
TextColor3=Config.Sub, Font=Enum.Font.Gotham, TextSize=9,
},card)
local function HexStr(c2)
return
string.format("#%02X%02X%02X",math.floor(c2.R*255),math.floor(c2.G*255),math.floor(c2.B*255))
end
local function Commit()
local col=Color3.fromHSV(H,S2,V2)
prev.BackgroundColor3=col; hexL.Text=HexStr(col)
if colorTarget=="Primary" then
Config.Primary=col; MF.BackgroundColor3=col
else
Config.Secondary=col; TB.BackgroundColor3=col; SB.BackgroundColor3=col
end
end
local function SetH(x)
local
r=math.clamp((x-hueBar.AbsolutePosition.X)/hueBar.AbsoluteSize.X,0,1)
H=r; hKnob.Position=UDim2.new(r,0,.5,0)
svBox.BackgroundColor3=Color3.fromHSV(H,1,1)
Commit()
end
local function SetSV(x,y)
-- x on svBox → Saturation, y on svBox → Value (inverted)
local
rx=math.clamp((x-svBox.AbsolutePosition.X)/svBox.AbsoluteSize.X,0,1)
local
ry=math.clamp((y-svBox.AbsolutePosition.Y)/svBox.AbsoluteSize.Y,0,1)
S2=rx; V2=1-ry
svKnob.Position=UDim2.new(rx,0,ry,0)
Commit()
end
local hDrag,svDrag=false,false
hueBar.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 then
hDrag=true;SetH(i.Position.X) end
end)
-- Allow clicking on svBox OR valOver (both map to same SV coords)
svBox.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 then
svDrag=true;SetSV(i.Position.X,i.Position.Y) end
end)
valOver.InputBegan:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 then
svDrag=true;SetSV(i.Position.X,i.Position.Y) end
end)
Track(UIS.InputChanged:Connect(function(i)
if i.UserInputType~=Enum.UserInputType.MouseMovement then return end
if hDrag then SetH(i.Position.X) end
if svDrag then SetSV(i.Position.X,i.Position.Y) end
end))
Track(UIS.InputEnded:Connect(function(i)
if i.UserInputType==Enum.UserInputType.MouseButton1 then
hDrag=false;svDrag=false end
end))
end
-- ── WINDOW SIZE ────────────────────────────────────
SecLbl(SettingsP,"WINDOW SIZE")
do
local MIN_W,MAX_W,MIN_H,MAX_H = 420,1400,310,900
local card=Card(SettingsP,108)
N("TextLabel",{Size=UDim2.new(1,-24,0,18),Position=UDim2.new(0,12,0,8),
BackgroundTransparency=1,Text="Manual (min "..MIN_W.."×"..MIN_H.." max
"..MAX_W.."×"..MAX_H..")",
TextColor3=Config.Sub,Font=Enum.Font.Gotham,TextSize=10,
TextXAlignment=Enum.TextXAlignment.Left},card)
local function SBox(xOff,val)
local
tb=N("TextBox",{Size=UDim2.new(0,60,0,28),Position=UDim2.new(1,xOff,0,28),
BackgroundColor3=Color3.fromRGB(26,26,26),Text=tostring(val),
TextColor3=Config.Text,Font=Enum.Font.Gotham,TextSize=12,
BorderSizePixel=0,ClearTextOnFocus=false},card)
Cor(tb,6); N("UIPadding",{PaddingLeft=UDim.new(0,6)},tb); return tb
end
local wIn=SBox(-140,Config.Width)
N("TextLabel",{Size=UDim2.new(0,16,0,28),Position=UDim2.new(1,-78,0,28),
BackgroundTransparency=1,Text="×",TextColor3=Config.Sub,Font=Enum.Font.GothamBold,TextSize=14},card)
local h
