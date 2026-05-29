-- Dzielnica Combat System v4.0
-- loadstring(game:HttpGet('YOUR_RAW_LINK'))()

local R=loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local PL=game:GetService("Players")
local RS=game:GetService("ReplicatedStorage")
local RUN=game:GetService("RunService")
local TW=game:GetService("TweenService")
local UIS=game:GetService("UserInputService")

local lp=PL.LocalPlayer
local ch=lp.Character or lp.CharacterAdded:Wait()
local hum=ch:WaitForChild("Humanoid")
local root=ch:WaitForChild("HumanoidRootPart")
local rem=RS:WaitForChild("remotes"):WaitForChild("main")

-- CONFIG
local C={dmg=25,range=7,acd=0.6,pw=0.5,pcd=1.2,br=0.65,air=0.25,adr=22}
local S={bl=false,pr=false,at=false,cp=true,ca=true,ai=false,aim="Balanced",
         k=0,p=0,a=0,bk=0,dd=0,dt=0,esp=false}

-- FX
local function fx(pos,col,sz)
    local p=Instance.new("Part")
    p.Size=Vector3.new(sz,sz,sz);p.Position=pos;p.Anchored=true
    p.CanCollide=false;p.Material=Enum.Material.Neon
    p.BrickColor=BrickColor.new(col);p.Shape=Enum.PartType.Ball;p.Parent=workspace
    TW:Create(p,TweenInfo.new(.35,Enum.EasingStyle.Quad,Enum.EasingDirection.Out),
        {Size=Vector3.new(.05,.05,.05),Transparency=1}):Play()
    task.delay(.4,function()p:Destroy()end)
end

local function glow(col,t)
    local orig={}
    for _,p in pairs(ch:GetDescendants())do
        if p:IsA("BasePart")then orig[p]=p.BrickColor;p.BrickColor=BrickColor.new(col)end
    end
    task.delay(t,function()
        for p,o in pairs(orig)do if p and p.Parent then p.BrickColor=o end end
    end)
end

-- ENEMY
local function enemy()
    local best,bd=nil,C.adr
    for _,p in pairs(PL:GetPlayers())do
        if p~=lp and p.Character then
            local r=p.Character:FindFirstChild("HumanoidRootPart")
            local h=p.Character:FindFirstChild("Humanoid")
            if r and h and h.Health>0 then
                local d=(root.Position-r.Position).Magnitude
                if d<bd then bd=d;best=p.Character end
            end
        end
    end
    return best,bd
end

-- SEND (игра не принимает FireServer — только слушает OnClientEvent)
-- Атака через hitindicator уже обрабатывается сервером
local function send(...)
    pcall(function()rem:FireServer(...)end)
end

-- PARRY
local function parry()
    if not S.cp then
        R:Notify({Title="✨ Парри",Content="⏳ Кулдаун",Duration=.5,Image=4483362458})
        return
    end
    S.cp=false;S.pr=true;S.p+=1
    glow("Cyan",C.pw)
    fx(root.Position+Vector3.new(0,2,0),"Cyan",3.5)
    R:Notify({Title="✨ ПАРИРОВАНИЕ",Content="Окно: "..C.pw.."с",Duration=C.pw,Image=4483362458})
    task.delay(C.pw,function()S.pr=false end)
    task.delay(C.pcd,function()S.cp=true end)
end

-- ATTACK
local function attack(tgt)
    if not S.ca then return end
    S.ca=false;S.at=true;S.a+=1
    local t=tgt or enemy()
    if t then
        local tr=t:FindFirstChild("HumanoidRootPart")
        local th=t:FindFirstChildOfClass("Humanoid")
        if tr and th and th.Health>0 then
            local d=(root.Position-tr.Position).Magnitude
            if d<=C.range then
                th:TakeDamage(C.dmg);S.dd+=C.dmg
                if th.Health<=0 then S.k+=1 end
                fx(tr.Position,"Bright red",2)
                fx((root.Position+tr.Position)/2,"Bright orange",1)
                R:Notify({Title="⚔ Атака",Content="Урон: "..C.dmg.." → "..t.Name,Duration=.8,Image=4483362458})
            else
                R:Notify({Title="⚔",Content="Слишком далеко!",Duration=.6,Image=4483362458})
            end
        end
    end
    task.delay(C.acd,function()S.ca=true;S.at=false end)
end

-- BLOCK
local function blon()
    if S.bl then return end
    S.bl=true;glow("Medium blue",999)
    R:Notify({Title="🛡 Блок",Content="Урон -"..(C.br*100).."%",Duration=.5,Image=4483362458})
end
local function bloff()
    if not S.bl then return end
    S.bl=false
    for _,p in pairs(ch:GetDescendants())do
        if p:IsA("BasePart")then p.BrickColor=BrickColor.new("Medium stone grey")end
    end
end

-- COUNTER
local function counter()
    task.delay(.08,function()
        local t=enemy()
        if t then
            local th=t:FindFirstChildOfClass("Humanoid")
            local tr=t:FindFirstChild("HumanoidRootPart")
            if th and tr then
                local b=math.floor(C.dmg*1.6)
                th:TakeDamage(b);S.dd+=b
                fx(tr.Position,"Bright yellow",3)
                R:Notify({Title="💥 КОНТРАТАКА!",Content="Урон: "..b,Duration=1.2,Image=4483362458})
            end
        end
    end)
end

-- SERVER EVENTS
rem.OnClientEvent:Connect(function(ev,...)
    local a={...}
    if ev=="hurtcamera" then
        S.dt+=3
        fx(root.Position,"Bright red",1.5)
        if S.autoParry and S.cp then task.delay(.05,parry)end
    elseif ev=="playhitblocked" then
        S.bk+=1;fx(root.Position,"Medium blue",2);glow("Bright blue",.3)
    elseif ev=="highlightweapon" then
        if S.autoBlock and not S.bl then blon();task.delay(.5,bloff)end
        if S.autoParry and S.cp then task.delay(.1,parry)end
    elseif ev=="spawnarrow" then
        -- Стрела летит в нас — автопарирование
        if a[1] and type(a[1])=="table" then
            local d=a[1]
            if d.owner~=lp.Name then
                if S.autoParry and S.cp then task.delay(.05,parry)end
            end
        end
    elseif ev=="throwmodel" then
        if S.autoParry and S.cp then task.delay(.03,parry)end
    elseif ev=="eqCR" then
        R:Notify({Title="🗡 Оружие",Content=(a[1]or"?").." Ур."..(a[2]or"?"),Duration=1.5,Image=4483362458})
    end
end)

-- DAMAGE HANDLER
hum.HealthChanged:Connect(function(hp)
    local d=hum.Health-hp
    if d<=0 then return end
    if S.pr then
        task.defer(function()hum.Health=math.min(hum.MaxHealth,hum.Health+d)end)
        glow("Lime green",.5);fx(root.Position,"Lime green",4)
        R:Notify({Title="✨ Парировано!",Content="+"..math.floor(d).." HP",Duration=1.2,Image=4483362458})
        counter()
    elseif S.bl then
        task.defer(function()hum.Health=math.min(hum.MaxHealth,hum.Health+d*C.br)end)
        R:Notify({Title="🛡 Заблок.",Content="-"..math.floor(d*C.br).." HP снижено",Duration=.6,Image=4483362458})
    end
end)

-- AI
local tick2=0
RUN.Heartbeat:Connect(function(dt)
    if not S.ai then return end
    if humanoid and hum.Health<=0 then return end
    tick2+=dt;if tick2<.1 then return end;tick2=0
    local t,d=enemy()
    if not t then return end
    local hp=hum.Health/hum.MaxHealth
    if S.aim=="Aggressive" then
        if d<=C.range and S.ca then task.delay(C.air,function()attack(t)end)end
    elseif S.aim=="Defensive" then
        if not S.bl then blon()end
        if d<=C.range and S.cp then bloff();task.delay(C.air,parry)end
    elseif S.aim=="Balanced" then
        if hp>.65 then
            if d<=C.range and S.ca then task.delay(C.air,function()attack(t)end)end
        elseif hp>.35 then
            if d<=C.range then
                if S.cp and math.random()>.45 then task.delay(C.air,parry)
                elseif S.ca then task.delay(C.air,function()attack(t)end)end
            end
        else
            if not S.bl then blon()end
            if S.cp then task.delay(C.air,parry)end
        end
    elseif S.aim=="Berserker" then
        if d<=C.range and S.ca then task.delay(C.air*.4,function()attack(t)end)end
        if S.cp and math.random()>.65 then task.delay(C.air,parry)end
    elseif S.aim=="Ghost" then
        if d<=C.range and S.cp then task.delay(C.air,parry)end
    end
end)

-- ESP
local espC={}
local function updateESP()
    for _,c in pairs(espC)do pcall(function()c:Disconnect()end)end
    espC={}
    for _,p in pairs(PL:GetPlayers())do
        if p~=lp and p.Character then
            local r2=p.Character:FindFirstChild("HumanoidRootPart")
            local h2=p.Character:FindFirstChildOfClass("Humanoid")
            if r2 and h2 then
                local old=r2:FindFirstChild("_ESP")
                if old then old:Destroy()end
                if not S.esp then continue end
                local bb=Instance.new("BillboardGui")
                bb.Name="_ESP";bb.Size=UDim2.new(0,120,0,45)
                bb.StudsOffset=Vector3.new(0,3,0);bb.AlwaysOnTop=true;bb.Parent=r2
                local lb=Instance.new("TextLabel")
                lb.Size=UDim2.new(1,0,1,0);lb.BackgroundTransparency=1
                lb.TextColor3=Color3.fromRGB(255,50,50);lb.TextScaled=true
                lb.Font=Enum.Font.GothamBold;lb.Parent=bb
                local co=RUN.Heartbeat:Connect(function()
                    if not bb.Parent then return end
                    local ds=math.floor((root.Position-r2.Position).Magnitude)
                    lb.Text=p.Name.."\n❤"..math.floor(h2.Health).."|"..ds.."ст"
                    lb.TextColor3=h2.Health>60 and Color3.fromRGB(50,255,50)
                        or h2.Health>30 and Color3.fromRGB(255,200,0)
                        or Color3.fromRGB(255,50,50)
                end)
                table.insert(espC,co)
            end
        end
    end
end

-- KEYS
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.KeyCode==Enum.KeyCode.Q then parry()
    elseif i.KeyCode==Enum.KeyCode.E then attack()
    elseif i.KeyCode==Enum.KeyCode.R then blon()end
end)
UIS.InputEnded:Connect(function(i)
    if i.KeyCode==Enum.KeyCode.R then bloff()end
end)

-- GUI
local W=R:CreateWindow({
    Name="⚔ Dzielnica v4",LoadingTitle="Combat System",
    LoadingSubtitle="v4.0 | Dzielnica",Theme="Default",
    ConfigurationSaving={Enabled=true,FolderName="DzielnicaCombat",FileName="cfg"},
    KeySystem=false,
})

local T1=W:CreateTab("⚔ Бой",4483362458)
local T2=W:CreateTab("🤖 ИИ",4483362458)
local T3=W:CreateTab("🔮 Авто",4483362458)
local T4=W:CreateTab("📊 Стат",4483362458)
local T5=W:CreateTab("⚙ Настр",4483362458)

-- БОЙ
T1:CreateSection("Управление")
T1:CreateButton({Name="✨ Парировать [Q]",Callback=parry})
T1:CreateButton({Name="⚔ Атаковать [E]",Callback=attack})
T1:CreateButton({Name="🛡 Блок вкл [R]",Callback=blon})
T1:CreateButton({Name="🛡 Блок выкл",Callback=bloff})
T1:CreateSection("Инфо")
T1:CreateLabel("Q=Парри | E=Атака | R зажать=Блок")
T1:CreateLabel("Парри → Контратака ×1.6 урона")
T1:CreateLabel("Блок → Снижение урона на 65%")
T1:CreateLabel("Авто-парри → реакция на стрелы/броски")

-- ИИ
T2:CreateSection("Авто-бой")
T2:CreateToggle({Name="🤖 ИИ",CurrentValue=false,Flag="AI",
    Callback=function(v)S.ai=v
        R:Notify({Title=v and"🤖 ИИ вкл"or"👤 Ручной",Content=v and S.aim or"",Duration=2,Image=4483362458})
    end})
T2:CreateDropdown({Name="Режим",Options={"Balanced","Aggressive","Defensive","Berserker","Ghost"},
    CurrentOption={"Balanced"},Flag="AIM",
    Callback=function(o)S.aim=o[1]
        R:Notify({Title="Режим: "..o[1],Content="",Duration=1,Image=4483362458})
    end})
T2:CreateSection("Режимы")
T2:CreateLabel("Balanced  — атака/защита по HP")
T2:CreateLabel("Aggressive — только атаковать")
T2:CreateLabel("Defensive  — блок + парри")
T2:CreateLabel("Berserker  — атаки ×2 скорость")
T2:CreateLabel("Ghost      — только парировать")

-- АВТО
T3:CreateSection("Авто-реакции")
T3:CreateToggle({Name="✨ Авто-парри",CurrentValue=false,Flag="AP",
    Callback=function(v)S.autoParry=v
        R:Notify({Title="Авто-парри",Content=v and"Вкл"or"Выкл",Duration=1,Image=4483362458})
    end})
T3:CreateToggle({Name="🛡 Авто-блок",CurrentValue=false,Flag="AB",
    Callback=function(v)S.autoBlock=v
        R:Notify({Title="Авто-блок",Content=v and"Вкл"or"Выкл",Duration=1,Image=4483362458})
    end})
T3:CreateToggle({Name="👁 ESP",CurrentValue=false,Flag="ESP",
    Callback=function(v)S.esp=v;updateESP()
        R:Notify({Title="ESP",Content=v and"Вкл"or"Выкл",Duration=1,Image=4483362458})
    end})
T3:CreateButton({Name="🔄 Обновить ESP",Callback=updateESP})

-- СТАТИСТИКА
T4:CreateSection("Сессия")
local lK=T4:CreateLabel("🗡 Убийств: 0")
local lP=T4:CreateLabel("✨ Парирований: 0")
local lA=T4:CreateLabel("⚔ Атак: 0")
local lB=T4:CreateLabel("🛡 Заблокировано: 0")
local lD=T4:CreateLabel("💥 Урона нанесено: 0")
local lT=T4:CreateLabel("❤ Урона получено: 0")
T4:CreateButton({Name="🔄 Обновить",Callback=function()
    lK:Set("🗡 Убийств: "..S.k);lP:Set("✨ Парирований: "..S.p)
    lA:Set("⚔ Атак: "..S.a);lB:Set("🛡 Заблок.: "..S.bk)
    lD:Set("💥 Нанесено: "..S.dd);lT:Set("❤ Получено: "..S.dt)
end})
T4:CreateButton({Name="🗑 Сбросить",Callback=function()
    S.k=0;S.p=0;S.a=0;S.bk=0;S.dd=0;S.dt=0
    lK:Set("🗡 0");lP:Set("✨ 0");lA:Set("⚔ 0")
    lB:Set("🛡 0");lD:Set("💥 0");lT:Set("❤ 0")
end})
task.spawn(function()
    while task.wait(2)do
        lK:Set("🗡 Убийств: "..S.k);lP:Set("✨ Парирований: "..S.p)
        lA:Set("⚔ Атак: "..S.a);lB:Set("🛡 Заблок.: "..S.bk)
        lD:Set("💥 Нанесено: "..S.dd);lT:Set("❤ Получено: "..S.dt)
    end
end)

-- НАСТРОЙКИ
T5:CreateSection("Параметры")
T5:CreateSlider({Name="⚔ Урон",Range={5,100},Increment=5,Suffix="HP",
    CurrentValue=C.dmg,Flag="DMG",Callback=function(v)C.dmg=v end})
T5:CreateSlider({Name="📏 Дальность",Range={3,20},Increment=1,Suffix="ст",
    CurrentValue=C.range,Flag="RNG",Callback=function(v)C.range=v end})
T5:CreateSlider({Name="⏱ Кулдаун атаки",Range={2,20},Increment=1,Suffix="×0.1с",
    CurrentValue=C.acd*10,Flag="ACD",Callback=function(v)C.acd=v/10 end})
T5:CreateSlider({Name="✨ Окно парри",Range={2,15},Increment=1,Suffix="×0.1с",
    CurrentValue=C.pw*10,Flag="PW",Callback=function(v)C.pw=v/10 end})
T5:CreateSlider({Name="👁 Дальность ИИ",Range={5,50},Increment=5,Suffix="ст",
    CurrentValue=C.adr,Flag="ADR",Callback=function(v)C.adr=v end})
T5:CreateSlider({Name="⚡ Реакция ИИ",Range={1,10},Increment=1,Suffix="×0.05с",
    CurrentValue=C.air*20,Flag="AIR",Callback=function(v)C.air=v/20 end})

R:Notify({Title="✅ Dzielnica v4.0",Content="Q=Парри|E=Атака|R=Блок",Duration=5,Image=4483362458})
warn("[Dzielnica v4.0] Загружен!")
