-- Import Rana lua modules.
Event = require "ranalib_event"
Stat = require "ranalib_statistic"
Move = require "ranalib_movement"
Agent = require "ranalib_agent"
Map = require "ranalib_map"
Collision = require "ranalib_collision"

function initializeAgent()
	say("Agent #: " .. ID .. " has been initialized")
	GridMove = true
	Agent.changeColor{r=0, g=0, b=255}
end

function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

	--if eventDescription == "NAME" then
  --end
end

function takeStep()
  if not Stalking then
		if not Moving then
			--Move.toRandom()
			Move.byAngle(Stat.randomInteger(0,360))
			Speed = 1
		end
		if Stat.randomInteger(1,10000) == 1 then
			Speed = 0
			Moving = false
		end

		stalked_prey = _ScanMap(20)
		if stalked_prey then--and Map.checkColor(stalked_prey.posX, stalked_prey.posY)=={r=0, g=255, b=0} then
			Stalking = true
			--colorsss = Map.checkColor(stalked_prey.posX, stalked_prey.posY)
			--say("Color")
			--say(colorsss[1])
			--say(colorsss[2])
			--say(colorsss[3])
		end
		--local table = Collision.radialCollisionScan(20)
		--if table ~= nil then
			--for i = 1, #table do
				--Stalking = true
				--stalked_prey = table[i]
				--return
			--end
		--end

  elseif Stalking then
		Speed = 3
    if Attack then
      --Event.emit{targetID=prey.ID, speed=343, description="attack"}
    end
		stalked_prey = _ScanMap(10)
		if stalked_prey then
			Move.to({x=stalked_prey.posX, y=stalked_prey.posY})
			--if (PositionX == stalked_prey.posX and PositionY == stalked_prey.posY) then
			if math.sqrt(math.pow((PositionX-stalked_prey.posX),2) + math.pow((PositionY-stalked_prey.posY),2)) < 1 then
				--Agent.removeAgent(stalked_prey.id)
				Event.emit{targetID=stalked_prey.id, speed=343, description="attack"}
				Stalking = false
			end
		elseif not stalked_prey then
				Stalking = false
		end
  end
end

function cleanUp()
	say("Agent #: " .. ID .. " is done\n")
end


_ScanMap = function(scanRadius)

	local dist = 10000

	local table = Collision.radialCollisionScan(scanRadius, PredatorX, PredatorY)
	if table ~= nil then
		--say(#table)
		for i = 1, #table do
			temp_dist = math.sqrt(math.pow((PositionX-table[i].posX),2) + math.pow((PositionY-table[i].posY),2))
			if temp_dist < dist then
				dist = temp_dist
				targetPrey = table[i]
			end
			--say(table[i].id)
			--say(temp_dist)
		end
		--say("targetPrey")
		--say(targetPrey.id)
		return targetPrey
	end
	return
end
