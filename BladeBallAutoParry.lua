if not game:IsLoaded() then
	game.Loaded:Wait()
end

local cloneRef = typeof(cloneref) == "function" and cloneref or function(x)
	return x
end

local replicatedStorage = cloneRef(game:GetService("ReplicatedStorage"))
local workspaceService = cloneRef(game:GetService("Workspace"))
local inputService = cloneRef(game:GetService("UserInputService"))

local gv = getgenv()

gv.visualizer = gv.visualizer or {}

gv.visualizer.path = {
	workspace:FindFirstChild("Balls", true),
	workspace:FindFirstChild("TrainingBalls", true)
}

local hash = "5455ef47-de02-4074-808c-8d82c2cd12ec"

local net = replicatedStorage
	and replicatedStorage:FindFirstChild("Packages")
	and replicatedStorage.Packages:FindFirstChild("_Index")
	and replicatedStorage.Packages._Index:FindFirstChild("sleitnick_net@0.1.0")

net = net and net:FindFirstChild("net")

local base

if net then
	if typeof(net.QueryDescendants) == "function" then
		for _, inst in net:QueryDescendants("RemoteEvent") do
			base = inst
			break
		end
	else
		for _, inst in net:GetDescendants() do
			if inst:IsA("RemoteEvent") then
				base = inst
				break
			end
		end
	end
end

if base and typeof(hookfunction) == "function" then
	local remote
	local session
	local key

	local arg4 = 0.5
	local arg8 = false

	local function keyFromToken(token, serverTick)
		local tickText = tostring(serverTick)

		if typeof(token) ~= "string" or #tickText ~= #token then
			return nil
		end

		local out = table.create(#tickText)

		for i = 1, #tickText do
			out[i] = string.char(
				bit32.bxor(
					string.byte(token, i),
					(string.byte(tickText, i) + i) % 256
				)
			)
		end

		return table.concat(out)
	end

	local function solveKey(token, capturedTick)
		if typeof(session) ~= "string" or session == "" then
			return nil
		end

		local period = #session

		for delta = -30, 30 do
			local candidate = keyFromToken(
				token,
				capturedTick + delta
			)

			if candidate and #candidate >= period * 2 then
				local valid = true

				for i = 1, #candidate do
					if string.byte(candidate, i) ~= string.byte(
						candidate,
						((i - 1) % period) + 1
					) then
						valid = false
						break
					end
				end

				if valid then
					return string.sub(candidate, 1, period)
				end
			end
		end

		return nil
	end

	local function makeToken()
		if not key then
			return nil
		end

		local serverTick = tostring(
			math.floor(
				workspaceService:GetServerTimeNow() * 100
			)
		)

		local out = table.create(#serverTick)

		for i = 1, #serverTick do
			local k = string.byte(
				key,
				((i - 1) % #key) + 1
			)

			out[i] = string.char(
				bit32.bxor(
					(string.byte(serverTick, i) + i) % 256,
					k
				)
			)
		end

		return table.concat(out)
	end

	local function targets()
		local result = {}

		local alive = workspaceService:FindFirstChild("Alive")
		local camera = workspaceService.CurrentCamera

		if not alive or not camera then
			return result
		end

		for _, model in alive:GetChildren() do
			local root = model:FindFirstChild("HumanoidRootPart")

			if root then
				result[model.Name] =
					camera:WorldToScreenPoint(root.Position)
			end
		end

		return result
	end

	local function mousePosition()
		local camera = workspaceService.CurrentCamera

		if not camera then
			return {0, 0}
		end

		if inputService then
			local kind = inputService:GetLastInputType()

			if kind == Enum.UserInputType.MouseButton1
				or kind == Enum.UserInputType.MouseButton2
				or kind == Enum.UserInputType.Keyboard
			then
				local pos = inputService:GetMouseLocation()

				return {
					pos.X,
					pos.Y
				}
			end
		end

		return {
			camera.ViewportSize.X / 2,
			camera.ViewportSize.Y / 2
		}
	end

	local function remoteArgs()
		if not (
			remote
			and remote.Parent
			and session
			and key
		) then
			return nil
		end

		local camera = workspaceService.CurrentCamera
		local token = makeToken()

		if not camera or not token then
			return nil
		end

		return table.pack(
			hash,
			session,
			token,
			arg4,
			camera.CFrame,
			targets(),
			mousePosition(),
			arg8
		)
	end

	local function publish()
		if remote
			and remote.Parent
			and session
			and key
		then
			gv.visualizer.remote = remote
			gv.visualizer.remoteArgs = remoteArgs
		end
	end

	local oldFire

	oldFire = hookfunction(
		base.FireServer,
		function(self, ...)
			local args = table.pack(...)

			if args.n == 8 and args[1] == hash then
				local callerOwned =
					typeof(checkcaller) == "function"
					and checkcaller()

				local changed =
					self ~= remote
					or args[2] ~= session

				if not callerOwned or changed then
					if changed then
						remote = self
						session = args[2]

						arg4 = args[4]
						arg8 = args[8]

						key = nil
					end

					if self == remote
						and args[2] == session
						and not key
					then
						key = solveKey(
							args[3],
							math.floor(
								workspaceService:GetServerTimeNow()
									* 100
							)
						)

						if key then
							publish()
						end
					end
				end
			end

			return oldFire(self, ...)
		end
	)
end

loadstring(
	game:HttpGet(
		"https://raw.githubusercontent.com/ltseverydayyou/uuuuuuu/refs/heads/main/AutoParry.lua"
	)
)()