--// Services 
local UserInputService = game:GetService("UserInputService")
local TweenService =  game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--Waiting cuz roblox replicating is server > client
local Animations = ReplicatedStorage:WaitForChild("Animations")
local Modules = ReplicatedStorage:WaitForChild("Modules")

local ExplosionEffect = ReplicatedStorage:WaitForChild("Explosion")
local LightLeg = ReplicatedStorage:WaitForChild("LightLeg")

local Camera = workspace:WaitForChild("Camera")

--Imports
local CameraShake = require(Modules.CameraShaker)
local Types = require(Modules.Types)

--Getting animations from replicated storage
local Throw = Animations.Throw
local Hold = Animations.Hold

--Creating connection variable for disconnect it later
local connection
--Debounce for cooldown
local debounce = false

--Player
local Player = Players.LocalPlayer
--waiting for character to appear
local character: Types.Character = Player.Character or Player.CharacterAdded:Wait()

local CachePart = {}

--Custom debris system, better than default roblox cuz take less memory 
function CachePart:Debris(_time: number , object: BasePart)
	--if time is didnt supplied then set it to 1
	if not _time then _time = 1 end
	--if theres no object then it will throw error so make sure to object exist 
	if not object or not object:IsA("BasePart") then return end

    --task delay prevents to main thread to stop 
	task.delay(_time,function()
		object:Destroy()
	end)	
end

--Main crater function for handling the rocks, cache, despawn time and etc
local function Createcrater(Data: Types.RocksData)
	--Making variabls for clear so we dont type Data.AmountPerStud it will make code more clear
	local AmountPerStud = Data.AmountPerStud 

	local AmountOfParts = Data.AmountOfParts
	local Radius = Data.Radius

	local Size = Data.Size
	local Offset = Data.Offset
	local AngleOfParts = Data.AngleOfParts 

	local DespawnTime = Data.DespawnTime 

	local Position = Data.Position
	-- If we didnt have position then we return cuz no where to spawn and it will cause error if we didnt return
	if not Position then return end

	local Orientation = 0

	--Creating the folder to make things clear
	local Folder = Instance.new('Folder')
	Folder.Name = 'RockFolder'
	Folder.Parent = workspace.Effects
	--Folder will delete after 3 seconds this better than delete parts separately
	CachePart:Debris(DespawnTime + 3, Folder)
	
	--if folder is not parented then return lol
	if not Folder.Parent then return end
	

	-- This ensures the loop runs exactly AmountOfParts`
	for x = 1, AmountOfParts do
		
		-- AmountPerStud determines how many rocks are created per unit allowing for control over density and spread
		for i = 1, AmountPerStud do
			--Generates a random radius within the given range 
			local NewRadius = Random.new():NextNumber(Radius[1], Radius[2]) 
			--This ensures that the spawned objects are distributed in a circular pattern 
			local NewCFrame = CFrame.new(Position) * CFrame.fromEulerAnglesXYZ(0, math.rad(Orientation), 0) * CFrame.new(NewRadius, 0, NewRadius) 

			--Creates a new part and sets its physical properties
			local Part = Instance.new('Part')
			Part.Anchored = true
			Part.CanCollide = true
			Part.Massless = true

			Part.CanTouch = false
			Part.CastShadow = false
			Part.CanQuery = false

			Part.CFrame = NewCFrame
			Part.Parent = Folder

			--Raycast for detecting where we collided so we need this 
			local Raycast = workspace:Raycast(Part.Position, -Vector3.yAxis * 10)

			--If raycast returned the result then we going to implement the rocks
			if Raycast then
				--Getting Position thats raycast returned in varaible
				local ResultPosition = Raycast.Position
				--Getting the object that raycast collided with
				local Object = Raycast.Instance

				--Calculate the final CFrame for the parts
				local EndFrame = CFrame.lookAt(
					Vector3.new(
						NewCFrame.Position.X,
						ResultPosition.Y - Offset.Y, 
						NewCFrame.Position.Z
					),
					Vector3.new(
						Position.X,	
						ResultPosition.Y,
						Position.Z
					)
				)

				--Applying the CFrame to the part
				Part.CFrame = EndFrame * CFrame.new(0, -4, 0)

				--Set the part properties
				Part.Material = Object.Material
				Part.Color = Object.Color
				Part.Transparency = Object.Transparency

				Part.Size = Vector3.zero

				--Adding more angles
				Part.CFrame *= CFrame.fromEulerAnglesXYZ(
					--random x angle (turn forward-back)
					math.rad(math.random(-10, 10) / 20),
					--random y angle (turn around its axis)
					math.rad(Orientation + (math.random(-200, 200) / 20)),
					--random z angle (turn left-right)
					math.rad(math.random(-10, 10) / 20)
				)

				--Making smooth animation for size and angles  Why thats need? cuz i want smooth animation so it will be cool
					TweenService:Create(Part, TweenInfo.new(0.1), {
						--Size its Vector.new(1,1,1) mult to random size minimum and to size max (Tweening from 1,1,1 to more so it will smooth)
						Size = Vector3.one * math.random(Size[1] , Size[2]),
					--Multing the EndCFrame to random x angle (The result is a slightly randomized rotation of the part and smooth animation)
						CFrame = EndFrame * CFrame.Angles(math.rad( -math.random(AngleOfParts[1], AngleOfParts[2]) ), 0, 0),
					}):Play()


				--When timeout then
				task.delay(DespawnTime, function()
					--Waiting a bit there so small amout of waitng like 0.04
					task.wait((i / AmountOfParts) / 25)

					--Tween size to small (to 20% of original size )
					TweenService:Create(Part, TweenInfo.new(1, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {
						Size = Part.Size * 0.2,
					}):Play()

					--Parts going invisible loool (no what to explain there basic)
					TweenService:Create(Part, TweenInfo.new(0.6, Enum.EasingStyle.Cubic, Enum.EasingDirection.InOut), {
						Transparency = 1
					}):Play()

					--Rocks going down tween (too no what to explain)
					 TweenService:Create(Part, TweenInfo.new(1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {
						CFrame = EndFrame * CFrame.new(0, -4, 0),
					}):Play()

                
				end)

			else
				--Destroying if no raycast result :(
				Part:Destroy()
			end
		end

		--used to evenly distribute parts 
		Orientation += 360 / AmountOfParts
	end
end


-- Removes all constraints (AlignPosition, AlignOrientation, etc.) from the player's HumanoidRootPart.
-- if we didnt remove it then player will stuck in one position
local function DestroyAllConstaints()
	for _, values: Constraint in character.HumanoidRootPart:GetChildren() do
		--If values is not a Class Constraint then we didnt want it to destroy
		if values:IsA("Constraint") then
			values:Destroy()
		end
	end
end

--Stoping animation by name
local function StopAnimation(Humanoid: Humanoid & {Animator: Animator},Animation: string)
	for _, animations: AnimationTrack in Humanoid.Animator:GetPlayingAnimationTracks() do
		if animations.Name == Animation then
			animations:Stop() -- Stop the animation if it matches the given name
		end
	end
end

--Emit effect by provided attachment. Why i make it function? (for clear code and better readbility)
local function Emit(EmitCount: number,Attachment: Attachment)
	for _, Effects: ParticleEmitter in Attachment:GetChildren() do
		--if its not particleemitter then we pass current iteration
		if not Effects:IsA("ParticleEmitter") then continue end
		--Emiting how much as argument have (no else to explain)
		Effects:Emit(EmitCount)
	end
end

--Detecting any Input began
UserInputService.InputBegan:Connect(function(UserKey,IsTyping)
	--If is typing in chat then we maybe dont want to cast the skill
	if IsTyping then return end

	--If KeyCode is r then we start the skill and if debounce is false
	if UserKey.KeyCode == Enum.KeyCode.R and not debounce then
		
		--Why i use attachment? cuz it follow the player leg when he move
	    --Cloning the attachment
		local LightLegClone = LightLeg.Attachment:Clone()
		--Parent to leftleg 
		LightLegClone.Parent = character["Left Leg"]

		--Getting player mouse
		local PlayerMouse = Player:GetMouse()
		
		--Loading Animation to an animator cuz Humanoid:LoadAnimation its deprecated
		local HoldTrack: AnimationTrack = character.Humanoid.Animator:LoadAnimation(Hold)
		HoldTrack:Play()
		
		--Freezee the character cuz if he use on ground he can jump
		character.Humanoid.WalkSpeed = 0
		character.Humanoid.JumpPower = 0

		--Creating constraints for follow the mouse 
		local AlignPosition = Instance.new("AlignPosition")
		local AlignOrientation = Instance.new("AlignOrientation")
		local Attachment = Instance.new("Attachment")

        --Setting up so it will be used correctly
		Attachment.Parent = character.HumanoidRootPart
		AlignPosition.Parent = character.HumanoidRootPart

		AlignPosition.Mode = Enum.PositionAlignmentMode.OneAttachment	
		AlignPosition.Position = character.HumanoidRootPart.Position
		AlignPosition.Responsiveness = 15000
		AlignPosition.Attachment0 = Attachment

		AlignOrientation.Parent = character.HumanoidRootPart
		AlignOrientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
		AlignOrientation.MaxTorque = 8000000
		AlignOrientation.Responsiveness = 15000
		AlignOrientation.Attachment0 = Attachment

		--Making connection so we can disconnet it later
		connection = RunService.Heartbeat:Connect(function(dt)
			--AlignOrienation is constraint that changes orienation so we use this for chacter follow the mouse
			local Hit = PlayerMouse.Hit
			AlignOrientation.CFrame = Hit
		end)
	end
end)

--Detect all end input
UserInputService.InputEnded:Connect(function(Userkey: InputObject,IsTyping: boolean)
	--If is typing in chat then we maybe dont want to cast the skill
	if IsTyping then return end

	if Userkey.KeyCode == Enum.KeyCode.R and not debounce then
		--Set debounce to true so code block doesnt reach here
		debounce = true
		--Getting player mouse
		local PlayerMouse = Player:GetMouse()
		--Getting mouse collide location
		local MouseLocation = PlayerMouse.Hit.Position
		--Stopping animation so it will didnt blended and it infinite
		StopAnimation(character.Humanoid,"Hold")
		
		--Creating variable cuz it will be more clear at code
		local EffectExist =  character["Left Leg"]:FindFirstChild("Attachment")
		
		--Loading Animation to an animator cuz Humanoid:LoadAnimation its deprecated
		local ThrowTrack: AnimationTrack = character.Humanoid.Animator:LoadAnimation(Throw)
		ThrowTrack:Play()

		--Creating raycast params
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = {workspace.Map:GetDescendants()}

		local ray = workspace:Raycast(MouseLocation + Vector3.new(0,2,0),-Vector3.yAxis * 13,params)
		--if theres no raycast result then return and destroyall bodymovers so player doesnt stuck
		if not ray then 
			DestroyAllConstaints()
			--debounce set to false cuz ability will not work anymore
			debounce = false
			--unfreeze the character
			character.Humanoid.WalkSpeed = 16
			character.Humanoid.JumpPower = 50
			--Sometimes there error cause with destroy its due to when player fast press and endpress so we need to check if there effect (Ah i hate that part cuz its not readbility)
			if EffectExist then
				EffectExist:Destroy()
			end
			return  
		end
		
			--Waiting to match the timing of animation
		   task.delay(0.1,function()
			
			--Sometimes there error cause with destroy its due to when player fast press and endpress so we need to check if there effect (Ah i hate that part cuz its not readbility)
			if EffectExist then
				EffectExist:Destroy()
			end
			
			--Create creater (no more to explain)
			Createcrater({Position = ray.Position + Vector3.new(0,3,0), 
				AmountPerStud = 3, 

				AmountOfParts = 32, 

				AngleOfParts = {10, 30}, 
				Radius = {6, 9},
				Size = {1.5, 2},

				Offset = {
					X = 0,
					Y = 0.5,
					Z = 0,
				},

				DespawnTime = 2, 
			})
			
			--Creating Overlap params
			local Overlapparams = OverlapParams.new()
		    --Set the filter type to exclude 
			Overlapparams.FilterType = Enum.RaycastFilterType.Exclude
			--character and map will be excluded 
			Overlapparams.FilterDescendantsInstances = {character,workspace.Map}
			
			--Getting cframe from ray position and with lookvector, Why i use LookVector? (Cuz i use that to transform cframe to vector lol)
			local DesiredCFrame = CFrame.new(ray.Position, ray.Position + CFrame.new(MouseLocation + Vector3.new(0,5,0), -Vector3.yAxis * 13).LookVector)
			
			local Hitlist = {}
			
			--Gettng parts in the desiredCFrame and with seted size and overlap params. Why i use this instead GetPartsInPart?, 1. I dont need to create part it will do this automatic. 
			--2. it has more perfomance than GetPartsInPart (from docs)
			local GetPartsInPart = workspace:GetPartBoundsInBox(DesiredCFrame,Vector3.new(15,6,15),Overlapparams)
		
		    -- Checking if something inside table 
			if #GetPartsInPart ~= 0 then
				--Pass through table
				for _, parts: BasePart in GetPartsInPart do
					--Getting Model by FindFirstAncestorOfClass cuz its better than spam Parent.Parent, Why i use or parts.Parent? cuz sometimes it didnt find the character model and return nil
					local Enemycharacter: Types.Character = parts:FindFirstAncestorOfClass("Model") or parts.Parent
					--Getting humanoid  from enemycharacter so it will make code clear (theres no way to explain)
					local EnemyHumanoid = Enemycharacter:FindFirstChildOfClass("Humanoid")
					
					--Checking if EnemyHumanoid exist and if its not in table so we dont damage multyply time (like when 7 parts detected we damage 7 times)
					if EnemyHumanoid and not table.find(Hitlist,EnemyHumanoid) then
						--Inserting to table for if statment working
						table.insert(Hitlist,EnemyHumanoid)
						--Damage to humanoid
						EnemyHumanoid:TakeDamage(25)
					end
				end
			end
			

			--Cloning vfx part
			local CloneExplosion = ExplosionEffect:Clone()
			--Position a bit up cuz it a bit down so we match rock vfx
			CloneExplosion.Position = ray.Position + Vector3.new(0,3,0)
			CloneExplosion.Parent = workspace

			--Emiting the effects
			Emit(1,CloneExplosion.P2)

			--camerashake init
			local camShake = CameraShake.new(Enum.RenderPriority.Camera.Value, function(shakeCFrame)
				Camera.CFrame = Camera.CFrame * shakeCFrame
			end)

			--Starting the camshake
			camShake:Start()

			-- Shaking 
			camShake:ShakeOnce(3,4,.3,.4)

			--Creating tween for smooth PointLight going Brighness go to 0 (THIS IS SO SICK!)
			TweenService:Create(CloneExplosion.P2.PointLight,TweenInfo.new(1,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),{Brightness = 0}):Play()

            --adding to custom debris system so it will cleanup after 2 seconds (theres no what to explain else!!!)
			CachePart:Debris(2,CloneExplosion)
		   end)

           
		ThrowTrack.Ended:Connect(function()
			--Cleaning up constraints 
			DestroyAllConstaints()
			--set humanoid walkspeed and jumppower back cuz player need to move after skill lol
			character.Humanoid.WalkSpeed = 16
			character.Humanoid.JumpPower = 50
			--If we didnt stop then it will be buggy 
			ThrowTrack:Stop()
			--off cooldown when skill ended
			debounce = false
			--If connection exist then we disconnect and = nil if we didnt check there will be error
			if connection then
				connection:Disconnect()
				connection = nil
			end
		end)
	end
end)
