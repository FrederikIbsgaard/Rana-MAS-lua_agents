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
Shared = require "ranalib_shared"
Agent = require "ranalib_agent"



-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local group, oreStorage, MaxEnergy, energy, W, P, S, I, Q, ore_color
local STATE = "NOSTATE"
local baseID
local LATCHED_STATE = "NOSTATE"
local stepCounter, complete
local stepCounterTwo = 0
local destX = Stat.randomInteger(0,ENV_WIDTH)
local destY = Stat.randomInteger(0,ENV_WIDTH)

function initializeAgent()
	GridMove = true
	oreStorage = 0
	table.insert(memory, {x=PositionX,y=PositionY})
	local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	MaxEnergy = parameters.E
	energy = MaxEnergy -- energy for robots
	W = parameters.W -- number of max ore
 	P = parameters.P -- initial perception scope
	S = parameters.S -- memory size of robots
	I = parameters.I -- fixed communication scope
	Q = parameters.Q -- cost of movemnt
	 -- transporter
	complete = false
	local color = Shared.getTable("miner_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})
	--Collision.updatePosition(100, 100)
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "AcceptGroup" and STATE == "NOSTATE" and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= 1 then
		group = eventTable.group
		Agent.joinGroup(group)
		baseID = group
		say("Miner #" ..ID .. " assigned to " .. group)
		STATE = "idle"
	end
	if sourceID ~= ID and eventTable.group == group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
		if eventDescription == "dockingAccepted" then
			oreStorage = 0
			energy = MaxEnergy

		elseif eventDescription == "dockingRefused" then
				energy = MaxEnergy
				STATE = "findNewBase"

		elseif eventDescription == "taskOffer" and STATE ~= "waitForObjective" and #memory ~= S then
			Event.emit{targetID=sourceID, speed=5000, description="taskResponse", table={capacity=S-#memory, group=group}}--(W-oreStorage)}}--, minDist=minDistance}}
			--say("miner: " .. ID .. " response to offer from: " .. sourceID .. " Free memory: " .. (S-#memory))
			LATCHED_STATE = STATE
			stepCounter = 0
			STATE = "waitForObjective"

		elseif eventDescription == "taskObjective" and STATE == "waitForObjective" then
			ores = eventTable.ores
			--say("miner: " .. ID .. " objective response from: " .. sourceID .. " objective dropped: " .. #ores-(S-#memory))
			local i = 1
			while #memory < S do
				if i > #ores then
					break
				end
				table.insert(memory, {x=ores[i].x, y=ores[i].y})
				i = i+1
			end

			STATE = LATCHED_STATE

		--elseif eventDescription == "allOreCollected" and sourceID == group then
		--	completed()
		--elseif eventDescription == "changeBaseTo" and sourceID == group then
		--	while #memory > 0 do
		--		memory[#memory] = nil
		--	end
		--	table.insert(memory, {x=eventTable.x,y=eventTable.y})
		--	Agent.joinGroup(eventTable.id)
		--	baseID = group
		--	say("Explore #" ..ID .. " assigned to " .. group)
		--	STATE = "idle"

		end
	elseif sourceID ~= ID and eventTable.group ~= group and torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
		if eventDescription == "joinBase" then
			group = eventTable.group
			memory[1].x = eventTable.basePos.x
			memory[1].y = eventTable.basePos.y
			--deloadAndRefill()
			STATE = "moveToBase"

			-- color change to see base swap
			local red = 0
			local blue = 0
			if group == 2 then
				red = 255
				blue = 0
			elseif group == 23 then
				blue = 255
				red = 0
			end
			Agent.changeColor({r=0, g=0, b=255})



		elseif eventDescription == "lookingForNewBase" then
			Event.emit{targetID=sourceID, speed=5000, description="joinBase",table={group=group,basePos={x=memory[1].x, y=memory[1].y}}}
		end
	end
end

function takeStep()
	--say("ID: " .. ID .. " STATE: " .. STATE .. " Latched State: " .. LATCHED_STATE)

	if STATE == "idle" then
		if #memory > 1  and energy == MaxEnergy then
			STATE = "moveToOre"
		end

	elseif STATE == "moveToOre" then
		--local closestIndex
		--local oreX
		--local oreY

		if closestIndex == nil then
			closestIndex = findClosestOreIndex()
			oreX = memory[closestIndex].x
			oreY = memory[closestIndex].y
		end

		moveTo(oreX, oreY)
		if atPos(oreX, oreY) then
			if atOre() then
				table.remove(memory, closestIndex)
				STATE = "pickUpOre"
			elseif not atOre() then
				table.remove(memory, closestIndex)
				if #memory == 1 then
					STATE = "moveToBase"
				end
			end
			closestIndex = nil
		end

	elseif STATE == "pickUpOre" then
		mineOre()
		if oreStorage < W and #memory > 1 then
			STATE = "moveToOre"
		elseif oreStorage == W or #memory == 1 then
			STATE = "moveToBase"
		end

	elseif STATE == "moveToBase" then
		if not atBase() then
			moveTo(memory[1].x, memory[1].y)
		else
			deloadAndRefill()
			STATE = "idle"
		end

	elseif STATE == "waitForObjective" then
		stepCounter = stepCounter + 1
		if stepCounter >= 4 then
			STATE = LATCHED_STATE
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
	end

	if energy < distToBase() + (MaxEnergy*0.1) and not (STATE == "pickUpOre" or STATE == "idle") then
		STATE = "moveToBase"
	end
	if energy <= 0 then
		Agent.removeAgent(ID)
		Map.modifyColor(PositionX, PositionY, {255,255,255})
	end
end

function mineOre()
	l_modifyMap(PositionX,PositionY, 0, 0, 0)
	oreStorage = oreStorage + 1
end

function findClosestOreIndex()
	local dist = ENV_WIDTH*1.5
	local closest = 1

	for i=2, #memory do
		local tempDist = torusModul.distanceToAgent(PositionX, PositionY, memory[i].x, memory[i].y)
		if tempDist < dist then
			dist = tempDist
			closest = i
		end
	end

	return closest
end

function distToBase()
	return torusModul.distanceToAgent(PositionX, PositionY, memory[1].x, memory[1].y)
end

function atOre()
	local r,g,b = l_checkMap(PositionX,PositionY)
	return (r == ore_color[1] and g == ore_color[2] and b == ore_color[3])
end

function atBase()
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

function atPos(x, y)
	return PositionX==x and PositionY==y
end

function deloadAndRefill()
	Event.emit{targetID=baseID, speed=5000, description="dockingRequest", table={oreCount=oreStorage, usedEnergy=MaxEnergy-energy,group=group}}
end

function colorGround() --NOT WORKING ATM
	local color = Map.checkColor(PositionX,PositionY)
	local newC = color[2] + 10
	if newC < 255 then
		l_modifyMap(PositionX,PositionY, color[1], newC, color[3])
	end
end

function moveTo(x,y)
	--colorGround()
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	energy = energy -1
end

function completed()
	STATE = "moveToBase"
	complete = true
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
