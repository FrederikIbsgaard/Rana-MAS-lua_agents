-- Import Rana lua libraries
Agent = require "ranalib_agent"
Stat = require "ranalib_statistic"
Map = require "ranalib_map"
Shared = require "ranalib_shared"

-- amount of bases
N = 1
-- density of ore [procentage]
D = 0.05
-- base capacity of ore
C = math.floor(D/N-D)
-- energi for robots [units]
E = 100
-- grid size
G = ENV_WIDTH
-- fixed communication scope
I = 20
-- coordination mode, cooperative = 1 or competitive 0
M = 0
-- initial perception scope
P = 10
-- cost of motion
Q = 1
-- memory size of robots
S = 10
-- Max number of cycles
T = 100
-- max number of ore a miner can carry
W = 1
-- number of explores
X = 1
-- number of miners
Y = 1

-- VARIABLES
background_color = {0,0,0}
ore_color = {0,0,255}

function initializeAgent()

    --StepMultiple = 1000
    say("Master Agent#: " .. ID .. " has been initialized")
    local parameters = {N=N, D=D, C=C, E=E, G=G, I=I, M=M, P=P, Q=Q, S=S, T=T, W=W, X=X, Y=Y}
    Shared.storeTable("background_color", background_color)
    Shared.storeTable("ore_color", ore_color)
    Shared.storeTable("parameters", parameters)

    for i=0, ENV_WIDTH do
        for j=0, ENV_HEIGHT do
            Map.modifyColor(i,j, background_color)
        end
    end
    local amountOfOre = (G*G)*D
    say("amount of ore: ".. amountOfOre)
    for i=1, amountOfOre do
        local placed = false
        while not placed do
            x = Stat.randomInteger(0,ENV_WIDTH)
            y = Stat.randomInteger(0,ENV_WIDTH)
            local color = Map.checkColor(x,y)
            if color[1] == 0 and color[2] == 0 and color[3] == 0 then
                Map.modifyColor(x,y, ore_color)
                placed = true
            end

        end

    end
    say("Map has been initialized")

    local data_table = {}
	local ids = {}
    local baseCordinates = {}
    for i = 1, N do
        local placed = false
        while not placed do
            x = Stat.randomInteger(0,ENV_WIDTH)
            y = Stat.randomInteger(0,ENV_WIDTH)
            local color = Map.checkColor(x,y)
            if color[1] == 0 and color[2] == 0 and color[3] == 0 then
                local ID = Agent.addAgent("lunar_base.lua",x,y)
                table.insert(ids, ID)
                data_table[ID] = {call_amount = 0}
                table.insert(baseCordinates, {x,y})
                placed = true
            end
        end
    end

    for i=1, N do
        x = baseCordinates[i][1]
        y = baseCordinates[i][2]
        -- give each base explores
        for i=1,X do
            local ID = Agent.addAgent("lunar_explorer.lua",x,y)
            table.insert(ids, ID)
            data_table[ID] = {call_amount = 0}
        end
        -- gave each base miners
        for i=1,Y do
            local ID = Agent.addAgent("lunar_miner.lua",x,y)
            table.insert(ids, ID)
            data_table[ID] = {call_amount = 0}
        end
    end



    say("All agents initialized")

end

function takeStep()
	Agent.removeAgent(ID)

    say("Master agent removed")
end

function cleanUp()
	--say("Agent #: " .. ID .. " is done\n")
end
