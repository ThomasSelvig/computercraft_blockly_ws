-- NodeMCU client

-- todo: add error printing

local s = softuart.setup(9600, 5, 4)
local ws = websocket.createClient()

ws:config({headers={["useragent"]="NodeMCU"}})


ws:on("connection", function()
	-- only register this door-listening event after websocket connected
	s:on(
		"data", 
		8, 
		function(data) 
			if data == "063774a5" then
				-- open door
				ws:send("DOOR_OPEN")
			else
				-- print error
				ws:send("DOOR_ERROR")
			end
		end
	)
end)

ws:connect("ws://85.165.129.95:23085")

