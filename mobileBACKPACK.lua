do local ok,e=pcall(getgenv) if ok and type(e)=="table" then if e.BPX then return end e.BPX=true end end
if not game:IsLoaded() then game.Loaded:Wait() end

local function sgs(n) local gs=game.GetService local cr=rawget(getfenv(0) or {},"cloneref") local s=gs(game,n) return (cr and cr(s)) or s end
local Plr=sgs("Players").LocalPlayer
local TS=sgs("TweenService")
local UIS=sgs("UserInputService")
local SG=sgs("StarterGui")
local WS=sgs("Workspace")
local TSvc=sgs("TextService")
pcall(function() SG:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack,false) end)

local mob=UIS.TouchEnabled
local sw=false local swSel=nil local sel=nil local col=false local exp=false
local need=false local tBtns={} local tOrder={} local qtxt="" local strokes={}
local dropCnt=0 local toolCnt=0

local Thm={bg=Color3.fromRGB(14,14,16),soft=Color3.fromRGB(26,26,30),acc=Color3.fromRGB(45,120,255),acc2=Color3.fromRGB(0,185,95),dng=Color3.fromRGB(205,60,60),txt=Color3.fromRGB(255,255,255),mtx=Color3.fromRGB(210,210,210),str=Color3.fromRGB(60,60,62),hot=Color3.fromRGB(42,42,46),yel=Color3.fromRGB(255,225,90),lk=Color3.fromRGB(150,150,150)}

local qbW= mob and 520 or 600
local cell= mob and 46 or 50
local pad = mob and 4 or 5
local bW  = mob and 46 or 52
local bH  = mob and 40 or 44

local function root() local ok,r=pcall(function() return gethui and gethui() end) if ok and typeof(r)=="Instance" then return r end local cg=sgs("CoreGui") return cg:FindFirstChild("RobloxGui") or cg or Plr:FindFirstChildOfClass("PlayerGui") end
local function tw(i,t,p,e,d) TS:Create(i, TweenInfo.new(t or .18,e or Enum.EasingStyle.Quad,d or Enum.EasingDirection.Out), p):Play() end
local function stroke(i,th) local s=Instance.new("UIStroke") s.Color=Thm.str s.Thickness=th or 1 s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border s.Parent=i table.insert(strokes,s) return s end
local function corner(i,r) local c=Instance.new("UICorner") c.CornerRadius=UDim.new(0,r or 10) c.Parent=i return c end
local function attr(g,n,v) pcall(function() g:SetAttribute(n,v) end) end
local function getattr(g,n,d) local ok,v=pcall(function() return g:GetAttribute(n) end) if ok and v~=nil then return v end return d end
local function hum() return Plr.Character and Plr.Character:FindFirstChildOfClass("Humanoid") end
local function canDrop(t) return t:IsA("Tool") and t.CanBeDropped and not getattr(t,"BP_Lock",false) end
local function dropOne(t) local c=Plr.Character if not c then return end if t.Parent==c then t.Parent=WS else t.Parent=c task.wait() t.Parent=WS end end

local ui=Instance.new("ScreenGui") ui.Name="BPX" ui.IgnoreGuiInset=true ui.DisplayOrder=9e8 ui.ResetOnSpawn=false ui.ZIndexBehavior=Enum.ZIndexBehavior.Global ui.Parent=root()

local bar=Instance.new("Frame") bar.Name="Bar" bar.AnchorPoint=Vector2.new(.5,1) bar.Position=UDim2.new(.5,0,1,-(mob and 6 or 10)) bar.Size=UDim2.new(0,qbW+(mob and 220 or 260),0,(mob and 56 or 64)) bar.BackgroundTransparency=1 bar.Parent=ui
local qb=Instance.new("Frame") qb.Name="QB" qb.Size=UDim2.new(0,qbW,0,(mob and 54 or 60)) qb.Position=UDim2.new(.5,-qbW/2,0,(mob and 1 or 2)) qb.BackgroundColor3=Thm.soft qb.BackgroundTransparency=.25 qb.ClipsDescendants=true qb.Parent=bar corner(qb,12) stroke(qb,1)
local ql=Instance.new("UIGridLayout") ql.FillDirection=Enum.FillDirection.Horizontal ql.CellSize=UDim2.new(0,cell,0,cell) ql.CellPadding=UDim2.new(0,pad,0,pad) ql.HorizontalAlignment=Enum.HorizontalAlignment.Center ql.VerticalAlignment=Enum.VerticalAlignment.Center ql.SortOrder=Enum.SortOrder.LayoutOrder ql.Parent=qb

local ex=Instance.new("TextButton") ex.Name="Ex" ex.AnchorPoint=Vector2.new(.5,.5) ex.Size=UDim2.new(0,(mob and 40 or 44),0,(mob and 40 or 44)) ex.Position=UDim2.new(.5,-qbW/2-(mob and 30 or 38),.5,(mob and 1 or 2)) ex.Text="Open" ex.Font=Enum.Font.GothamBold ex.TextScaled=true ex.BackgroundColor3=Thm.hot ex.BackgroundTransparency=.2 ex.TextColor3=Thm.txt ex.Parent=bar corner(ex,10) stroke(ex,1)

local rDock=Instance.new("Frame") rDock.Name="RD" rDock.AnchorPoint=Vector2.new(0,.5)
rDock.Size=UDim2.new(0, bW*3 + (mob and 8 or 8)*2 ,0,bH)
rDock.Position=UDim2.new(.5, qbW/2 - rDock.Size.X.Offset - (mob and 6 or -14), .5, (mob and 1 or 2))
rDock.BackgroundTransparency=1 rDock.Parent=bar
local rList=Instance.new("UIListLayout") rList.FillDirection=Enum.FillDirection.Horizontal rList.HorizontalAlignment=Enum.HorizontalAlignment.Left rList.VerticalAlignment=Enum.VerticalAlignment.Center rList.Padding=UDim.new(0,(mob and 8 or 8)) rList.Parent=rDock

local swBtn=Instance.new("TextButton") swBtn.Size=UDim2.new(0,bW,0,bH) swBtn.Text="Swap" swBtn.Font=Enum.Font.GothamBold swBtn.TextScaled=true swBtn.BackgroundColor3=Thm.soft swBtn.BackgroundTransparency=.1 swBtn.TextColor3=Thm.txt swBtn.Visible=false swBtn.Parent=rDock corner(swBtn,10) stroke(swBtn,1)
local drpBtn=Instance.new("TextButton") drpBtn.Size=UDim2.new(0,bW,0,bH) drpBtn.Text="Drop(0)" drpBtn.Font=Enum.Font.GothamBold drpBtn.TextScaled=true drpBtn.BackgroundColor3=Thm.dng drpBtn.BackgroundTransparency=.5 drpBtn.TextTransparency=.4 drpBtn.TextColor3=Thm.txt drpBtn.Active=false drpBtn.AutoButtonColor=false drpBtn.Parent=rDock corner(drpBtn,10) stroke(drpBtn,1)
local colBtn=Instance.new("TextButton") colBtn.Size=UDim2.new(0,bW,0,bH) colBtn.Text="-" colBtn.Font=Enum.Font.GothamBold colBtn.TextScaled=true colBtn.BackgroundColor3=Thm.soft colBtn.BackgroundTransparency=.1 colBtn.TextColor3=Thm.txt colBtn.Parent=rDock corner(colBtn,10) stroke(colBtn,1)

local expFr=Instance.new("Frame") expFr.Name="Exp" expFr.Size=UDim2.new(0,qbW,0,0) expFr.AnchorPoint=Vector2.new(.5,1) expFr.Position=UDim2.new(.5,0,1,-(mob and 60 or 74)) expFr.BackgroundColor3=Thm.bg expFr.BackgroundTransparency=.2 expFr.BorderSizePixel=0 expFr.Visible=true expFr.ClipsDescendants=true expFr.Parent=ui corner(expFr,12) stroke(expFr,1)
local hdr=Instance.new("Frame") hdr.Size=UDim2.new(1,-10,0,(mob and 34 or 40)) hdr.Position=UDim2.new(0,5,0,5) hdr.BackgroundColor3=Thm.soft hdr.BackgroundTransparency=.2 hdr.Parent=expFr corner(hdr,8) stroke(hdr,1)
local srch=Instance.new("TextBox") srch.Size=UDim2.new(1,-10,1,0) srch.Position=UDim2.new(0,5,0,0) srch.ClearTextOnFocus=false srch.PlaceholderText="Search" srch.Text="" srch.Font=Enum.Font.Gotham srch.TextSize=(mob and 13 or 14) srch.TextColor3=Thm.txt srch.PlaceholderColor3=Thm.mtx srch.BackgroundTransparency=1 srch.TextXAlignment=Enum.TextXAlignment.Left srch.Parent=hdr
local scr=Instance.new("ScrollingFrame") scr.Size=UDim2.new(1,-10,1,-((mob and 38 or 50))) scr.Position=UDim2.new(0,5,0,(mob and 40 or 45)) scr.CanvasSize=UDim2.new(0,0,0,0) scr.ScrollBarThickness=4 scr.ScrollingDirection=Enum.ScrollingDirection.Y scr.BackgroundTransparency=1 scr.Parent=expFr
local gl=Instance.new("UIGridLayout") gl.CellSize=UDim2.new(0,cell,0,cell) gl.CellPadding=UDim2.new(0,pad,0,pad) gl.SortOrder=Enum.SortOrder.LayoutOrder gl.Parent=scr

local cfm=Instance.new("Frame") cfm.Name="Cfm" cfm.Size=UDim2.new(0,300,0,78) cfm.BackgroundColor3=Thm.soft cfm.BackgroundTransparency=1 cfm.Visible=false cfm.ZIndex=60 cfm.Parent=ui corner(cfm,10) stroke(cfm,1)
local cScale=Instance.new("UIScale") cScale.Scale=.95 cScale.Parent=cfm
local cfmT=Instance.new("TextLabel") cfmT.BackgroundTransparency=1 cfmT.Size=UDim2.new(1,-140,1,-18) cfmT.Position=UDim2.new(0,12,0,9) cfmT.Font=Enum.Font.GothamSemibold cfmT.TextSize=14 cfmT.TextColor3=Thm.txt cfmT.TextWrapped=true cfmT.TextTransparency=1 cfmT.Text="Drop all unlocked tools?" cfmT.ZIndex=61 cfmT.Parent=cfm
local cYes=Instance.new("TextButton") cYes.Size=UDim2.new(0,56,0,36) cYes.Position=UDim2.new(1,-124,.5,-18) cYes.Text="Yes" cYes.Font=Enum.Font.GothamBold cYes.TextScaled=true cYes.BackgroundColor3=Thm.dng cYes.TextColor3=Thm.txt cYes.TextTransparency=1 cYes.ZIndex=61 cYes.Parent=cfm corner(cYes,8) stroke(cYes,1)
local cNo=Instance.new("TextButton") cNo.Size=UDim2.new(0,56,0,36) cNo.Position=UDim2.new(1,-62,.5,-18) cNo.Text="No" cNo.Font=Enum.Font.GothamBold cNo.TextScaled=true cNo.BackgroundColor3=Thm.soft cNo.TextColor3=Thm.txt cNo.TextTransparency=1 cNo.ZIndex=61 cNo.Parent=cfm corner(cNo,8) stroke(cNo,1)

local tip=Instance.new("Frame") tip.Name="Tip" tip.BackgroundColor3=Thm.soft tip.BackgroundTransparency=.05 tip.Visible=false tip.ZIndex=500 tip.Parent=ui corner(tip,8) stroke(tip,1)
local tipT=Instance.new("TextLabel") tipT.BackgroundTransparency=1 tipT.Size=UDim2.new(1,-14,1,-8) tipT.Position=UDim2.new(0,7,0,4) tipT.Font=Enum.Font.GothamSemibold tipT.TextScaled=true tipT.TextColor3=Color3.new(1,1,1) tipT.TextStrokeTransparency=0 tipT.TextStrokeColor3=Color3.new(0,0,0) tipT.Text="" tipT.ZIndex=501 tipT.Parent=tip local tipMax=Instance.new("UITextSizeConstraint") tipMax.MaxTextSize=18 tipMax.MinTextSize=10 tipMax.Parent=tipT

local mTop=Instance.new("Frame") mTop.Name="MTop" mTop.AnchorPoint=Vector2.new(.5,0) mTop.Size=UDim2.new(0, mob and 170 or 0, 0, mob and 36 or 0) mTop.Position=UDim2.new(.5,0,0,(mob and 8 or 0)) mTop.BackgroundColor3=Thm.soft mTop.BackgroundTransparency=.1 mTop.Visible=false mTop.ZIndex=400 mTop.Parent=ui corner(mTop,10) stroke(mTop,1)
local mList=Instance.new("UIListLayout") mList.FillDirection=Enum.FillDirection.Horizontal mList.HorizontalAlignment=Enum.HorizontalAlignment.Center mList.VerticalAlignment=Enum.VerticalAlignment.Center mList.Padding=UDim.new(0,8) mList.Parent=mTop
local function mBtn(txt,col) local b=Instance.new("TextButton") b.Size=UDim2.new(0,50,0,30) b.Text=txt b.TextScaled=true b.Font=Enum.Font.GothamBold b.BackgroundColor3=col or Thm.soft b.TextColor3=Thm.txt b.Parent=mTop corner(b,8) stroke(b,1) return b end
local mFav=mBtn("★") local mLock=mBtn("🔓") local mDrop=mBtn("D",Thm.dng)

local function setStrokeOn(on) for _,s in ipairs(strokes) do if s and s.Parent then s.Transparency=on and 0 or 1 end end end
local function keyChip(btn,txt) if mob or not txt then return end local old=btn:FindFirstChild("Key") if old then old:Destroy() end local f=Instance.new("Frame") f.Name="Key" f.Size=UDim2.new(0,20,0,20) f.Position=UDim2.new(0,3,0,3) f.BackgroundColor3=Thm.bg f.BackgroundTransparency=.1 f.ZIndex=btn.ZIndex+2 f.Parent=btn corner(f,5) stroke(f,1) local t=Instance.new("TextLabel") t.BackgroundTransparency=1 t.Size=UDim2.new(1,0,1,0) t.Font=Enum.Font.GothamBold t.TextScaled=true t.TextColor3=Thm.txt t.Text=txt t.ZIndex=f.ZIndex+1 t.Parent=f local ts=Instance.new("UITextSizeConstraint") ts.MaxTextSize=14 ts.MinTextSize=10 ts.Parent=t return f end
if not mob then keyChip(ex,"`") keyChip(drpBtn,"E") keyChip(colBtn,"C") end

local function cntDrop() local n=0 for _,cont in ipairs({Plr.Backpack,Plr.Character}) do if cont then for _,t in ipairs(cont:GetChildren()) do if canDrop(t) then n+=1 end end end end return n end
local function posCfm() local v=workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920,1080) local rx=rDock.AbsolutePosition.X+rDock.AbsoluteSize.X+10 local y=bar.AbsolutePosition.Y-(mob and 88 or 96) if rx+cfm.AbsoluteSize.X>v.X then cfm.Position=UDim2.new(0,rDock.AbsolutePosition.X-10-cfm.AbsoluteSize.X,0,y) else cfm.Position=UDim2.new(0,rx,0,y) end end
local function showCfm() dropCnt=cntDrop() if dropCnt<=0 then return end posCfm() cfm.Visible=true cfm.BackgroundTransparency=1 cScale.Scale=.95 cfmT.TextTransparency=1 cYes.TextTransparency=1 cNo.TextTransparency=1 tw(cfm,.16,{BackgroundTransparency=.1}) tw(cScale,.16,{Scale=1},Enum.EasingStyle.Back) tw(cfmT,.16,{TextTransparency=0}) tw(cYes,.16,{TextTransparency=0}) tw(cNo,.16,{TextTransparency=0}) end
local function hideCfm() if not cfm.Visible then return end tw(cfm,.12,{BackgroundTransparency=1}) tw(cScale,.12,{Scale=.95}) tw(cfmT,.12,{TextTransparency=1}) tw(cYes,.12,{TextTransparency=1}) tw(cNo,.12,{TextTransparency=1}) task.delay(.12,function() cfm.Visible=false end) end
local function layout() qb.Position=UDim2.new(.5,-qbW/2,0,(mob and 1 or 2)) ex.Position=UDim2.new(.5,-qbW/2-(mob and 30 or 38),.5,(mob and 1 or 2)) rDock.Position=UDim2.new(.5, qbW/2 - rDock.Size.X.Offset - (mob and 6 or -14), .5, (mob and 1 or 2)) expFr.Position=UDim2.new(.5,0,1,-(mob and 60 or 74)) end

local function tipForBtn(b,name)
	if mob then return end
	local padX=16 local h=26
	local sz=TSvc:GetTextSize(name,18,Enum.Font.GothamSemibold,Vector2.new(500,36))
	local w=math.clamp(sz.X+padX,80,260)
	tip.Size=UDim2.fromOffset(w,h) tipT.Text=name
	local bp=b.AbsolutePosition local bs=b.AbsoluteSize
	tip.Position=UDim2.fromOffset(bp.X+(bs.X-w)/2, bp.Y - h - 2)
	tip.Visible=true
end

local function orderedQBButtons()
	local arr={} for _,ch in ipairs(qb:GetChildren()) do if ch:IsA("GuiButton") then table.insert(arr,ch) end end
	table.sort(arr,function(a,b) return (a.LayoutOrder or 0) < (b.LayoutOrder or 0) end) return arr
end

local function updMobileTop()
	if not mob then mTop.Visible=false return end
	local t=sel
	if t and t:IsA("Tool") then
		mTop.Visible=true
		mFav.TextColor3 = getattr(t,"BP_Fav",false) and Thm.yel or Thm.txt
		mLock.Text = getattr(t,"BP_Lock",false) and "🔒" or "🔓"
		local ok=canDrop(t)
		mDrop.AutoButtonColor=ok mDrop.Active=ok mDrop.TextTransparency=ok and 0 or .4 mDrop.BackgroundTransparency=ok and .05 or .5
	else
		mTop.Visible=false
	end
end

local function equip(t)
	local h=hum() if not h then return end
	h:UnequipTools()
	if sel~=t then h:EquipTool(t) sel=t else sel=nil end
	updMobileTop()
end

local function opsBar(b,t)
	if mob then return end
	local ops=Instance.new("Frame") ops.Name="Ops" ops.Size=UDim2.new(1,0,0,16) ops.Position=UDim2.new(0,0,1,-16) ops.BackgroundColor3=Thm.bg ops.BackgroundTransparency=.35 ops.Visible=false ops.ZIndex=7 ops.Parent=b
	local ol=Instance.new("UIListLayout") ol.FillDirection=Enum.FillDirection.Horizontal ol.HorizontalAlignment=Enum.HorizontalAlignment.Center ol.VerticalAlignment=Enum.VerticalAlignment.Center ol.Padding=UDim.new(0,6) ol.Parent=ops
	local function mini(txt) local x=Instance.new("TextButton") x.Size=UDim2.new(0,18,0,12) x.Text=txt x.Font=Enum.Font.GothamBold x.TextScaled=true x.BackgroundColor3=Thm.soft x.BackgroundTransparency=.1 x.TextColor3=Thm.txt x.BorderSizePixel=0 x.ZIndex=8 x.Parent=ops corner(x,4) return x end
	local fav=mini("★") local lock=mini(getattr(t,"BP_Lock",false) and "🔒" or "🔓") local drop=nil if t.CanBeDropped then drop=mini("D") end
	fav.TextColor3=getattr(t,"BP_Fav",false) and Thm.yel or Thm.txt
	fav.MouseButton1Click:Connect(function() local nv=not getattr(t,"BP_Fav",false) attr(t,"BP_Fav",nv) fav.TextColor3=nv and Thm.yel or Thm.txt need=false rebuild() end)
	lock.MouseButton1Click:Connect(function() local nv=not getattr(t,"BP_Lock",false) attr(t,"BP_Lock",nv) lock.Text=nv and "🔒" or "🔓" need=false rebuild() end)
	if drop then drop.MouseButton1Click:Connect(function() if canDrop(t) then dropOne(t) need=false rebuild() end end) end
	b.MouseEnter:Connect(function() ops.Visible=true end)
	b.MouseLeave:Connect(function() ops.Visible=false tip.Visible=false end)
	b.MouseButton1Down:Connect(function() ops.Visible=true end)
end

mFav.MouseButton1Click:Connect(function()
	if not sel or not sel:IsA("Tool") then return end
	attr(sel,"BP_Fav", not getattr(sel,"BP_Fav",false))
	rebuild()
end)
mLock.MouseButton1Click:Connect(function()
	if not sel or not sel:IsA("Tool") then return end
	attr(sel,"BP_Lock", not getattr(sel,"BP_Lock",false))
	rebuild()
end)
mDrop.MouseButton1Click:Connect(function()
	if not sel or not sel:IsA("Tool") then return end
	if canDrop(sel) then dropOne(sel) sel=nil rebuild() end
end)

function rebuild()
	for _,c in ipairs(qb:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
	for _,c in ipairs(scr:GetChildren()) do if c:IsA("GuiButton") then c:Destroy() end end
	table.clear(tBtns)

	local bp=Plr:FindFirstChild("Backpack")
	local map={}
	for _,cont in ipairs({bp,Plr.Character}) do if cont then for _,t in ipairs(cont:GetChildren()) do if t:IsA("Tool") then map[t]=true end end end end
	toolCnt=0 for _ in pairs(map) do toolCnt+=1 end

	for t in pairs(map) do if not table.find(tOrder,t) then table.insert(tOrder,t) end end
	for i=#tOrder,1,-1 do if not map[tOrder[i]] then table.remove(tOrder,i) end end

	sel=Plr.Character and Plr.Character:FindFirstChildOfClass("Tool") or sel

	local list={} local idxMap={} for i,v in ipairs(tOrder) do idxMap[v]=i end
	local q=qtxt local qlwr=(q~="") and string.lower(q) or nil
	for _,t in ipairs(tOrder) do if map[t] then if not qlwr or string.find(string.lower(t.Name),qlwr,1,true) then table.insert(list,t) end end end

	table.sort(list,function(a,b)
		local fa = getattr(a,"BP_Fav",false) and 0 or 1
		local fb = getattr(b,"BP_Fav",false) and 0 or 1
		if fa~=fb then return fa<fb end
		return (idxMap[a] or 1e9) < (idxMap[b] or 1e9)
	end)

	local function mkBtn(t,i)
		local has=t.TextureId and t.TextureId~=""
		local b=has and Instance.new("ImageButton") or Instance.new("TextButton")
		if has then b.Image=t.TextureId else b.Text=t.Name b.TextScaled=true b.TextColor3=Thm.txt end
		b.Name=t.Name b.Size=UDim2.new(0,cell,0,cell) b.AutoButtonColor=false
		b.BackgroundColor3= sw and ((swSel==t) and Thm.acc2 or Thm.hot) or ((sel==t) and Thm.acc or Thm.hot)
		local cr=Instance.new("UICorner") cr.CornerRadius=UDim.new(0,.2) cr.Parent=b
		local bs=stroke(b,2) bs.Color=getattr(t,"BP_Fav",false) and Thm.yel or Thm.str
		local lk=Instance.new("Frame") lk.Size=UDim2.new(1,0,0,2) lk.BackgroundColor3=getattr(t,"BP_Lock",false) and Thm.lk or Color3.fromRGB(0,0,0) lk.BackgroundTransparency=getattr(t,"BP_Lock",false) and .15 or 1 lk.BorderSizePixel=0 lk.ZIndex=6 lk.Parent=b
		tBtns[b]=t
		if not mob and i<=10 then keyChip(b, i==10 and "0" or tostring(i)) end
		opsBar(b,t)
		if not mob then
			b.MouseEnter:Connect(function() tipForBtn(b,t.Name) end)
			b.MouseLeave:Connect(function() tip.Visible=false end)
			b.MouseButton1Down:Connect(function() tipForBtn(b,t.Name) end)
			b.MouseButton1Up:Connect(function() tip.Visible=false end)
		end
		b.MouseButton1Click:Connect(function()
			if sw then
				if not swSel then swSel=t rebuild() return end
				if swSel==t then swSel=nil rebuild() return end
				local i1,i2 for k,v in ipairs(tOrder) do if v==swSel then i1=k end if v==t then i2=k end end
				if i1 and i2 then tOrder[i1],tOrder[i2]=tOrder[i2],tOrder[i1] end
				swSel=nil rebuild()
			else
				equip(t) rebuild()
			end
		end)
		return b
	end

	for i,t in ipairs(list) do
		local b=mkBtn(t,i)
		b.LayoutOrder=i
		if i<=10 then b.Parent=qb else b.Parent=scr end
	end

	local extra=math.max(#list-10,0) local rows=math.ceil(extra/10)
	scr.CanvasSize=UDim2.new(0,0,0,rows*(cell+pad))

	dropCnt=cntDrop()
	drpBtn.AutoButtonColor=dropCnt>0 drpBtn.Active=dropCnt>0
	drpBtn.TextTransparency=dropCnt>0 and 0 or .4 drpBtn.BackgroundTransparency=dropCnt>0 and .05 or .5
	drpBtn.Text="Drop("..tostring(dropCnt)..")"

	swBtn.Visible=(toolCnt>=2) and not col and bar.Visible
	if not mob and swBtn.Visible then keyChip(swBtn,"Q") end
	if not swBtn.Visible then sw=false swSel=nil end
	swBtn.Text=sw and "X" or "Swap"

	if col then bar.Visible=false exp=false expFr.Visible=false setStrokeOn(false)
	else bar.Visible=true expFr.Visible=true setStrokeOn(true) end

	local h=exp and (mob and 220 or 260) or 0
	tw(expFr,.16,{Size=UDim2.new(0,qbW,0,h)})
	ex.Text=exp and "Close" or "Open"

	updMobileTop()
	layout()
end

local function req() if need then return end need=true task.defer(function() task.wait(.02) need=false rebuild() end) end
local function setSwap() if toolCnt<2 then return end sw=not sw swSel=nil swBtn.Text=sw and "X" or "Swap" tw(swBtn,.12,{BackgroundColor3=sw and Thm.acc2 or Thm.soft}) req() end
local function slideBar(show) if show then bar.Position=UDim2.new(.5,0,1,-(mob and -40 or -64)) bar.Visible=true tw(bar,.2,{Position=UDim2.new(.5,0,1,-(mob and 6 or 10))}) else tw(bar,.16,{Position=UDim2.new(.5,0,1,-(mob and -40 or -64))}) task.delay(.16,function() if col then bar.Visible=false end end) end end
local function toggleCol() col=not col if col then hideCfm() slideBar(false) exp=false setStrokeOn(false) else setStrokeOn(true) slideBar(true) end req() end
local function toggleExp() if col then return end exp=not exp local sc=qb:FindFirstChildOfClass("UIScale") or Instance.new("UIScale",qb) sc.Scale=exp and .95 or 1.05 tw(sc,.16,{Scale=1}) req() end

local running=false
local function doDropAll() dropCnt=cntDrop() if dropCnt<=0 then return end if running then return end showCfm() end

cYes.MouseButton1Click:Connect(function()
	if running then return end
	running=true
	local lst={}
	for _,cont in ipairs({Plr.Backpack,Plr.Character}) do if cont then for _,t in ipairs(cont:GetChildren()) do if canDrop(t) then table.insert(lst,t) end end end end
	local h=hum() if h then h:UnequipTools() end
	local c=Plr.Character
	for _,t in ipairs(lst) do if t and t.Parent and t.Parent~=WS then if c and t.Parent~=c then t.Parent=c task.wait() end t.Parent=WS end end
	hideCfm() running=false req()
end)
cNo.MouseButton1Click:Connect(function() hideCfm() end)

UIS.InputBegan:Connect(function(i,gp)
	if gp then return end
	if not mob then
		local kc=i.KeyCode
		if not sw then
			local map={ [Enum.KeyCode.One]=1,[Enum.KeyCode.Two]=2,[Enum.KeyCode.Three]=3,[Enum.KeyCode.Four]=4,[Enum.KeyCode.Five]=5,[Enum.KeyCode.Six]=6,[Enum.KeyCode.Seven]=7,[Enum.KeyCode.Eight]=8,[Enum.KeyCode.Nine]=9,[Enum.KeyCode.Zero]=10 }
			local idx=map[kc]
			if idx then local arr=orderedQBButtons() local b=arr[idx] local t=b and tBtns[b] if t then equip(t) req() end end
		end
		if kc==Enum.KeyCode.Q then setSwap()
		elseif kc==Enum.KeyCode.E then doDropAll()
		elseif kc==Enum.KeyCode.C then toggleCol()
		elseif kc==Enum.KeyCode.Backquote then toggleExp()
		elseif kc==Enum.KeyCode.F then if sel and sel:IsA("Tool") then attr(sel,"BP_Fav",not getattr(sel,"BP_Fav",false)) req() end
		elseif kc==Enum.KeyCode.L then if sel and sel:IsA("Tool") then attr(sel,"BP_Lock",not getattr(sel,"BP_Lock",false)) req() end end
	end
end)

swBtn.MouseButton1Click:Connect(setSwap)
drpBtn.MouseButton1Click:Connect(doDropAll)
colBtn.MouseButton1Click:Connect(toggleCol)
ex.MouseButton1Click:Connect(toggleExp)

srch:GetPropertyChangedSignal("Text"):Connect(function() qtxt=srch.Text or "" req() end)

local conns={}
local function hook()
	for _,c in ipairs(conns) do if c and c.Disconnect then c:Disconnect() end end table.clear(conns)
	local bp=Plr:FindFirstChild("Backpack")
	if bp then table.insert(conns,bp.ChildAdded:Connect(req)) table.insert(conns,bp.ChildRemoved:Connect(req)) end
	if Plr.Character then table.insert(conns,Plr.Character.ChildAdded:Connect(req)) table.insert(conns,Plr.Character.ChildRemoved:Connect(req)) end
end
Plr.CharacterAdded:Connect(function() task.wait(.1) req() hook() end)

hook()
rebuild()
bar:GetPropertyChangedSignal("AbsoluteSize"):Connect(layout)
sgs("RunService").Heartbeat:Connect(function() if ui.Parent==nil then ui.Parent=root() end if cfm.Visible then posCfm() end end)