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
Map = require "ranalib_map" -- DELETE
-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

--
local memory = {}
local ore_color, destX, destY, group, returningHome, stepCounter, STATE
local energy, MaxEnergy, P, S, I, Q
-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if sourceID ~= ID then
		if torusModul.distanceToAgent(PositionX, PositionY, sourceX, sourceY) <= I then
			if eventDescription == "explore ping" and not(returningHome) then
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
			end
		end




	end
end

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

	group = 1
	Agent.joinGroup(group)
	stepCounter = P
 	STATE = "idle"
	--local color =  --{0,255,0}local parameters = Shared.getTable("parameters")
	ore_color = Shared.getTable("ore_color")
	local color = Shared.getTable("explorer_color")
	Agent.changeColor({r=color[1], g=color[2], b=color[3]})
	returningHome = false


	say(memory[1].x .. " and " .. memory[1].y)
end



function takeStep()
	if STATE == "idle" then
		destX = Stat.randomInteger(0,ENV_WIDTH)
		destY = Stat.randomInteger(0,ENV_WIDTH)
		STATE = "move"
	elseif STATE == "move" then
		moveTo(destX, destY)
		if stepCounter >= 10 then
			--Event.emit{targetGroup=group, speed=636, description="explore ping", table={scanP=P, dest={x=destX,y=destY}}}
			STATE = "scanForOre"
		end
	elseif STATE == "scanForOre" then
		newDest = _scanForOre()
		if newDest ~= nil then
			destX = newDest[1]
			destY = newDest[2]
		else
			destX = Stat.randomInteger(0,ENV_WIDTH)
			destY = Stat.randomInteger(0,ENV_WIDTH)
		end
		stepCounter = 0
		if #memory >= S then
			STATE = "goHome"
			--say("go home")
		else
			STATE = "move"
		end
	elseif STATE == "goHome" then
		moveTo(memory[1].x, memory[1].y)
		if PositionX == memory[1].x and PositionY == memory[1].y then
			while #memory > 1 do -- DELETE!
				Map.modifyColor(memory[#memory].x, memory[#memory].y, Shared.getTable("background_color"))
				table.remove(memory,#memory)
			end
			STATE = "idle"
		end
	end

	if energy == 0 then
		--Agent.removeAgent(ID)
	end
	say(STATE)
	stepCounter = stepCounter + 1
end

function moveTo(x, y)
	torusModul.moveTorus(x, y, PositionX, PositionY , ENV_WIDTH)
	energy = energy - 1
end

function _scanForOre()
	local scanDim = P
	local oreTable = torusModul.squareSpiralTorusScanColor(P, ore_color, ENV_WIDTH)
	local orePicked = 0
	local x = 0
	local y = 0

	if oreTable ~= nil then
		for i=1, #oreTable do
			if #memory ~= S then
				table.insert(memory, {x=oreTable[orePicked+1].posX, y=oreTable[orePicked+1].posY})
				orePicked = orePicked + 1
			end

		end
		if orePicked > 0 and orePicked ~= #oreTable then
			local oreCount = 0
			for i=orePicked, #oreTable do
				x = x + oreTable[i].posX
				y = y + oreTable[i].posX
				oreCount = oreCount + 1
			end
			x = x/oreCount
			y = y/oreCount
			return {x, y}
		end

	end
	return nil
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
