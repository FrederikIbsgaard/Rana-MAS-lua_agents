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

-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"
 --
local G
local doScan = true
local sp
local standStill
local goToDest

-- EventHandler
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

	-- Change Agent color to the prey color determined in 21_master
	local color = Shared.getTable("prey_color")
	Agent.changeColor{r=color[1], g=color[2], b=color[3]}
	-- Get the grid dim
	local Grid = Shared.getTable("mapSize")
	G = Grid[1]
	standStill = false
	goToDest = {x=Stat.randomInteger(1,ENV_WIDTH),y=Stat.randomInteger(1,ENV_WIDTH)}
	sp = 3
	doScan = true
	Speed = sp
	--Collision.updatePosition(198,45)

end


function takeStep()
	if not standStill then
		-- Go to a random place on the map
		if Stat.randomInteger(1,2000) == 1 then
			goToDest.x = Stat.randomInteger(1,ENV_WIDTH)
			goToDest.y = Stat.randomInteger(1,ENV_WIDTH)
			--Moving = false
		end
		-- Stand still
		if Stat.randomInteger(1,5000) == 1 then
			--Speed = 0
			goToDest.x = PositionX
			goToDest.y = PositionY
			standStill = true
			standStillCounter = 0
		end
	else
		-- the Agents stop for a fixed program cycles.
		standStillCounter = standStillCounter + 1
		if standStillCounter > 500 then
			standStill = false
		end
	end

	if not Moving then
		Speed = sp
		-- Go though the egde if its shortere
		torusModul.moveTorus(goToDest.x, goToDest.y, G)
		--torusModul.moveTorus(100, 100, G)
		Move.to({x=DestinationX,y=DestinationY})
	end
end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
