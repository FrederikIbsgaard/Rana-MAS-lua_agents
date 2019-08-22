--The following global values are set via the simulation core:
-- ------------------------------------
-- IMMUTABLES.
-- ------------------------------------
-- ID -- id of the agent.
-- STEP_RESOLUTION 	-- resolution of steps, in the simulation core.
-- EVENT_RESOLUTION	-- resolution of event distribution.
-- ENV_WIDTH -- Width of the environment in meters.
-- ENV_HEIGHT -- Height of the environment in meters.
-- ------------------------------------
-- VARIABLES.
-- ------------------------------------
-- PositionX	 	-- Agents position in the X plane.
-- PositionY	 	-- Agents position in the Y plane.
-- DestinationX 	-- Agents destination in the X plane.
-- DestinationY 	-- Agents destination in the Y plane.
-- StepMultiple 	-- Amount of steps to skip.
-- Speed 			-- Movement speed of the agent in meters pr. second.
-- Moving 			-- Denotes wether this agent is moving (default = false).
-- GridMove 		-- Is collision detection active (default = false).
-- ------------------------------------

-- Import Rana lua modules.
Event = require "ranalib_event"
Move = require "ranalib_movement"
Shared = require "ranalib_shared"
Agent = require "ranalib_agent"
Collision = require "ranalib_collision"
--Map = require "ranalib_map" -- DELETE
-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local transporterTable = {}
local ore_color, destX, destY, group, stepCounter, STATE, baseID, taskOfferState, color, complete
local energy, MaxEnergy, scanDim, P, S, I, Q
local targetMiner = nil
local STATE = "NOSTATE"
local agentColor = "green" --DELETE
local stepCounterTwo = 0
-- EventHandler


function initializeAgent()
	GridMove = true
	table.insert(memory, {x=PositionX,y=PositionY})
	local parameters = Shared.getTable("parameters")
	MaxEnergy = parameters.E -- energi for tge robot
	energy = MaxEnergy
	P = parameters.P -- initial perception scope
	S = parameters.S -- memory size of robots
	I = parameters.I -- fixed communication scope
	Q = parameters.Q -- cost of movemnt

	stepCounter = P
	taskOfferState = "emitOffer"
	complete = false
	--local color =  --{0,255,0}local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	color = Shared.getTable("explorer_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})

end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "AcceptGroup" and STATE == "NOSTATE" and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= 1 then
		group = eventTable.group
		Agent.joinGroup(group)
		baseID = group
		say("Explore #" ..ID .. " assigned to " .. group)
		STATE = "idle"
	end
	if sourceID ~= ID and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
		if  eventTable.group == group then
			if eventDescription == "explore ping"  and eventTable.group == group then
				--say(eventTable.dest.x)
				if torusModul.distanceToAgent(destX, destY, eventTable.dest.x, eventTable.dest.y) <= 100 then
					local x = Stat.randomInteger(0,ENV_WIDTH)
					local y = Stat.randomInteger(0,ENV_WIDTH)
					while torusModul.distanceToAgent(x, y, eventTable.dest.x, eventTable.dest.y) >= 100 do
						x = Stat.randomInteger(0,ENV_WIDTH)
						y = Stat.randomInteger(0,ENV_WIDTH)
					end

					destX = x
					destY = y
				end
			elseif eventDescription == "taskResponse" then
				table.insert(transporterTable, {ID=sourceID, capacity=eventTable.capacity})--, minDist=eventTable.minDist})

			elseif eventDescription == "dockingAccepted" then
				energy = MaxEnergy

			elseif eventDescription == "dockingRefused" then
					energy = MaxEnergy
					STATE = "findNewBase"

			--elseif eventDescription == "allOreCollected" and sourceID == group  then
			--	completed()
			--end
		--elseif eventDescription == "findNearestBase"  then
		--	STATE = "findNearestBase"
		--	complete = true
		--elseif eventDescription == "baseHere" and sourceID ~= group and STATE == "findNearestBase" and #memory == 1 then
		--	STATE = "foundBase"
		--	table.insert(memory, {x=sourceX,y=sourceY,id=sourceID})
		--	say("Base Found")
		--elseif eventDescription == "changeBaseTo" and sourceID == group then
		--	while #memory > 0 do
		--		memory[#memory] = nil
		--	end
		--	table.insert(memory, {x=eventTable.x,y=eventTable.y})
		--	Agent.joinGroup(eventTable.id)
		--	baseID = group
		--	say("Explore #" ..ID .. " assigned to " .. group)
				--STATE = "idle"
			end
		elseif eventTable.group ~= group then
			if eventDescription == "joinBase" then
					baseID = eventTable.baseID
					group = eventTable.group
					local newBase = eventTable.basePos
					while #memory > 0 do
						memory [#memory] = nil
					end
					table.insert(memory, {x=newBase.x, y=newBase.y})
					--Event.emit{targetID=baseID, speed=5000, description="dockingRequest", table={oreCount=oreStorage, usedEnergy=MaxEnergy-energy,group=group}}
					STATE = "moveToBase"

						-- color change to see base swap
					Agent.changeColor({r=255, g=0, b=0})



			elseif eventDescription == "lookingForNewBase" then
				Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group, baseID=baseID, basePos={x=memory[1].x, y=memory[1].y}}}
			end
		end
	end
end

function takeStep()
	--say("EXPLORER: " .. STATE)
	if STATE == "idle" then
		destX = Stat.randomInteger(0,ENV_WIDTH)
		destY = Stat.randomInteger(0,ENV_WIDTH)
		STATE = "move"
		stepCounter = P
	elseif STATE == "move" then
		moveTo(destX, destY)

		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)

		end
		--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
		if stepCounter >= P then
			--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
			STATE = "scanForOre"
		end
		stepCounter = stepCounter + 1
	elseif STATE == "scanForOre" then
		newDest = _scanForOre()

		--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
		if newDest ~= nil then
			destX = newDest[1]
			destY = newDest[2]
		else
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		stepCounter = 0

		if #memory >= S then
			STATE = "moveToBase"
		else
			STATE = "move"
		end
		--STATE = "32"
	elseif STATE == "moveToBase" then
		if (not atBase()) then
			destX = memory[1].x
			destY = memory[1].y
			moveTo(destX, destY)
		else
			STATE = "recharge"
		end
	elseif STATE == "recharge" then
			if energy ~= MaxEnergy then
				Event.emit{targetID=baseID, speed=0, description="dockingRequest", table={oreCount=0,usedEnergy=MaxEnergy-energy,group=group}}
				--energy = energy -1
			elseif #memory ~= 1 then
				STATE = "taskOffer"
			else
				STATE = "scanForOre"
			end

	elseif STATE == "taskOffer" then
		--say("TASK STATE: " .. taskOfferState)
		if taskOfferState == "emitOffer" then
			Event.emit{speed=5000, description="taskOffer", table={group=group}}
			--if #memory == 1 then
			--	STATE = "recharge"
			--end
			waitStepCounter = 0
			taskOfferState = "evaluateOffers"
		elseif taskOfferState == "evaluateOffers" then
			waitStepCounter = waitStepCounter + 1
			if #transporterTable > 0 and waitStepCounter >= 2 then
				local highestCap = 0
				local cap = 0
				for i=1, #transporterTable do
					cap = transporterTable[i].capacity
					if cap > highestCap then
						highestCap = cap
						targetMiner = transporterTable[i].ID
					end
				end


				while #transporterTable > 0 do
					transporterTable [#transporterTable] = nil
				end

				if targetMiner ~= nil then
					taskOfferState = "emitTasks"
				--elseif targetMiner == nil then
				--	-- FUCKING UGLY CODE, IF NO TRANSPORTER DUMP MEMORY AND MOVE ON
				--	while #memory > 1 do
				--		memory [#memory] = nil
				--	end
				--	taskOfferState = "emitOffer"
				--	STATE = "recharge"
				end
			elseif waitStepCounter == 100 and #transporterTable == 0 then
				while #memory > 1 do
					memory [#memory] = nil
				end
				taskOfferState = "emitOffer"
				STATE = "recharge"
			elseif (waitStepCounter == 20 or waitStepCounter == 40) and #transporterTable == 0 then -- QUICKFIX
				Event.emit{speed=5000, description="taskOffer", table={group=group}}
			end
		elseif taskOfferState == "emitTasks" then
			emitObjective(targetMiner)
			targetMiner = nil

			taskOfferState = "emitOffer"
			STATE = "recharge"
		end

	elseif STATE == "findNewBase" then
		moveTo(destX, destY)
		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		if stepCounterTwo >= P then--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
			STATE = "callForAgents"
		end
		stepCounterTwo = stepCounterTwo + 1
	elseif STATE == "callForAgents" then
		Event.emit{speed=5000, description="lookingForNewBase", table={group=group}}
		STATE = "findNewBase"
		stepCounterTwo = 0

	--elseif STATE == "findNearestBase" then
	--	if #memory > 1 then
	--		while #memory > 1 do
	--			memory[#memory] = nil
	--		end
	--		destX = memory[1].x
	--		destY = memory[1].y
	--	else
	--		moveTo(destX, destY)
	--		if math.abs(destX-PositionX) <= 1.1 and math.abs(destY-PositionY) <= 1.1 then
	--			destX = Stat.randomInteger(0,ENV_WIDTH)
	--			destY = Stat.randomInteger(0,ENV_WIDTH)
	--
	--		end
	--	end
	--elseif STATE == "foundBase" then
	--	if (not atBase()) then
	--		destX = memory[1].x
	--		destY = memory[1].y
	--		moveTo(destX, destY)
	--	else
	--		STATE = "recharge"
	--		Event.emit{targetID=group,destination="changebase",table={id=memory[2].id,x=memory[2].x,y=memory[2].y,group=group}}
	--	end
	end
	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "recharge" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy <= 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,255,255})
	end

end

function moveTo(x, y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	--colorGround()
	energy = energy - 1
end
function colorGround() --NOT WORKING ATM
	local color = Map.checkColor(PositionX,PositionY)
	local newR = color[1] + 10
	if newR < 255 then
		l_modifyMap(PositionX,PositionY, newR, 0, 0)
	end
end

function atBase() -- CLEAN THIS UP! MAKE THE DROP ZONE LARGER TO AVOID STUCK AGENTS
	if (PositionX==memory[1].x and PositionY==memory[1].y) or (PositionX==memory[1].x+1 and PositionY==memory[1].y) or (PositionX==memory[1].x and PositionY==memory[1].y+1) or (PositionX==memory[1].x-1 and PositionY==memory[1].y) or (PositionX==memory[1].x and PositionY==memory[1].y-1) then
		--Collision.updatePosition(memory[1].x,memory[1].y)
		return true
	elseif distToBase() <= 2 then
		Collision.updatePosition(memory[1].x,memory[1].y)
		return true
	else
		return false
	end
end

function distToBase()
	return torusModul.distanceToAgent(PositionX, PositionY, memory[1].x, memory[1].y)
end

function _scanForOre()

	--if agentColor == "green" then -- DELETE THIS IS TO SEE WHEN IT SCANS
	--	Agent.changeColor({r=255, g=0, b=0})
	--	agentColor = "red"
	--elseif agentColor == "red" then
	--	Agent.changeColor({r=0, g=255, b=0})
	--	agentColor = "green"
	--end

	local scanDim = P
	local oreTable = torusModul.squareSpiralTorusScanColor(P, ore_color, ENV_WIDTH)
	energy = energy - P
	local x = 0
	local y = 0
	if oreTable ~= nil then
		for i=1, #oreTable do
			if #memory ~= S then
				table.insert(memory, {x=oreTable[i].posX, y=oreTable[i].posY})
			end
		end
		local oreCount = #oreTable
		for i=1, #oreTable do
			x = x + oreTable[i].posX
			y = y + oreTable[i].posY
			--oreCount = oreCount + 1
		end
		x = x/oreCount
		y = y/oreCount
		return {x, y}

		--end
	end
	return nil
end

function emitObjective(minerID)
	local objectiveList = {}
	for i=2, #memory do
		table.insert(objectiveList, memory[i])
	end
	Event.emit{targetID=minerID, speed=5000, description="taskObjective", table={ores=objectiveList,group=group}}
	while #memory > 1 do
		memory [#memory] = nil
	end
end

function completed()
	STATE = "moveToBase"
	complete = true
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end


--[[local dx = math.abs(sourceX - PositionX)
local dy = math.abs(sourceY - PositionY)
local x, y, sourceScanP
x= 0
y= 0
sourceScanP = eventTable.scanP
if PositionX > sourceX then
	if PositionY > sourceY then
		x = sourceX + sourceScanP/2
		y = sourceY + sourceScanP/2
	end
	if PositionY <= sourceY then
		x = sourceX + sourceScanP/2
		y = sourceY - sourceScanP/2
	elseif math.abs(PositionX - x) < math.abs(PositionY - y) then
		destX = x + P
		destY = PositionY
	else
		destX = PositionX
		destY = y + P
	end
elseif PositionX < sourceX then
	if PositionY > sourceY then
		x = sourceX - sourceScanP/2
		y = sourceY + sourceScanP/2
	elseif PositionY <= sourceY then
		x = sourceX - sourceScanP/2
		y = sourceY - sourceScanP/2
	end

	if math.abs(PositionX - x) < math.abs(PositionY - y) then
		destX = x - P
		destY = PositionY
	else
		destX = PositionX
		destY = y - P
	end
end
say("here")
--]]
