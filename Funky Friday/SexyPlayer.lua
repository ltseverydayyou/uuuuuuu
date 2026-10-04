local ENV = (getgenv and getgenv()) or _G

if type(ENV.__FunkyFridayAutoplayer) == "table" and type(ENV.__FunkyFridayAutoplayer.Unload) == "function" then
	pcall(function()
		ENV.__FunkyFridayAutoplayer:Unload()
	end)
end

local __lt = (function()
	local globalEnv = (getgenv and getgenv()) or _G or {}
	local sharedEnv = rawget(_G, "shared")
	local cacheHost = type(sharedEnv) == "table" and sharedEnv or (type(globalEnv) == "table" and globalEnv or nil)
	if cacheHost then
		local cached = rawget(cacheHost, "__lt_service_resolver")
		if type(cached) == "table" then
			return cached
		end
	end
	local loader = loadstring or load
	if type(loader) ~= "function" then
		error("Service resolver loader unavailable")
	end
	local resolver = loader(game:HttpGet("https://ltseverydayyou.github.io/ServiceResolver.luau"), "@ServiceResolver.luau")
	if type(resolver) ~= "function" then
		error("Service resolver failed to compile")
	end
	local loaded = resolver()
	if type(loaded) ~= "table" then
		error("Service resolver failed to load")
	end
	if cacheHost then
		cacheHost.__lt_service_resolver = loaded
	end
	return loaded
end)()

local Players = __lt.cs("Players", cloneref)
local RunService = __lt.cs("RunService", cloneref)
local VirtualInputManager = __lt.cs("VirtualInputManager", cloneref)
local UserInputService = __lt.cs("UserInputService", cloneref)
local Client = Players.LocalPlayer
local PlayerGui = Client:WaitForChild("PlayerGui")
local IsDesktop = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
local HasVirtualInput = VirtualInputManager ~= nil

local HasScriptableInput = pcall(function()
	local binding = Instance.new("InputBinding")
	binding.Type = Enum.InputBindingType.Scriptable
	binding:Destroy()
end)

local IsExternal = IsDesktop and not HasScriptableInput

local InputModes = {}
if HasScriptableInput then
	InputModes[#InputModes + 1] = "Scriptable Input"
end
if HasVirtualInput then
	InputModes[#InputModes + 1] = "Virtual Input"
end
if #InputModes == 0 then
	error("No supported input method found")
end

local DefaultInputMode = InputModes[1]

local connections = {
	_list = {},
	add = function(self, signal, cb)
		local conn = signal:Connect(cb)
		self._list[#self._list + 1] = conn
		return conn
	end,
	disconnect = function(self)
		for _, conn in self._list do
			if typeof(conn) == "RBXScriptConnection" then
				pcall(function()
					conn:Disconnect()
				end)
			end
		end
		table.clear(self._list)
	end
}

local st = {
	auto = true,
	inMode = DefaultInputMode,
	accuracy = 100,
	off = 0,
	baseMs = 230,
	tapMs = 35,
	relMs = 0,
	holdTick = 0.015,
	maxHold = 8,
	alive = true,
	boundWindow = nil,
	laneDown = {},
	laneCount = {},
	Session = {},
	RayfieldWindow = nil,
	FieldWatch = nil,
	ActiveTasks = 0,
	ScriptBindings = setmetatable({}, {__mode = "k"}),
	ConfigWatch = nil,
	SpecialPageWatch = nil,
	VisualConnections = {},
	VisualSeen = setmetatable({}, {__mode = "k"}),
	VisualNoteIds = setmetatable({}, {__mode = "k"}),
	NextVisualId = 0,
	InputModes = InputModes,
	Capabilities = {
		External = IsExternal,
		VirtualInput = HasVirtualInput,
		ScriptableInput = HasScriptableInput,
	},
	NoteBridge = nil,
	SongGeneration = 0,
	NoteStats = {Pressed = 0, Skipped = {}, Reused = 0},
	SpecialNotes = {
		Death = {Profiles = {}},
		Poison = {Profiles = {}},
		Normal = {},
		Refreshing = false,
	}

}

ENV.__FunkyFridayAutoplayer = st

local function getLaneKeyCode(action)
	if not action then
		return nil
	end
	for _, child in ipairs(action:GetChildren()) do
		if child:IsA("InputBinding") then
			local keyCode = child.KeyCode
			if keyCode and keyCode ~= Enum.KeyCode.Unknown then
				return keyCode
			end
		end
	end
	return nil
end

local function getScriptBinding(action)
	if not action then
		return nil
	end

	local binding = st.ScriptBindings[action]
	if binding and binding.Parent == action then
		return binding
	end

	binding = Instance.new("InputBinding")
	binding.Name = "SexyPlayerScriptBinding"
	binding.Type = Enum.InputBindingType.Scriptable
	binding.Parent = action
	st.ScriptBindings[action] = binding

	return binding
end

local function fireAction(action, down)
	if not action then
		return false
	end

	if st.inMode == "Scriptable Input" then
		if not HasScriptableInput then
			return false
		end

		local binding = getScriptBinding(action)
		if not binding then
			return false
		end

		return pcall(function()
			binding:Fire(down)
		end)
	end

	return false
end

local function pressLane(name, action)
	if st.inMode ~= "Virtual Input" then
		fireAction(action, true)
		return
	end

	local keyCode = getLaneKeyCode(action)
	if keyCode and HasVirtualInput then
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, keyCode, false, game)
		end)
	end
end

local function releaseLane(name, action)
	if st.inMode ~= "Virtual Input" then
		fireAction(action, false)
		return
	end

	local keyCode = getLaneKeyCode(action)
	if keyCode and HasVirtualInput then
		pcall(function()
			VirtualInputManager:SendKeyEvent(false, keyCode, false, game)
		end)
	end
end

local function getHoldTail(Arrow)
	if not Arrow then
		return nil
	end
	for _, child in ipairs(Arrow:GetChildren()) do
		if child:IsA("GuiObject") and child.ZIndex == 1 then
			return child
		end
	end
	return nil
end

local function isHold(Arrow)
	local tail = getHoldTail(Arrow)
	return tail and tail.Parent and tail.Visible and math.abs(tail.AbsoluteSize.Y) > 0.5 or false
end


local MetadataSource = [==[
local playerGui = game.Players.LocalPlayer.PlayerGui
local bridge = playerGui:FindFirstChild("__SexyPlayerNoteMetadata")
if not bridge then return end
local generation = bridge:GetAttribute("Generation")
local env = (getgenv and getgenv()) or _G
local previous = env.__SexyPlayerMetadataBridge
if previous and previous.Stop then previous.Stop() end
local state = {Active = true, Tagged = 0, NextId = 0, NoteIds = setmetatable({}, {__mode = "k"})}
env.__SexyPlayerMetadataBridge = state
local class, original, wrapper
local changed, removed
local function stop()
	if not state.Active then return end
	state.Active = false
	if class and rawget(class, "ApplyVisual") == wrapper then
		class.ApplyVisual = original
	end
	if changed then changed:Disconnect() end
	if removed then removed:Disconnect() end
	if env.__SexyPlayerMetadataBridge == state then
		env.__SexyPlayerMetadataBridge = nil
	end
end
state.Stop = stop
local function active()
	return state.Active and bridge.Parent == playerGui
		and bridge:GetAttribute("Active") == true
		and bridge:GetAttribute("Generation") == generation
end
local function stamp(note)
	if not active() then return end
	local frame = note.Frame
	if typeof(frame) ~= "Instance" or not frame:IsA("GuiObject") then return end
	local data = note.NoteData
	local kind = type(data) == "table" and data.Type or nil
	if type(kind) ~= "string" or kind == "" then kind = "Normal" end
	if kind == "Mechanic" and type(data.HitSound) == "table" then
		local sound = tostring(data.HitSound.AssetId or "")
		local id = sound:match("rbxassetid://(%d+)") or sound:match("[?&]id=(%d+)")
		if id == "9421719366" then kind = "Ink" end
	end
	local id = state.NoteIds[note]
	if not id then
		state.NextId += 1
		id = state.NextId
		state.NoteIds[note] = id
	end
	frame:SetAttribute("__SexyPlayerNoteType", kind)
	frame:SetAttribute("__SexyPlayerNoteGeneration", generation)
	frame:SetAttribute("__SexyPlayerNoteId", id)
	state.Tagged += 1
end
local ok, failure = pcall(function()
	local objects = getgc(true)
	local scanned = 0
	for _, value in pairs(objects) do
		if not active() then stop() return end
		if type(value) == "table"
			and type(rawget(value, "ApplyVisual")) == "function"
			and type(rawget(value, "GetVisualType")) == "function"
			and type(rawget(value, "GetVisualCacheKey")) == "function"
			and type(rawget(value, "ReleaseVisual")) == "function"
			and rawget(value, "__index") == value then
			class = value
			break
		end
		scanned += 1
		if scanned % 3000 == 0 then task.wait() end
	end
	if not class then
		bridge:SetAttribute("Status", "Unavailable")
		stop()
		return
	end
	original = class.ApplyVisual
	wrapper = function(note, ...)
		if active() then pcall(stamp, note) end
		return original(note, ...)
	end
	class.ApplyVisual = wrapper
	changed = bridge:GetAttributeChangedSignal("Active"):Connect(function()
		if not active() then stop() end
	end)
	removed = bridge.AncestryChanged:Connect(function()
		if not active() then stop() end
	end)
	scanned = 0
	for _, value in pairs(objects) do
		if not active() then stop() return end
		if type(value) == "table" and rawget(value, "Frame")
			and getmetatable(value) == class then
			pcall(stamp, value)
		end
		scanned += 1
		if scanned % 3000 == 0 then task.wait() end
	end
	if active() then bridge:SetAttribute("Status", "Ready") end
end)
if not ok then
	if bridge.Parent then
		bridge:SetAttribute("Status", "Unavailable")
		bridge:SetAttribute("Error", tostring(failure))
	end
	stop()
end
]==]

local function startNoteMetadata()
	if st.NoteBridge then
		return
	end
	local bridge = Instance.new("ScreenGui")
	bridge.ResetOnSpawn = false
	bridge.Enabled = false
	bridge.Name = "__SexyPlayerNoteMetadata"
	bridge:SetAttribute("Generation", tostring(os.clock()) .. ":" .. tostring(math.random(1, 1000000000)))
	bridge:SetAttribute("Active", true)
	bridge:SetAttribute("Status", "Starting")
	bridge.Parent = PlayerGui
	st.NoteBridge = bridge

	task.spawn(function()
		local scripts = Client:FindFirstChild("PlayerScripts")
		local actor = scripts and scripts:FindFirstChild("ClientActor")
		local ok, failure
		if type(getgc) ~= "function" then
			ok, failure = false, "This executor does not support note metadata."
		elseif actor and actor:IsA("Actor") then
			if type(run_on_actor) == "function" then
				ok, failure = pcall(run_on_actor, actor, MetadataSource)
			else
				ok, failure = false, "This executor cannot inspect the game Actor."
			end
		elseif type(getgc) == "function" then
			ok, failure = pcall(function()
				local chunk = assert(loadstring(MetadataSource))
				chunk()
			end)
		else
			ok, failure = false, "This executor does not support note metadata."
		end
		if not ok and st.alive and bridge.Parent then
			bridge:SetAttribute("Status", "Unavailable")
			bridge:SetAttribute("Error", tostring(failure))
		end
		if bridge:GetAttribute("Status") == "Unavailable" and st.CaptureVisualFallback then
			task.defer(st.CaptureVisualFallback)
		end
	end)
	task.delay(8, function()
		if st.alive and bridge.Parent and bridge:GetAttribute("Status") == "Starting" then
			bridge:SetAttribute("Active", false)
			bridge:SetAttribute("Status", "Unavailable")
			if st.CaptureVisualFallback then task.defer(st.CaptureVisualFallback) end
		end
	end)
end


local VisualAssets = {"135247410719619","97859679023673","117950128749630","100522630100836","102710180349520","137305795499748","105618996240035","89368350561562","120077286622596","125973904904727","88815830295612","125614392730801","131438056522776","95997911621516","82433760926790","134078382097754","83024668935378","88623923653538","98258294634474","139899676689264","132028516743068","137491238230924","101754283884820","134951306004947","77051531406087","110522238640680","90996043647752","81712944045829","127288073523042","90592902030176","131013310714751","100637486396953","129523889204688","126049110762781","74206469494183","97011641220747","94187659803317","88647380940312","132269384952711","108332885170033","70949553371793","80836960581549","123171423822972","93474527545872","84544103613968","100073642139171","108027014534415","83632481586951","97779350044832","124332534093391","134390824705371","81329570694416","76817155081045","88550364999172","103063425974568","74744595588977","90852188225585","128897696725874","118284681658493","88176359838610","110641141870973","116026042241052","135925752254033","105571921849041","101951481332606","74989444694115","109857951809418","112141063109581","130448515526528","88131147482537","87301150070735","128886503985108","79644112699489","81831982206128","127714985054422","103576145534805","88067184940388","132404865147562","113468164251564","77877909237438","105157714692902","94539566483091","97640364707344","92901446275923","111175549789326","125405506159440","138114221280372","120891245268032","137814443249403","103862364696380","117944127596350","124075223315231","131741543485402","107215480051315","133222703602663","115603650852501","75524650572498","125722317784791","127322913332738","121997897711216","122064597399427","127362811769496","87743207101098","98498894332744","99816820820800","85717993084332","111497460693999","84356163533861","133263472129634","117288521503268","95770781667571","130004899415502","75862403162465","95851817051841","86194990546450","134223416173457","129791925609733","132204201599518","135960440706872","123422112508811","95077432906626","113892673552791","113608304221862","112893595926577","82636615225130","73229114662777","122144856015915","116701735663586","70615456198196","88056379261795","88076413543941","83336387639549","116910567291554","99368657892054","93143905863386","103880231421728","99509080556008","113004063203508","99202730603474","72815517484624","98433531004275","93739184078118","90846540653983","80253856536931","119301770512486","106397891894659","118981792654344","96966339099967","76657740448366","88530467220950","116778203667435","97355329037382","101719661587831","121050035423923","103483801062498","116254476280414","72724303384571","93284497372220","94879692676230","120222801097284","91620137594170","137442050024089","140299359268584","139441586066249","109130876544260","84581380793886","130111924509910","119104556068885","76252501179369","80298325187976","73205421514412","132532815386599","105152364570594","121980351710989","110081612268797","84658657587205","72857182773372","74778632523218","94424181375160","128100089596481","72819625279696","91671075057613","94366594691630","93507774369953","134007223583553","79774417078719","109046147716805","74662600334622","81375359056139","114980386293749","97335990685876","118673355653002","93415357117060","83295758765497","83533816507323","115909868580964","120847214217062","72996609076832","118205352192453","74238562557086","101212778722034","118341192063747","139507100655273","133282191406359","116868531931602","111809538352485","105480816603498","76379952300447","101725135995114","130804613566234","102894258806452","128268884651974","96604591493196","92949027884274","102902647198186","113821625972955","72804556788860","112057810779311","133511339820475","106788188950313","84438359324747","122076439179709","110989877445733","94822811579015","131645129410649","99105764247045","108541535006657","84605907512666","104154834835917","89368338358372","79164038901476","130415153272628","84561666722026","79647982878902","84339082252177","123283213030186","139888978437583","119800592848573","124935674564588","98054736126648","113231930089284","123470741875983","91211626632196","74453327225172","121141398791935","116370134812900","127552100415973","131520541612632","110404646810559","92466832175059","137973214096347","127724254048328","80984405498652","122144558690848","137842432863456","75685697026260","118187648687831","106590345548535","118166223565083","80717394682160","91618568479569","75387307594209","112992638532728","110959724577174","119161261521150","108958050258766","107680012756488","85816370070710","96411703845150","88036705171195","101690013192099","124956231480024","100174414094134","134509476539243","91004507003205","134234618872336","133042894863252","109777757150908","89053020004865","88657145321879","80967770211277","127215701796674","95681788015275","115391638842068","73448476558230","87933757334894","72146808564070","111791807818682","130171362516103","130897298181182","96537126319273","76096258423972","91550337553769","85898387461579","81139026136795","134569639243259","80653824188619","112267593697241","84981301245179","121700216794744","103609409121813","88379862269060","105897185387242","120657620985845","95993981370759","115656951614909","73951741879206","84500752269603","82694839579783","74078892912327","113866589041863","131467734566623","110158519269933","109439341150950","70443454523276","125845988282811","88404659579027","129074935359264","123425033876355","136658248440296","127790291527395","130016793424596","129474807865353","82783013194627","73879533638080","109482017718896","94587390045454","79221580810771","102083341320502","115072949741288","135853313738366","109767315748401","88863654504457","121677284163372","106434370515763","83143282797261","104919860689182","83050022981586","102920116000560","129370951907174","107648851023311","132285258569998","75811464124385","106286818916283","139157637017055","126955350162006","93310471781978","106343196043116","103421554896869","119099245531292","138233461804628","108778461230799","130590951541019","77142582285898","86651831302171","134090297010614","78301705316595","118794319069045","114270324246714","78962612099322","75638823389101","124338479931736","81460860280239","128590336127798","96236334592322","94728961352616","111714319413786","70975542961379","85638601137920","126117759227762","129276184110936","127617329133000","97033333790523","86950158136924","76032297583541","82389635043232","115217347989749","102571376947963","77165077762462","106291167890600","74367890206296","81031850588909","107676212757466","118054598867233","127309114779004","92362778258231","114361423725142","106071171701845","116084693511791","95353779387368","129214223702443","80812104927364","90731545195307","93818425210105","101544854152041","88126400357325","121406338911394","80181507685235","110777572136501","74343369854706","70377520750301","136112808322655","78972940335337","76705888188205","78762656702468","84668046081241","118366043883080","73826500770559","107436014116964","135908871268032","84655302236875","81165952836051","74407843955874","131413011088730","103519691959598","107618158569602","133369468616643","103804350552719","96600940353543","85441932749777","127388234242409","115681906352950","98975132328909","107899201372795","108702245869734","119913658674563","102803087062531","83062750111897","103627435339853","73959231044946","73613617541145","136739833492762","98918732616529","120455106426844","81076092531783","121015559586507","134128390489590","96477318615537","113773287423098","82175863019599","94773365884994","72155542903392","122775603303803","95977731311581","82086135132386","70466167062868","129794512628536","82348362837057","122488607969105","129129532758378","139544039048908","103399690562999","113469750479220","136246561549121","127951949963927","79841658578457","120581427136497","123287515732725","127697196520760","105521227007539","140222973621448","84556483168120","124073553738356","99022692732472","105679971282431","96777398085529","82280365417089","80087842567545","108458952979981","112278873909992","99950935323649","83905691302468","77356076492800","75442119339813","123251271225155","113304855517533","114584338314068","118270472859755","126133687859356","79710606712743","77881991620205","110530111235573","138463311695288","136522204063299","74280877261073","115919792377229","93199647855016","111487370594144","131745893889601","100742885063153","77685821387703","98715623313431","122453123017211","105041471676600","134218634352212","111041789521373","116314392120560","113965432917318","70953070004200","107289712555550","111888324336133","114493259160628","94295042338971","140256897187364","90821649912069","74368611517676","78030893318791","106297332864879","82922893238857","123911869347704","126496734985489","88103203842978","99615237411475","102776439587029","73919843476639","128237103291542","72257537771587","95096129846643","113891158137895","91881274960323","97246933690525","139903250808007","88993086220674","111180294383983","123160839334826","108903236033839","140668449320412","88004828567597","99086982490411","104424056486418","78318568097022","116647754343776","125401559182862","88838731471626","108426079457091","91442713275312","86348746977639","116052580964661","98896833754364","71733372882715","126471842852524","71649693821150","120961456120500","125790727741511","116667340835865","131690128861320","93263029866544","119132818095233","107416557315862","123445434163990","89475729318212"}
local VisualTemplates = {
	{"Shadow","Left",{-1,2,3,-4},{-1,2,3,-4},{-5,6,7,-8}},
	{"Shadow","Down",{-9,10,11,-12},{-9,10,11,-12},{-13,14,15,-16}},
	{"Shadow","Up",{-17,18,19,-20},{-17,18,19,-20},{-21,22,23,-24}},
	{"Shadow","Right",{-25,26,27,-28},{-25,26,27,-28},{-29,30,31,-32}},
	{"Inverted","Left",{-33,34},{-35,36,37},{-38,39,40}},
	{"Inverted","Down",{-41,42},{-43,44,45},{-46,47,48}},
	{"Inverted","Up",{-49,50},{-51,52,53},{-54,55,56}},
	{"Inverted","Right",{-57,58},{-59,60,61},{-62,63,64}},
	{"Hazard","Left",{-65,66,67},{-65,66,67},{-68,69,70,-71}},
	{"Hazard","Down",{-65,66,67},{-65,66,67},{-68,69,70,-71}},
	{"Hazard","Up",{-65,66,67},{-65,66,67},{-68,69,70,-71}},
	{"Hazard","Right",{-65,66,67},{-65,66,67},{-68,69,70,-71}},
	{"DefaultAlt","Left",{-72,73,74,-75},{-72,73,74,-75},{-76,77,78,-79}},
	{"DefaultAlt","Down",{-80,81,82,-83},{-80,81,82,-83},{-84,85,86,-87}},
	{"DefaultAlt","Up",{-88,89,90,-91},{-88,89,90,-91},{-92,93,94,-95}},
	{"DefaultAlt","Right",{-96,97,98,-99},{-96,97,98,-99},{-100,101,102,-103}},
	{"Taiko","Left",{-104,105,106},{-104,105,106},{-107,108,109}},
	{"Taiko","Down",{-104,105,106},{-104,105,106},{-107,108,109}},
	{"Taiko","Up",{-104,105,106},{-104,105,106},{-107,108,109}},
	{"Taiko","Right",{-104,105,106},{-104,105,106},{-107,108,109}},
	{"Aus_si","Left",{-110,111,112},{-113,114,115},{-116,117,118,-119}},
	{"Aus_si","Down",{-120,121,122},{-123,124,125},{-126,127,128,-129}},
	{"Aus_si","Up",{-130,131,132},{-133,134,135},{-136,137,138,-139}},
	{"Aus_si","Right",{-140,141,142},{-143,144,145},{-146,147,148,-149}},
	{"Expurgation","Left",{150,-151},{150,-151},{-152,153,-154}},
	{"Expurgation","Down",{155,-156},{155,-156},{-157,158,-159}},
	{"Expurgation","Up",{160,-161},{160,-161},{-162,163,-164}},
	{"Expurgation","Right",{165,-166},{165,-166},{-167,168,-169}},
	{"3D","Left",{-170,171},{-170,171},{-172,173,174}},
	{"3D","Down",{-175,176},{-175,176},{-177,178,179}},
	{"3D","Up",{-180,181},{-180,181},{-182,183,184}},
	{"3D","Right",{-185,186},{-185,186},{-187,188,189}},
	{"InvertedOutline","Left",{-190,191},{-190,191},{-192,193,194}},
	{"InvertedOutline","Down",{-195,196},{-195,196},{-197,198,199}},
	{"InvertedOutline","Up",{-200,201},{-200,201},{-202,203,204}},
	{"InvertedOutline","Right",{-205,206},{-205,206},{-207,208,209}},
	{"CircularWide","Left",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"CircularWide","Down",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"CircularWide","Up",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"CircularWide","Right",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"Ron","Left",{-220,221,222},{-220,221,222},{-223,224,225,-226}},
	{"Ron","Down",{-227,228,229},{-227,228,229},{-230,231,232,-233}},
	{"Ron","Up",{-234,235,236},{-234,235,236},{-237,238,239,-240}},
	{"Ron","Right",{-241,242,243},{-241,242,243},{-244,245,246,-247}},
	{"Square","Left",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"Square","Down",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"Square","Up",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"Square","Right",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"DiamondWide","Left",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"DiamondWide","Down",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"DiamondWide","Up",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"DiamondWide","Right",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"OsuFelopesSkin","Left",{-265},{266},{267}},
	{"OsuFelopesSkin","Down",{-265},{266},{267}},
	{"OsuFelopesSkin","Up",{-265},{266},{267}},
	{"OsuFelopesSkin","Right",{-265},{266},{267}},
	{"Sus","Left",{-268,269,270},{-271,272,273},{-274,275,276}},
	{"Sus","Down",{-268,269,270},{-271,272,273},{-274,275,276}},
	{"Sus","Up",{-268,269,270},{-271,272,273},{-274,275,276}},
	{"Sus","Right",{-268,269,270},{-271,272,273},{-274,275,276}},
	{"Circular","Left",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"Circular","Down",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"Circular","Up",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"Circular","Right",{-210,211,212},{-213,214,215},{-216,217,218,-219}},
	{"BarWide","Left",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"BarWide","Down",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"BarWide","Up",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"BarWide","Right",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"OsuEliminateCircles","Left",{-287},{288},{289}},
	{"OsuEliminateCircles","Down",{-287},{288},{289}},
	{"OsuEliminateCircles","Up",{-287},{288},{289}},
	{"OsuEliminateCircles","Right",{-287},{288},{289}},
	{"Bloxxin","Left",{-290,291,292},{-293,294},{-295,296,297,-298}},
	{"Bloxxin","Down",{-299,300,301},{-302,303},{-304,305,306,-307}},
	{"Bloxxin","Up",{-308,309,310},{-311,312},{-313,314,315,-316}},
	{"Bloxxin","Right",{-317,318,319},{-320,321},{-322,323,324,-325}},
	{"Fumo","Left",{326},{-327,328},{329}},
	{"Fumo","Down",{330},{-331,332},{333}},
	{"Fumo","Up",{334},{-335,336},{337}},
	{"Fumo","Right",{338},{-339,340},{341}},
	{"Diamond","Left",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"Diamond","Down",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"Diamond","Up",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"Diamond","Right",{-255,256,257},{-258,259,260},{-261,262,263,-264}},
	{"OsuManiaPl0x","Left",{-342,343},{-342,343},{-344,345}},
	{"OsuManiaPl0x","Down",{-346,347},{-346,347},{-348,349}},
	{"OsuManiaPl0x","Up",{-350,351},{-350,351},{-352,353}},
	{"OsuManiaPl0x","Right",{-354,355},{-354,355},{-356,357}},
	{"SquareWide","Left",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"SquareWide","Down",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"SquareWide","Up",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"SquareWide","Right",{-248,249,250},{-248,249,250},{-251,252,253,-254}},
	{"Static","Left",{-358,359,360},{-358,359,360},{-361,362,363,-364}},
	{"Static","Down",{-365,366,367},{-365,366,367},{-368,369,370,-371}},
	{"Static","Up",{-372,373,374},{-372,373,374},{-375,376,377,-378}},
	{"Static","Right",{-379,380,381},{-379,380,381},{-382,383,384,-385}},
	{"StepManiaWide","Left",{-386,387,388,-389},{-390,391,392,-393},{-394,395,396,-397}},
	{"StepManiaWide","Down",{-398,399,400,-401},{-402,403,404,-405},{-406,407,408,-409}},
	{"StepManiaWide","Up",{-410,411,412,-413},{-414,415,416,-417},{-418,419,420,-421}},
	{"StepManiaWide","Right",{-422,423,424,-425},{-426,427,428,-429},{-430,431,432,-433}},
	{"StepMania","Left",{-386,387,388,-389},{-390,391,392,-393},{-394,395,396,-397}},
	{"StepMania","Down",{-398,399,400,-401},{-402,403,404,-405},{-406,407,408,-409}},
	{"StepMania","Up",{-410,411,412,-413},{-414,415,416,-417},{-418,419,420,-421}},
	{"StepMania","Right",{-422,423,424,-425},{-426,427,428,-429},{-430,431,432,-433}},
	{"Glitched","Left",{-434,435,-436},{-434,435,-436},{-437,438,439,-440}},
	{"Glitched","Down",{-441,442,-443},{-441,442,-443},{-444,445,446,-447}},
	{"Glitched","Up",{-448,449,-450},{-448,449,-450},{-451,452,453,-454}},
	{"Glitched","Right",{-455,456,-457},{-455,456,-457},{-458,459,460,-461}},
	{"EXE","Left",{-462,463,464},{-462,463,464},{-465,466,467}},
	{"EXE","Down",{-462,463,464},{-462,463,464},{-465,466,467}},
	{"EXE","Up",{-462,463,464},{-462,463,464},{-465,466,467}},
	{"EXE","Right",{-462,463,464},{-462,463,464},{-465,466,467}},
	{"Default","Left",{-110,111,112},{-113,114,115},{-116,117,118,-119}},
	{"Default","Down",{-120,121,122},{-123,124,125},{-126,127,128,-129}},
	{"Default","Up",{-130,131,132},{-133,134,135},{-136,137,138,-139}},
	{"Default","Right",{-140,141,142},{-143,144,145},{-146,147,148,-149}},
	{"Etterna","Left",{-468,469,470},{-471},{-472}},
	{"Etterna","Down",{-473,474,475},{-476},{-477}},
	{"Etterna","Up",{-478,479,480},{-481},{-482}},
	{"Etterna","Right",{-483,484,485},{-486},{-487}},
	{"ClassicDefault","Left",{-110,111,112},{-113,114,115},{-116,117,118,-119}},
	{"ClassicDefault","Down",{-120,121,122},{-123,124,125},{-126,127,128,-129}},
	{"ClassicDefault","Up",{-130,131,132},{-133,134,135},{-136,137,138,-139}},
	{"ClassicDefault","Right",{-140,141,142},{-143,144,145},{-146,147,148,-149}},
	{"RetroSpecter","Left",{-488,489,490,-491},{-488,489,490,-491},{-492,493,494,-495}},
	{"RetroSpecter","Down",{-496,497,498,-499},{-496,497,498,-499},{-500,501,502,-503}},
	{"RetroSpecter","Up",{-504,505,506,-507},{-504,505,506,-507},{-508,509,510,-511}},
	{"RetroSpecter","Right",{-512,513,514,-515},{-512,513,514,-515},{-516,517,518,-519}},
	{"Pixel","Left",{-520,521,522,-523},{-520,521,522,-523},{-524,525,526,-527}},
	{"Pixel","Down",{-528,529,530,-531},{-528,529,530,-531},{-532,533,534,-535}},
	{"Pixel","Up",{-536,537,538,-539},{-536,537,538,-539},{-540,541,542,-543}},
	{"Pixel","Right",{-544,545,546,-547},{-544,545,546,-547},{-548,549,550,-551}},
	{"Bar","Left",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"Bar","Down",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"Bar","Up",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
	{"Bar","Right",{-277,278,279},{-280,281,282},{-283,284,285,-286}},
}

local GuiService = __lt.cs("GuiService", cloneref)
local function assetId(image)
	return image:match("rbxassetid://(%d+)") or image:match("[?&]id=(%d+)") or image
end

local function profileFromLayers(layers, tint)
	local exact, shape = {}, {}
	for index, layer in ipairs(layers) do
		local id = math.abs(layer)
		local base = table.concat({VisualAssets[id], "0", "0", "0", "0", tostring(index)}, "|")
		local color = layer < 0 and tint or Color3.new(1, 1, 1)
		shape[#shape + 1] = base
		exact[#exact + 1] = base .. "|" .. math.round(color.R * 255) .. "|" .. math.round(color.G * 255) .. "|" .. math.round(color.B * 255)
	end
	table.sort(shape)
	table.sort(exact)
	return table.concat(exact, ";"), table.concat(shape, ";")
end

local function spriteProfile(root)
	if not root then return nil end
	local exact, shape, images = {}, {}, {}
	local function add(obj)
		if (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) and obj.Visible and obj.Image ~= "" then
			local offset, size, color = obj.ImageRectOffset, obj.ImageRectSize, obj.ImageColor3
			local base = table.concat({assetId(obj.Image), tostring(offset.X), tostring(offset.Y),
				tostring(size.X), tostring(size.Y), tostring(obj.ZIndex)}, "|")
			shape[#shape + 1] = base
			exact[#exact + 1] = base .. "|" .. math.round(color.R * 255) .. "|" .. math.round(color.G * 255) .. "|" .. math.round(color.B * 255)
			images[obj.ZIndex] = color
		end
	end
	add(root)
	for _, obj in ipairs(root:QueryDescendants("ImageLabel, ImageButton")) do add(obj) end
	if #shape == 0 then return nil end
	table.sort(shape)
	table.sort(exact)
	return table.concat(exact, ";"), table.concat(shape, ";"), images
end

local NormalAliases = {}
local InkProfiles = {}
local ActiveNormalShapes = {}
local NormalTintKnown = {}
for _, template in ipairs(VisualTemplates) do
	local normal = template[3]
	local black = profileFromLayers(normal, Color3.new(0, 0, 0))
	InkProfiles[black] = true
	for i = 4, 5 do
		local _, shape = profileFromLayers(template[i], Color3.new(0, 0, 0))
		NormalAliases[shape] = NormalAliases[shape] or {}
		NormalAliases[shape][#NormalAliases[shape] + 1] = {Source = template[i], Target = normal}
	end
	if template[1] == "Expurgation" then
		st.SpecialNotes.Death.Profiles[profileFromLayers(normal, Color3.fromRGB(240, 0, 0))] = true
	elseif template[1] == "Hazard" then
		st.SpecialNotes.Poison.Profiles[profileFromLayers(normal, Color3.fromRGB(255, 255, 0))] = true
	end
end

local function learnNormal(root)
	local _, shape, colors = spriteProfile(root)
	for _, alias in ipairs(shape and NormalAliases[shape] or {}) do
		local tint = Color3.new(1, 1, 1)
		local known = false
		for index, id in ipairs(alias.Source) do
			if id < 0 and colors[index] then tint = colors[index] known = true break end
		end
		local profile, targetShape = profileFromLayers(alias.Target, tint)
		ActiveNormalShapes[targetShape] = true
		NormalTintKnown[targetShape] = NormalTintKnown[targetShape] or known
		if known then st.SpecialNotes.Normal[profile] = true end
	end
end
st.LearnNormalSprite = learnNormal

local function getSpecialSettingsUi()
	local gameGui = PlayerGui:FindFirstChild("GameGui")
	local windows = gameGui and gameGui:FindFirstChild("Windows")
	local configuration = windows and windows:FindFirstChild("Configuration")
	local frame = configuration and configuration:FindFirstChild("Frame")
	local body = frame and frame:FindFirstChild("Body")
	local content = body and body:FindFirstChild("Content")
	local arrows = content and content:FindFirstChild("Arrows")
	local pages = arrows and arrows:FindFirstChild("Content")
	local notes = pages and pages:FindFirstChild("Notes")
	local options = notes and notes:FindFirstChild("Options")
	local bottom = options and options:FindFirstChild("Bottom")
	local preview = bottom and bottom:FindFirstChild("Arrows")
	local inner = preview and preview:FindFirstChild("Inner")
	local top = options and options:FindFirstChild("Top")
	local list = notes and notes:FindFirstChild("Notes")
	list = list and list:FindFirstChild("ScrollingFrame")
	local selection = arrows and arrows:FindFirstChild("Bottom")
	selection = selection and selection:FindFirstChild("Selection")
	local tabs = body and body:FindFirstChild("Top")
	tabs = tabs and tabs:FindFirstChild("Selection")
	return {
		Configuration = configuration, Content = content, Arrows = arrows, Pages = pages,
		NotesPage = notes, Preview = inner and inner:FindFirstChild("Arrows"),
		Colors = bottom and bottom:FindFirstChild("Colors"),
		Title = top and top:FindFirstChild("Title"),
		Death = list and list:FindFirstChild("Death"), Poison = list and list:FindFirstChild("Poison"),
		NotesButton = selection and selection:FindFirstChild("Notes"),
		Selection = selection, Tabs = tabs, ArrowsButton = tabs and tabs:FindFirstChild("Arrows"),
	}
end

local function refreshSpecialNoteSkins()
	local ui = getSpecialSettingsUi()
	if not (ui.Configuration and ui.Configuration.Visible and ui.Arrows and ui.Arrows.Visible
		and ui.NotesPage and ui.NotesPage.Visible and ui.Preview and ui.Title) then return end
	local title = ui.Title.Text
	local kind = title:find("Death", 1, true) and "Death" or title:find("Poison", 1, true) and "Poison"
	if not kind then return end
	local profiles = {}
	local rgb = ui.Colors and ui.Colors:FindFirstChild("RGB")
	local values = {}
	for _, key in ipairs({"R", "G", "B"}) do
		local channel = rgb and rgb:FindFirstChild(key)
		local inner = channel and channel:FindFirstChild("Inner")
		local box = inner and inner:FindFirstChild("TextBox")
		values[#values + 1] = box and tonumber(box.Text) or 255
	end
	local tint = Color3.fromRGB(math.clamp(values[1], 0, 255), math.clamp(values[2], 0, 255), math.clamp(values[3], 0, 255))
	for _, frame in ipairs(ui.Preview:GetChildren()) do
		local profile, shape = spriteProfile(frame:FindFirstChild("LayeredSprite"))
		if profile then profiles[profile] = true end
		for _, alias in ipairs(shape and NormalAliases[shape] or {}) do
			profiles[profileFromLayers(alias.Target, tint)] = true
		end
	end
	if next(profiles) then
		st.SpecialNotes[kind].Profiles = profiles
		st.SpecialNotes[kind].Captured = true
		st.SpecialNotes.Ready = st.SpecialNotes.Death.Captured and st.SpecialNotes.Poison.Captured or false
	end
end

local function clickGui(button)
	if not (button and button:IsA("GuiButton") and HasVirtualInput) then return false end
	local pos = button.AbsolutePosition + button.AbsoluteSize * 0.5
	pos += GuiService:GetGuiInset()
	local camera = workspace.CurrentCamera
	if not camera or pos.X < 0 or pos.Y < 0 or pos.X >= camera.ViewportSize.X or pos.Y >= camera.ViewportSize.Y then return false end
	return pcall(function()
		VirtualInputManager:SendMouseMoveEvent(pos.X, pos.Y, game)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, true, game, 0)
		task.wait(0.04)
		VirtualInputManager:SendMouseButtonEvent(pos.X, pos.Y, 0, false, game, 0)
	end)
end

local function waitFor(check)
	local deadline = os.clock() + 2
	repeat
		if not st.alive or PlayerGui:FindFirstChild("Window") then return false end
		if check() then task.wait(0.12) return true end
		task.wait(0.05)
	until os.clock() >= deadline
	return false
end

local function captureVisualFallback()
	if not st.alive or st.SpecialNotes.Refreshing then return false end
	if PlayerGui:FindFirstChild("Window") then
		if not st.SpecialNotes.Ready and not st.SpecialNotes.DeferredNotice and st.RayfieldWindow then
			st.SpecialNotes.DeferredNotice = true
			st.RayfieldWindow:Notify({title = "Note Detection", content = "Visual detection will finish setup after this song. Unknown notes are skipped until then.", duration = 7})
		end
		return false
	end
	st.SpecialNotes.Refreshing = true
	local ui = getSpecialSettingsUi()
	local config = ui.Configuration
	if not config then st.SpecialNotes.Refreshing = false return false end
	local wasOpen = config.Visible
	local overlay = st.RayfieldWindow and st.RayfieldWindow.screenGui
	local overlayEnabled = overlay and overlay.Enabled
	if overlay then overlay.Enabled = false end
	local originalTab, originalPage
	for _, page in ipairs(ui.Content:GetChildren()) do if page:IsA("GuiObject") and page.Visible then originalTab = page.Name break end end
	if ui.Pages then for _, page in ipairs(ui.Pages:GetChildren()) do if page:IsA("GuiObject") and page.Visible then originalPage = page.Name break end end end
	local originalKind = ui.Title and (ui.Title.Text:find("Death", 1, true) and "Death" or ui.Title.Text:find("Poison", 1, true) and "Poison")
	local top = PlayerGui:FindFirstChild("TopBar")
	local button = top and top:FindFirstChild("Frame")
	button = button and button:FindFirstChild("Left")
	button = button and button:FindFirstChild("Configuration")
	local ok, failure = pcall(function()
		if not config.Visible then
			st.SpecialNotes.CaptureStep = "Open settings"
			assert(clickGui(button) and waitFor(function() return config.Visible end))
		end
		ui = getSpecialSettingsUi()
		st.SpecialNotes.CaptureStep = "Arrows tab"
		assert(clickGui(ui.ArrowsButton) and waitFor(function() return ui.Arrows.Visible end))
		st.SpecialNotes.CaptureStep = "Notes tab"
		assert(clickGui(ui.NotesButton) and waitFor(function() return ui.NotesPage.Visible end))
		for _, kind in ipairs({"Death", "Poison"}) do
			st.SpecialNotes.CaptureStep = kind
			ui = getSpecialSettingsUi()
			assert(clickGui(ui[kind]) and waitFor(function() return ui.Title and ui.Title.Text:find(kind, 1, true) end))
			refreshSpecialNoteSkins()
			assert(st.SpecialNotes[kind].Captured)
		end
	end)
	if st.alive and not PlayerGui:FindFirstChild("Window") then
		if originalKind and ui[originalKind] then clickGui(ui[originalKind]) task.wait(0.12) end
		if originalPage and ui.Selection then clickGui(ui.Selection:FindFirstChild(originalPage)) task.wait(0.12) end
		if originalTab and ui.Tabs then clickGui(ui.Tabs:FindFirstChild(originalTab)) task.wait(0.12) end
		if not wasOpen and config.Visible then clickGui(button) end
	end
	st.SpecialNotes.Refreshing = false
	if overlay and overlay.Parent then overlay.Enabled = overlayEnabled end
	st.SpecialNotes.Ready = st.SpecialNotes.Death.Captured and st.SpecialNotes.Poison.Captured or false
	st.SpecialNotes.CaptureError = not ok and tostring(failure) or nil
	if not ok and st.RayfieldWindow and not st.SpecialNotes.Warned then
		st.SpecialNotes.Warned = true
		st.RayfieldWindow:Notify({title = "Note Detection", content = "Open Settings > Arrows > Notes and select Death, then Poison to finish visual detection.", duration = 7})
	end
	return st.SpecialNotes.Ready
end
st.CaptureVisualFallback = captureVisualFallback

local function lastReelActive()
	local gui = PlayerGui:FindFirstChild("GameGui")
	local screen = gui and gui:FindFirstChild("Screen")
	local top = screen and screen:FindFirstChild("TopLabel")
	local label = top and top:FindFirstChild("Label")
	return label and label.Text:find("Last Reel", 1, true) ~= nil
end

local function getSpecialNoteType(Arrow)
	if not Arrow then return "Unknown" end
	local bridge = st.NoteBridge
	if bridge and bridge:GetAttribute("Active")
		and Arrow:GetAttribute("__SexyPlayerNoteGeneration") == bridge:GetAttribute("Generation") then
		local kind = Arrow:GetAttribute("__SexyPlayerNoteType")
		if kind == "Death" or kind == "Poison" or kind == "Ink" then return kind end
		return nil
	end
	if bridge and bridge:GetAttribute("Status") ~= "Unavailable" then return "Unknown" end
	for _, key in ipairs({"NoteType", "Type"}) do
		local kind = Arrow:GetAttribute(key)
		if kind == "Death" or kind == "Poison" or kind == "Ink" then return kind end
	end
	local head
	for _, child in ipairs(Arrow:GetChildren()) do
		if child:IsA("GuiObject") and child.ZIndex == 2 then head = child break end
	end
	local profile, shape = spriteProfile(head)
	if not profile then return "Unknown" end
	local death = st.SpecialNotes.Death.Profiles[profile]
	local poison = st.SpecialNotes.Poison.Profiles[profile]
	local ink = lastReelActive() and InkProfiles[profile]
	local normal = st.SpecialNotes.Normal[profile]
	if normal and (death or poison or ink) then return "Ambiguous" end
	if ActiveNormalShapes[shape] and not NormalTintKnown[shape] and (death or poison or ink) then return "Ambiguous" end
	if death then return "Death" end
	if poison then return "Poison" end
	if ink then return "Ink" end
	if not (st.SpecialNotes.Death.Captured and st.SpecialNotes.Poison.Captured) then return "Unknown" end
	if normal or ActiveNormalShapes[shape] then return nil end
	return "Unknown"
end
st.GetSpecialNoteType = getSpecialNoteType

local function playSeq(Holder, Arrow, keyCode, AutoCtx)
	local noteId = st.VisualNoteIds[Arrow]
	task.spawn(function()
		st.ActiveTasks += 1
		local delayTime = math.max(0, (AutoCtx.baseOffset or 0) + (AutoCtx.offsetMs or 0) / 1000)
		if delayTime > 0 then
			task.wait(delayTime)
		end
		if not st.alive or not st.auto or AutoCtx.generation ~= st.SongGeneration then
			st.ActiveTasks -= 1
			return
		end
		if not Arrow or not Arrow.Parent or not Arrow.Visible then
			st.ActiveTasks -= 1
			return
		end
		if noteId and st.VisualNoteIds[Arrow] ~= noteId then
			st.NoteStats.Reused += 1
			st.ActiveTasks -= 1
			return
		end
		local skip = getSpecialNoteType(Arrow)
		if skip then
			st.NoteStats.Skipped[skip] = (st.NoteStats.Skipped[skip] or 0) + 1
			st.ActiveTasks -= 1
			return
		end
		if AutoCtx.laneDown[Holder] then
			AutoCtx.release(Holder.Name, keyCode)
		end
		AutoCtx.press(Holder.Name, keyCode)
		st.NoteStats.Pressed += 1
		AutoCtx.laneDown[Holder] = true
		AutoCtx.laneCount[Holder] = (AutoCtx.laneCount[Holder] or 0) + 1
		local untilTime = os.clock() + math.max(0.05, AutoCtx.maxHold or 8)
		if isHold(Arrow) then
			while Arrow and Arrow.Parent and Arrow.Visible and st.alive and st.auto and AutoCtx.generation == st.SongGeneration and os.clock() <= untilTime do
				if not isHold(Arrow) or (noteId and st.VisualNoteIds[Arrow] ~= noteId)
					or getSpecialNoteType(Arrow) then
					break
				end
				task.wait(math.max(0.005, AutoCtx.holdTick or 0.015))
			end
		else
			task.wait(math.max(0, AutoCtx.tapMs or 35) / 1000)
		end
		if AutoCtx.relMs and AutoCtx.relMs > 0 then
			task.wait(AutoCtx.relMs / 1000)
		end
		AutoCtx.laneCount[Holder] = math.max((AutoCtx.laneCount[Holder] or 1) - 1, 0)
		if AutoCtx.laneCount[Holder] <= 0 then
			AutoCtx.laneCount[Holder] = 0
			if AutoCtx.laneDown[Holder] then
				AutoCtx.release(Holder.Name, keyCode)
				AutoCtx.laneDown[Holder] = false
			end
		end
		st.ActiveTasks -= 1
	end)
end

local function releaseAll()
	for Holder, down in st.laneDown do
		if down then
			local action = st.Session[Holder.Name]
			if action then
				releaseLane(Holder.Name, action)
			end
			st.laneDown[Holder] = false
		end
	end
	for Holder in st.laneCount do
		st.laneCount[Holder] = 0
	end
end

local function pickLocalField(fields)
	local best
	local bestScore
	for _, sideName in ipairs({"Left", "Right"}) do
		local side = fields:FindFirstChild(sideName)
		local inner = side and side:FindFirstChild("Inner")
		local lane1 = inner and inner:FindFirstChild("Lane1")
		if side and lane1 then
			local score = (side.ZIndex or 0) * 100000 + lane1.AbsoluteSize.X
			if not bestScore or score > bestScore then
				best = side
				bestScore = score
			end
		end
	end
	return best
end

local function clearSongConnections()
	st.SongGeneration += 1
	st.NoteStats = {Pressed = 0, Skipped = {}, Reused = 0}
	releaseAll()
	for _, conn in connections._list do
		if conn and conn.Connected then
			pcall(function()
				conn:Disconnect()
			end)
		end
	end
	table.clear(connections._list)
	table.clear(st.Session)
end

local function bindSong()
	clearSongConnections()

	local context = PlayerGui:FindFirstChild("VSRGContext")
	local window = PlayerGui:FindFirstChild("Window")
	local gameFrame = window and window:FindFirstChild("Game")
	local fields = gameFrame and gameFrame:FindFirstChild("Fields")
	if not (context and fields) then
		return false
	end

	local localField = pickLocalField(fields)
	local inner = localField and localField:FindFirstChild("Inner")
	if not inner then
		return false
	end

	st.SpecialNotes.Normal = {}
	table.clear(ActiveNormalShapes)
	table.clear(NormalTintKnown)
	local IncomingNotes = {}
	for i = 1, 12 do
		local Holder = inner:FindFirstChild("Lane" .. i)
		local action = context:FindFirstChild("Lane" .. i)
		local notes = Holder and Holder:FindFirstChild("Notes")
		if Holder and action and notes then
			for _, child in ipairs(Holder:GetChildren()) do
				if child ~= notes and child:IsA("GuiObject") then
					local sprite = child.Name == "LayeredSprite" and child or child:FindFirstChild("LayeredSprite", true)
					if sprite then
						learnNormal(sprite)
						local pending = false
						local generation = st.SongGeneration
						local function changed()
							if pending then return end
							pending = true
							task.delay(0.15, function()
								pending = false
								if st.alive and generation == st.SongGeneration and sprite.Parent then learnNormal(sprite) end
							end)
						end
						local function watch(obj)
							if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
								connections:add(obj:GetPropertyChangedSignal("Image"), changed)
								connections:add(obj:GetPropertyChangedSignal("ImageColor3"), changed)
							end
						end
						for _, obj in ipairs(sprite:QueryDescendants("ImageLabel, ImageButton")) do watch(obj) end
						connections:add(sprite.DescendantAdded, function(obj) watch(obj) changed() end)
					end
				end
			end
			st.Session[Holder.Name] = action
			IncomingNotes[#IncomingNotes + 1] = {
				Holder = Holder,
				Notes = notes
			}
		end
	end

	local AutoCtx = {
		generation = st.SongGeneration,
		offsetMs = st.off,
		baseOffset = st.baseMs / 1000,
		tapMs = st.tapMs,
		relMs = st.relMs,
		holdTick = st.holdTick,
		maxHold = st.maxHold,
		laneDown = st.laneDown,
		laneCount = st.laneCount,
		press = pressLane,
		release = releaseLane
	}

	for _, entry in IncomingNotes do
		local Holder = entry.Holder
		local Notes = entry.Notes
		connections:add(Notes.ChildAdded, function(Arrow)
			st.NextVisualId += 1
			st.VisualNoteIds[Arrow] = st.NextVisualId
			task.defer(function()
				if not Arrow or not Arrow.Visible then
					return
				end
				if not st.auto then
					return
				end
				if math.random(1, 10000) > math.floor(math.clamp(st.accuracy, 0, 100) * 100) then
					return
				end
				local keyCode = st.Session[Holder.Name]
				if not keyCode then
					return
				end
				AutoCtx.offsetMs = st.off
				AutoCtx.baseOffset = st.baseMs / 1000
				AutoCtx.tapMs = st.tapMs
				AutoCtx.relMs = st.relMs
				AutoCtx.holdTick = st.holdTick
				AutoCtx.maxHold = st.maxHold
				playSeq(Holder, Arrow, keyCode, AutoCtx)
			end)
		end)
	end

	st.boundWindow = window
	return #IncomingNotes > 0
end

local function fieldWatch()
	if not st.alive then
		return
	end

	local window = PlayerGui:FindFirstChild("Window")
	local context = PlayerGui:FindFirstChild("VSRGContext")

	if window ~= st.boundWindow then
		st.boundWindow = window
		if window and context then
			task.defer(bindSong)
		else
			releaseAll()
			if st.NoteBridge and st.NoteBridge:GetAttribute("Status") == "Unavailable" then
				task.defer(captureVisualFallback)
			end
		end
	elseif window and context and next(st.Session) == nil then
		task.defer(bindSong)
	end

	if not st.auto then
		releaseAll()
	end
end

function st:Unload()
	if not self.alive then
		return
	end
	self.alive = false
	self.auto = false
	self.SongGeneration += 1
	if self.NoteBridge then
		self.NoteBridge:SetAttribute("Active", false)
		self.NoteBridge:Destroy()
		self.NoteBridge = nil
	end
	releaseAll()
	connections:disconnect()
	if self.FieldWatch then
		pcall(function()
			self.FieldWatch:Disconnect()
		end)
		self.FieldWatch = nil
	end
	if self.ConfigWatch then
		pcall(function()
			self.ConfigWatch:Disconnect()
		end)
		self.ConfigWatch = nil
	end
	if self.SpecialPageWatch then
		pcall(function()
			self.SpecialPageWatch:Disconnect()
		end)
		self.SpecialPageWatch = nil
	end
	for _, conn in ipairs(self.VisualConnections) do conn:Disconnect() end
	table.clear(self.VisualConnections)
	for _, binding in pairs(self.ScriptBindings or {}) do
		if binding and binding.Parent then
			pcall(function()
				binding:Destroy()
			end)
		end
	end
	table.clear(self.ScriptBindings)
	if self.RayfieldWindow and not self.RayfieldWindow.unloaded then
		pcall(function()
			self.RayfieldWindow:Unload()
		end)
	end
	self.RayfieldWindow = nil
	if ENV.__FunkyFridayAutoplayer == self then
		ENV.__FunkyFridayAutoplayer = nil
	end
end

local Rayfield = loadstring(game:HttpGet("https://sirius.menu/gen2"))()

local Window = Rayfield:CreateWindow({
	name = "Funky Friday Autoplayer",
	subtitle = "Rayfield Gen2",
	sidebarLayout = true,
	showName = "Funky Friday",
	showIcon = 0,
	configuration = {
		autoSave = true,
		autoLoad = true,
		fileName = "FunkyFridayAutoplayer",
	}
})
st.RayfieldWindow = Window

local Main = Window:CreateTab({
	name = "Autoplayer"
})

local Grid = Main:CreateGroup()
local Controls = Grid:CreateGroup({ direction = "column" })
local Runtime = Grid:CreateGroup({ direction = "column" })

Controls:CreateSection({ name = "Playback" })

Controls:CreateToggle({
	name = "Autoplay",
	flag = "FF_Autoplay",
	value = true,
	callback = function(value)
		st.auto = value
		if not value then
			releaseAll()
		end
	end
})

if #InputModes > 1 then
	local InputModeDropdown = Controls:CreateDropdown({
		name = "Input Mode",
		flag = "FF_InputMode",
		options = InputModes,
		value = DefaultInputMode,
		forgetState = true,
		multiSelect = false,
		callback = function(value)
			releaseAll()
			if table.find(InputModes, value) then
				st.inMode = value
			else
				st.inMode = DefaultInputMode
			end
		end
	})

	if type(InputModeDropdown) == "table" then
		InputModeDropdown._bringIntoView = function(self)
			local page = self.main and self.main:FindFirstAncestorWhichIsA("ScrollingFrame")
			if not page then
				return
			end

			local view = page.AbsoluteWindowSize
			local at = page.CanvasPosition
			local pageAt = page.AbsolutePosition
			local cardAt = self.main.AbsolutePosition
			if view.Y <= 0 then
				return
			end

			local top = cardAt.Y - pageAt.Y + at.Y
			local bottom = top + self:_openHeight()
			local overflow = bottom - (at.Y + view.Y)
			if overflow <= 0 then
				return
			end

			local target = math.min(at.Y + overflow + 8, top)
			game:GetService("TweenService"):Create(
				page,
				TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
				{ CanvasPosition = Vector2.new(at.X, target) }
			):Play()
		end
	end
end

if IsDesktop then
	Controls:CreateText({
		name = "PC Warning",
		text = "Funky Friday stops reading gameplay inputs whenever Roblox loses focus. If you tab out or click another window, the autoplayer won’t work until Roblox is focused again."
	})
end

if IsExternal then
	Controls:CreateText({
		name = "External Executor",
		text = "Some executor-only input methods aren’t available here, so the autoplayer only shows the input modes this executor can actually use."
	})
end

Controls:CreateSlider({
	name = "Hit Accuracy",
	flag = "FF_Accuracy",
	range = { 0, 100 },
	increment = 1,
	value = 100,
	suffix = "%",
	callback = function(value)
		st.accuracy = math.clamp(tonumber(value) or 100, 0, 100)
	end
})

Controls:CreateSlider({
	name = "Timing Offset",
	flag = "FF_TimingOffset",
	range = { -100, 100 },
	increment = 1,
	value = 0,
	suffix = "ms",
	callback = function(value)
		st.off = tonumber(value) or 0
	end
})

Controls:CreateSlider({
	name = "Spawn-to-Hit Delay",
	flag = "FF_BaseDelay",
	range = { 150, 320 },
	increment = 1,
	value = 230,
	suffix = "ms",
	callback = function(value)
		st.baseMs = math.clamp(tonumber(value) or 230, 100, 500)
	end
})

Controls:CreateSlider({
	name = "Tap Hold Time",
	flag = "FF_TapMs",
	range = { 5, 100 },
	increment = 1,
	value = 35,
	suffix = "ms",
	callback = function(value)
		st.tapMs = math.clamp(tonumber(value) or 35, 5, 250)
	end
})

Runtime:CreateSection({ name = "Runtime" })

Runtime:CreateButton({
	name = "Refresh Note Detection",
	callback = function()
		task.defer(captureVisualFallback)
	end
})

Runtime:CreateButton({
	name = "Rebind Song",
	callback = function()
		task.defer(bindSong)
	end
})

Runtime:CreateButton({
	name = "Unload",
	callback = function()
		st:Unload()
	end
})

connections:add(UserInputService.InputBegan, function(input, gameProcessed)
	if gameProcessed or input.KeyCode ~= Enum.KeyCode.RightControl then
		return
	end
	if st.RayfieldWindow and not st.RayfieldWindow.unloaded then
		st.RayfieldWindow:ToggleHide()
	end
end)

startNoteMetadata()

local specialUi = getSpecialSettingsUi()
local visualVersion = 0
local function visualDirty()
	visualVersion += 1
	local version = visualVersion
	task.delay(0.2, function()
		if st.alive and version == visualVersion and not st.SpecialNotes.Refreshing then
			refreshSpecialNoteSkins()
		end
	end)
end
local function watchImage(obj)
	if not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) or st.VisualSeen[obj] then return end
	st.VisualSeen[obj] = true
	for _, property in ipairs({"Image", "ImageColor3", "ImageRectOffset", "ImageRectSize", "Visible"}) do
		st.VisualConnections[#st.VisualConnections + 1] = obj:GetPropertyChangedSignal(property):Connect(visualDirty)
	end
	visualDirty()
end
if specialUi.Title then
	st.ConfigWatch = specialUi.Title:GetPropertyChangedSignal("Text"):Connect(visualDirty)
end
if specialUi.NotesPage then
	st.SpecialPageWatch = specialUi.NotesPage:GetPropertyChangedSignal("Visible"):Connect(visualDirty)
end
if specialUi.Preview then
	for _, obj in ipairs(specialUi.Preview:QueryDescendants("ImageLabel, ImageButton")) do watchImage(obj) end
	st.VisualConnections[#st.VisualConnections + 1] = specialUi.Preview.DescendantAdded:Connect(watchImage)
end
if specialUi.Colors then
	for _, obj in ipairs(specialUi.Colors:QueryDescendants("TextBox")) do
		st.VisualConnections[#st.VisualConnections + 1] = obj:GetPropertyChangedSignal("Text"):Connect(visualDirty)
	end
end
task.defer(refreshSpecialNoteSkins)

bindSong()
st.FieldWatch = RunService.Heartbeat:Connect(fieldWatch)

Window:Notify({
	title = "Funky Friday Autoplayer",
	content = IsExternal and "External executor support loaded." or "Autoplayer loaded.",
	duration = 4
})
