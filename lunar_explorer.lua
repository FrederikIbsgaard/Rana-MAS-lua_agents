
-- Import Rana lua modules.
Event = require "ranalib_event"


-- Load torus modul to move and scan though egdes
torusModul = require "torus_modul"

-- EventHandler
function handleEvent(sourceX, sourceY, sourceID, eventDescription, eventTable)

end

function initializeAgent()
	GridMove = true


end

function takeStep()

end


function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
