local truegear = require "truegear"

local hookIds = {}
local slotItems = {}
local isFirst = true
local bagState = false
local healthLevel = 2
local lastTimestamp = os.time()
local lastReloadTimestamp = os.time()
local lastDownReloadTimestamp = os.time()
local leftHandgun = ""
local rightHandgun = ""
local canHeartBeat = false


function split(str, sep)
	assert(type(str) == 'string' and type(sep) == 'string', 'The arguments must be <string>')
	if sep == '' then return {str} end
	
	local res, from = {}, 1
	repeat
	  local pos = str:find(sep, from)
	  res[#res + 1] = str:sub(from, pos and pos - 1)
	  from = pos and pos + #sep
	until not from
	return res
end

function SendMessage(context)
	if context then
		print(context .. "\n")
		return
	end
	print("nil\n")
end

function PlayAngle(event,tmpAngle,tmpVertical)

	local rootObject = truegear.find_effect(event);

	local angle = (tmpAngle - 22.5 > 0) and (tmpAngle - 22.5) or (360 - tmpAngle)
	
    local horCount = math.floor(angle / 45) + 1
	local verCount = (tmpVertical > 0.1) and -4 or (tmpVertical < 0 and 8 or 0)


	for kk, track in pairs(rootObject.tracks) do
        if tostring(track.action_type) == "Shake" then
            for i = 1, #track.index do
                if verCount ~= 0 then
                    track.index[i] = track.index[i] + verCount
                end
                if horCount < 8 then
                    if track.index[i] < 50 then
                        local remainder = track.index[i] % 4
                        if horCount <= remainder then
                            track.index[i] = track.index[i] - horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] - remainder + 99 + num1
                        else
                            track.index[i] = track.index[i] + 2
                        end
                    else
                        local remainder = 3 - (track.index[i] % 4)
                        if horCount <= remainder then
                            track.index[i] = track.index[i] + horCount
                        elseif horCount <= (remainder + 4) then
                            local num1 = horCount - remainder
                            track.index[i] = track.index[i] + remainder - 99 - num1
                        else
                            track.index[i] = track.index[i] - 2
                        end
                    end
                end
            end
            if track.index then
                local filteredIndex = {}
                for _, v in pairs(track.index) do
                    if not (v < 0 or (v > 19 and v < 100) or v > 119) then
                        table.insert(filteredIndex, v)
                    end
                end
                track.index = filteredIndex
            end
        elseif tostring(track.action_type) ==  "Electrical" then
            for i = 1, #track.index do
                if horCount <= 4 then
                    track.index[i] = 0
                else
                    track.index[i] = 100
                end
            end
            if horCount == 1 or horCount == 8 or horCount == 4 or horCount == 5 then
                track.index = {0, 100}
            end
        end
    end

	truegear.play_effect_by_content(rootObject)
end

function RegisterHooks()
	if isFirst == false then
		return
	end
	isFirst = false

	for k,v in pairs(hookIds) do
		UnregisterHook("/Game/ITR/BPs/Items/Weapons/BP_FirearmItem.BP_FirearmItem_C:OnBulletFired", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:ReceiveAnyDamage", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerController.BP_PRPlayerController_C:HandHaptics", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Holders/BP_Holder_BackPack.BP_Holder_BackPack_C:SetContentVisibility", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:SetPaused", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:UpdateHealthSounds", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Weapons/BP_Knife.BP_Knife_C:BndEvt__MeleeDamageColider_K2Node_ComponentBoundEvent_0_ComponentHitSignature__DelegateSignature", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:SetUnderwaterState", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Holders/BPC_Holster.BPC_Holster_C:SetHolderVisibility", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Holders/BPC_Holster.BPC_Holster_C:OnItemTaken", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:EjectMag", k, v)
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:OnHealthEnd", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Weapons/BP_FirearmItem.BP_FirearmItem_C:IsLoadingLocked", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Weapons/BP_MagFirearmItem.BP_MagFirearmItem_C:GetChamberedAmmoTag", k, v)		
		UnregisterHook("/Game/ITR/BPs/Items/Equipment/BP_HandheldMap.BP_HandheldMap_C:OnGrip", k, v)		
		UnregisterHook("/Game/ITR/BPs/Items/Equipment/BP_HandheldMap.BP_HandheldMap_C:OnGripRelease", k, v)	
		UnregisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:ChangeHealth", k, v)
		UnregisterHook("/Game/ITR/BPs/Items/Equipment/BP_Consumable_Sweet.BP_Consumable_Sweet_C:OnGripRelease", k, v)
	end
	hookIds = {}

	local hook1, hook2 = RegisterHook("/Game/ITR/BPs/Items/Weapons/BP_FirearmItem.BP_FirearmItem_C:OnBulletFired", WeaponCheck)
	local hook3, hook4 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:ReceiveAnyDamage",Damage)
	local hook5, hook6 = RegisterHook("/Game/ITR/Player/BP_PRPlayerController.BP_PRPlayerController_C:HandHaptics", HandShock)
	local hook7, hook8 = RegisterHook("/Game/ITR/BPs/Items/Holders/BP_Holder_BackPack.BP_Holder_BackPack_C:SetContentVisibility", UsedBag)
	local hook9, hook10 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:SetPaused", Paused)
	local hook11, hook12 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:UpdateHealthSounds", HealthLevel)
	local hook13, hook14 = RegisterHook("/Game/ITR/BPs/Items/Weapons/BP_Knife.BP_Knife_C:BndEvt__MeleeDamageColider_K2Node_ComponentBoundEvent_0_ComponentHitSignature__DelegateSignature", Melee)
	local hook15, hook16 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:SetUnderwaterState", UnderWater)
	local hook17, hook18 = RegisterHook("/Game/ITR/BPs/Items/BPA_BaseItem.BPA_BaseItem_C:OnAddedToHolster", OnAddedToHolster)
	local hook19, hook20 = RegisterHook("/Game/ITR/BPs/Items/Holders/BPC_Holster.BPC_Holster_C:OnItemTaken", OnRemovedFromHolster)
	local hook21, hook22 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:EjectMag", EjectMag)
	local hook23, hook24 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:OnHealthEnd", PlayerDeath)
	local hook25, hook26 = RegisterHook("/Game/ITR/BPs/Items/Weapons/BP_FirearmItem.BP_FirearmItem_C:IsLoadingLocked", AddMag)
	local hook27, hook28 = RegisterHook("/Game/ITR/BPs/Items/Weapons/BP_MagFirearmItem.BP_MagFirearmItem_C:GetChamberedAmmoTag", Chamber)
	local hook29, hook30 = RegisterHook("/Game/ITR/BPs/Items/Equipment/BP_HandheldMap.BP_HandheldMap_C:OnGrip", MapShow)
	local hook31, hook32 = RegisterHook("/Game/ITR/BPs/Items/Equipment/BP_HandheldMap.BP_HandheldMap_C:OnGripRelease", MapHide)
	local hook33, hook34 = RegisterHook("/Game/ITR/Player/BP_PRPlayerCharacter_IKv4.BP_PRPlayerCharacter_IKv4_C:ChangeHealth", ChangeHealth)
	local hook35, hook36 = RegisterHook("/Game/ITR/BPs/Items/BPA_Consumable.BPA_Consumable_C:Use", SweetOnGripRelease)

	hookIds[hook1] = hook2
	hookIds[hook3] = hook4
	hookIds[hook5] = hook6
	hookIds[hook7] = hook8
	hookIds[hook9] = hook10
	hookIds[hook11] = hook12
	hookIds[hook13] = hook14
	hookIds[hook15] = hook16
	hookIds[hook17] = hook18
	hookIds[hook19] = hook20
	hookIds[hook21] = hook22
	hookIds[hook23] = hook24
	hookIds[hook25] = hook26
	hookIds[hook27] = hook28
	hookIds[hook29] = hook30
	hookIds[hook31] = hook32
	hookIds[hook33] = hook34
	hookIds[hook35] = hook36


	SendMessage("--------------------------------")
	SendMessage("HeartBeat")
	truegear.play_effect_by_uuid("HeartBeat")
end


-- *******************************************************************
function SweetOnGripRelease(self)
	SendMessage("--------------------------------")
	SendMessage("Eating")
	truegear.play_effect_by_uuid("Eating")
	SendMessage(self:get():GetFullName())
end


function ChangeHealth(self,HealthDelta)
	if lastTimestamp ~= os.time() then
		SendMessage("--------------------------------")
		SendMessage("ChangeHealth")
		SendMessage(HealthDelta:get())
		truegear.play_effect_by_uuid("Healing")
	end
	lastTimestamp = os.time()
end

function MapHide(self)
	SendMessage("--------------------------------")
	SendMessage("ChestSlotInputItem")
	truegear.play_effect_by_uuid("ChestSlotInputItem")
end

function MapShow(self)
	SendMessage("--------------------------------")
	SendMessage("ChestSlotOutputItem")
	truegear.play_effect_by_uuid("ChestSlotOutputItem")
end

function Chamber(self,chamberedAmmoTag)

	local inventory = self:get():GetPropertyValue('inventoryItemRef')
	if inventory:IsValid() == false then 
		SendMessage("inventory is not found")
		return
	end
	local holderID = inventory:GetPropertyValue('HolderID')
	if holderID:IsValid() == false then 
		SendMessage("holderID is not found")
		return
	end
	local slotName = holderID.TagName:ToString()
	
	if slotName == "None" then
		return
	end
	if lastDownReloadTimestamp ~= os.time() and lastDownReloadTimestamp + 1 ~= os.time() then 
		if slotName == "Item.Holder.Hand.Right"  then 
			SendMessage("--------------------------------")		
			SendMessage("RightDownReload")
			truegear.play_effect_by_uuid("RightDownReload")			
			rightHandgun = self:get():GetFullName()
			if rightHandgun == leftHandgun then 
				leftHandgun = ""
			end
		elseif slotName == "Item.Holder.Hand.Left" then
			SendMessage("--------------------------------")
			SendMessage("LeftDownReload")
			truegear.play_effect_by_uuid("LeftDownReload")
			leftHandgun = self:get():GetFullName()
			if rightHandgun == leftHandgun then 
				rightHandgun = ""
			end
		end
		lastDownReloadTimestamp = os.time()
		-- sleep(10)
		SendMessage(slotName)
		SendMessage(tostring(self:get():GetFullName()))
	end
end

function AddMag(self)
	local inventory = self:get():GetPropertyValue('inventoryItemRef')
	if inventory:IsValid() == false then 
		SendMessage("inventory is not found")
		return
	end
	local holderID = inventory:GetPropertyValue('HolderID')
	if holderID:IsValid() == false then 
		SendMessage("holderID is not found")
		return
	end
	local slotName = holderID.TagName:ToString()
	
	if slotName == "None" then
		return
	end

	if lastReloadTimestamp ~= os.time() and lastReloadTimestamp + 1 ~= os.time() then
		if slotName == "Item.Holder.Hand.Right"  then 
			SendMessage("--------------------------------")
			SendMessage("RightReloadAmmo")
			truegear.play_effect_by_uuid("RightReloadAmmo")
			rightHandgun = self:get():GetFullName()
			if rightHandgun == leftHandgun then 
				rightHandgun = ""
			end
		elseif slotName == "Item.Holder.Hand.Left" then
			SendMessage("--------------------------------")
			SendMessage("LeftReloadAmmo")
			truegear.play_effect_by_uuid("LeftReloadAmmo")
			leftHandgun = self:get():GetFullName()
			if rightHandgun == leftHandgun then 
				rightHandgun = ""
			end
		end
		lastReloadTimestamp = os.time()
		SendMessage(slotName)
		SendMessage(tostring(self:get():GetFullName()))
	end	
end

function EjectMag(self,Left)
	if Left:get() == false then 
		self:get():GetPropertyValue('Children'):ForEach(function(index, elem)
			if elem:get():GetFullName() == rightHandgun then 
				SendMessage("--------------------------------")
				SendMessage("RightMagazineEjected")
				truegear.play_effect_by_uuid("RightMagazineEjected")
				lastReloadTimestamp = os.time()
			end
		end)		
	else
		self:get():GetPropertyValue('Children'):ForEach(function(index, elem)
			if elem:get():GetFullName() == leftHandgun then 
				SendMessage("--------------------------------")
				SendMessage("LeftMagazineEjected")
				truegear.play_effect_by_uuid("LeftMagazineEjected")
				lastReloadTimestamp = os.time()
			end
		end)			
	end	
end

function PlayerDeath(self)
	SendMessage("--------------------------------")
	SendMessage("PlayerDeath")
	SendMessage("StopHeartBeat")
	truegear.play_effect_by_uuid("PlayerDeath")
	canHeartBeat = false
	healthLevel = 2
end

function UnderWater(self,HeadUnderwater,BodyUnderwater)
	if HeadUnderwater == true or BodyUnderwater == true then 
		SendMessage("--------------------------------")
		SendMessage("UnderWater")
		truegear.play_effect_by_uuid("UnderWater")
		SendMessage(HeadUnderwater:get())
		SendMessage(BodyUnderwater:get())
	end	
end


function HolsterCheck(holster)
	if string.find(holster, "Probes") then
		if string.find(holster, "L") then
			return "LeftGloveSlot"
		else
			return "RightGloveSlot"
		end	
	elseif string.find(holster,"WeaponPrimary") then 
		return "BackSlot"
	else
		return "ChestSlot"
	end
end



function OnAddedToHolster(self,Holster)
	SendMessage("--------------------------------")
	local itemName = self:get():GetFullName()
	local mesh = self:get():GetPropertyValue('RootComponent')
	if mesh:IsValid() == false then 
		SendMessage("mesh is not found")
		return
	end
	local soltName = mesh:GetPropertyValue('AttachParent'):GetFullName():match("([^%.]+)$")
	slotItems[soltName] = itemName
	local holsterName = HolsterCheck(soltName)
	SendMessage(holsterName .. "InputItem")
	truegear.play_effect_by_uuid(holsterName .. "InputItem")
	SendMessage(soltName)
	SendMessage(itemName)
	SendMessage(self:get():GetClass():GetFullName())
end


function OnRemovedFromHolster(self,InventoryItem)
	local holderID = InventoryItem:get():GetPropertyValue('HolderID')
	if holderID:IsValid() == false then 
		SendMessage("holderID is not found")
		return
	end
	local slotName = holderID.TagName:ToString()
	local itemName = InventoryItem:get():GetPropertyValue('ActorReference'):GetFullName()
	
	-- SendMessage(itemName)
	local keysToDelete = ""
	for k,v in pairs(slotItems) do
		if v == itemName then
			if slotName == "Item.Holder.Hand.Right" or slotName == "Item.Holder.Hand.Left" then 
				keysToDelete = k
			end
		end
	end
	if keysToDelete == "" then
		return
	end

	SendMessage("--------------------------------")
	local holsterName = HolsterCheck(keysToDelete)
	SendMessage(holsterName .. "OutputItem")
	truegear.play_effect_by_uuid(holsterName .. "OutputItem")

	SendMessage(keysToDelete)
	SendMessage(slotItems[keysToDelete])
	slotItems[keysToDelete] = nil

	if string.find(itemName,"Weapon") then
		lastReloadTimestamp = os.time()
		lastDownReloadTimestamp = os.time()
	end

end

function Paused(self,paused)
	SendMessage("--------------------------------")
	SendMessage("paused")
	SendMessage(tostring(paused:get()))
	local isPaused = paused:get()
	if isPaused == false then
		if healthLevel == 1 then
			SendMessage("StartHeartBeat")
			canHeartBeat = true	
		end
	else
		SendMessage("StopHeartBeat")
		canHeartBeat = false
	end
end

function HealthLevel(self,healthLevel)
	SendMessage("--------------------------------")
	SendMessage("Health")	
	SendMessage(tostring(healthLevel:get()))
	healthLevel = healthLevel:get()
	if healthLevel == 1 then
		SendMessage("StartHeartBeat")
		canHeartBeat = true
	else
		SendMessage("StopHeartBeat")
		canHeartBeat = false
	end
end

function Melee(self,HitComponent,OtherActor,OtherComp,NormalImpulse,Hit)
	SendMessage("--------------------------------")
	SendMessage("Melee")
	SendMessage(self:get():GetClass():GetFullName())
	SendMessage(self:get():GetFullName())
	local meleePlayer = self:get():GetPropertyValue('Owner')
	if meleePlayer:IsValid() == false then 
		SendMessage("meleePlayer is not found")
		return
	end	
	local rightVel = meleePlayer:GetPropertyValue('RHandVel')
	local leftVel = meleePlayer:GetPropertyValue('LHandVel')
	SendMessage(rightVel)
	SendMessage(leftVel)
	if rightVel > leftVel then 
		if rightVel > 2 then 
			SendMessage("RightHandMeleeHit")
			truegear.play_effect_by_uuid("RightHandMeleeHit")
		end
	else
		if leftVel > 2 then 
			SendMessage("LeftHandMeleeHit")
			truegear.play_effect_by_uuid("LeftHandMeleeHit")
		end
	end

end


function UsedBag(self,Visible)
	local isVisible = Visible:get()	
	if isVisible == true and bagState == false then
		SendMessage("--------------------------------")
		SendMessage("BackSlotOutputItem")
		truegear.play_effect_by_uuid("BackSlotOutputItem")
		bagState = true
	elseif isVisible == false and bagState == true then
		SendMessage("--------------------------------")
		SendMessage("BackSlotInputItem")
		truegear.play_effect_by_uuid("BackSlotInputItem")
		bagState = false
	end
	SendMessage(tostring(Visible:get()))
	
end

function HandShock(Context, param1, param2)
	local isRightHand = param2:get()
	local shockType = param1:get()

	if shockType == 1 or shockType == 0 then 
		return
	end

	if isRightHand == 0 then		
		SendMessage("--------------------------------")
		SendMessage("LeftHandPickupItem")
		truegear.play_effect_by_uuid("LeftHandPickupItem")
	elseif  isRightHand == 1 then 
		SendMessage("--------------------------------")
		SendMessage("RightHandPickupItem")
		truegear.play_effect_by_uuid("RightHandPickupItem")
	end
	SendMessage(isRightHand)
	SendMessage(param1:get())
end

function Damage(self,Damage,DamageType,InstigateBy,DamageCauser)

	if self:get():GetFullName() == DamageCauser:get():GetFullName() then 
		SendMessage("--------------------------------")
		SendMessage("FallDamage")
		truegear.play_effect_by_uuid("FallDamage")
		SendMessage(DamageType:get():GetPropertyValue('DamageFalloff'))
		SendMessage(DamageCauser:get():GetFullName())
		SendMessage(DamageCauser:get():GetClass():GetFullName())
		SendMessage(self:get():GetFullName())		
		return
	end

	local enemy = DamageCauser:get():GetPropertyValue('Controller')
	if enemy:IsValid() == false then 
		SendMessage("--------------------------------")
		SendMessage("PoisonDamage")
		truegear.play_effect_by_uuid("PoisonDamage")
		SendMessage(DamageType:get():GetPropertyValue('DamageFalloff'))
		SendMessage(DamageCauser:get():GetFullName())
		SendMessage(DamageCauser:get():GetClass():GetFullName())
		SendMessage(self:get():GetFullName())
		SendMessage("enemy is not found")
		return
	end
	local enemyRotation = enemy:GetPropertyValue('ControlRotation')
	if enemyRotation:IsValid() == false then 
		SendMessage("enemyRotation is not found")
		return
	end
	
	local playerController = self:get():GetPropertyValue('Controller')
	if playerController:IsValid() == false then 
		SendMessage("playerController is not found")
		return
	end
	local playerRotation = playerController:GetPropertyValue('ControlRotation')
	if playerRotation:IsValid() == false then 
		SendMessage("playerRotation is not found")
		return
	else
		local angleYaw = playerRotation.Yaw - enemyRotation.Yaw
		angleYaw = angleYaw + 180
		if angleYaw > 360 then 
			angleYaw = angleYaw - 360
		end
		SendMessage("--------------------------------")
		SendMessage("DefaultDamage," .. angleYaw .. ",0")
		PlayAngle("DefaultDamage",angleYaw,0)
		SendMessage(DamageType:get():GetPropertyValue('DamageFalloff'))
		SendMessage(DamageCauser:get():GetFullName())
		SendMessage(DamageCauser:get():GetClass():GetFullName())
		SendMessage(self:get():GetFullName())
	end
end

function WeaponCheck(self)
	SendMessage("--------------------------------")
	
	local currWeaponClass = self:get():GetClass():GetFullName()
	local weaponName = split(currWeaponClass, "/")
	local weaponType = WeaponType(weaponName[8])

	local player = self:get():GetPropertyValue('Owner')
	if player:IsValid() == false then 
		SendMessage("player is not found")
		return
	end
	local rightAngle = player:GetPropertyValue('RightTriggerAngle')
	local leftAngle = player:GetPropertyValue('LeftTriggerAngle')
	if rightAngle >= 0.69 then 
		SendMessage("RightHand".. weaponType .."Shoot")
		truegear.play_effect_by_uuid("RightHand".. weaponType .."Shoot")
	end
	if leftAngle >= 0.69 then 
		SendMessage("LeftHand".. weaponType .."Shoot")
		truegear.play_effect_by_uuid("LeftHand".. weaponType .."Shoot")
	end
	SendMessage(self:get():GetFullName())
	SendMessage(self:get():GetClass():GetFullName())
end


function WeaponType(weapon)
	if string.find(weapon, "Shotgun") or string.find(weapon, "Saiga") or string.find(weapon, "SPAS") then
		return "Shotgun"
	end
	if string.find(weapon, "AK-74") or string.find(weapon, "M4A1") or string.find(weapon, "AUG") or string.find(weapon, "FN-17") then
		return "Rifle"
	end
	return "Pistol"
end


function HeartBeat()
	if canHeartBeat == true then
		truegear.play_effect_by_uuid("HeartBeat")
	end
end

truegear.seek_by_uuid("DefaultDamage")
truegear.init("1012790", "Into The Radius")




function RegisterGameStart()
	local ran, errorMsg = pcall(RegisterHooks)
	if ran then
		return true
	else
		print(errorMsg)
	end
	
end

LoopAsync(5000, RegisterGameStart)
LoopAsync(1000, HeartBeat)

SendMessage("TrueGear Mod is Loaded");