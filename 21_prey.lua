--
--
-- Torus implementation by Rikke Tranborg and Maria Dam
--
--

-- Import Rana lua modules.
Event = require "ranalib_event"
Stat = require "ranalib_statistic"
Collision = require "ranalib_collision"
Map = require "ranalib_map"
Agent = require "ranalib_agent"
Shared = require "ranalib_shared"
Move = require "ranalib_movement"


torusModul = require "torus_modul"
 -- Grid size
local G
local doScan = true
local sp = 3

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)
	if eventDescription == "attack" then
		--say("Prey: "..ID .." was attacked by Predator: "..sourceID .."")
		Event.emit{targetID=sourceID, speed=343, description="killed prey"}
		Agent.removeAgent(ID)
		--l_modifyMap(PositionX, PositionY, 255, 0, 0)
	end
end

function initializeAgent()
	-- Visible is the collision grid

	GridMovement = true	-- Visible is the collision grid
	GridMove = true
	say("Agent #: " .. ID .. " has been initialized")

	--Map.modifyColor(10,10,{255,255,255})
	local color = Shared.getTable("prey_color")
	Agent.changeColor{r=color[1], g=color[2], b=color[3]}
	local Grid = Shared.getTable("mapSize")
	G = Grid[1]
	Speed = 0
	--Collision.updatePosition(195,45)
end

standStill = false
gotodest = {x=Stat.randomInteger(1,ENV_WIDTH),y=Stat.randomInteger(1,ENV_WIDTH)}
function takeStep()
	dim = 1
	if true then--math.abs(PositionX - gotoX) > 2 or math.abs(PositionY - gotoY) > 2 then
		--say ("Moving: ".. 1)
		if not standStill then
			if Stat.randomInteger(1,2000) == 1 then
				gotodest.x = Stat.randomInteger(1,ENV_WIDTH)
				gotodest.y = Stat.randomInteger(1,ENV_WIDTH)
				Moving = false
			end

			if Stat.randomInteger(1,5000) == 1 then
				Speed = 0
				standStill = true
				standStillCounter = 0
			end
		else
			standStillCounter = standStillCounter + 1
			if standStillCounter > 500 then
				standStill = false
			end
		end

		if not Moving then
			--
			--Moving = true;
			Speed = sp
			torusModul.moveTorus(gotodest.x, gotodest.y, G)
			--moveTorus(50, 50)
			--say("Move to: ".. DestinationX.. " , " ..DestinationY)
			Move.to({x=DestinationX,y=DestinationY})
			--Move.to({x=50,y=50})
			Speed = sp
		end
	end
end


function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end
