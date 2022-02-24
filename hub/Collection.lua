local class = require("seedless.util.class")

local Collection = class()

function Collection:init(name, nodes, nodeConnections)
    self.name = name
    self.nodeIDs = nodes -- nodeIDs is for a list of all the nodes
    self.nodeConnection = nodeConnections -- nodeConnections is the table linking nodes together
end

function Collection:serialise()
    local thinCollection = { }
    thinCollection.name = self.name
    thinCollection.nodeIDs = self.nodeIDs
    thinCollection.nodeConnections = self.nodeConnections

    return thinCollection
end

return Collection