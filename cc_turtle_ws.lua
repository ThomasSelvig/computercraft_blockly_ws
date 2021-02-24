--[[
	behaviour: on reboot, message_received will constantly listen for messages
	if the websocket fails or closes, 
]]

local URL = "ws://85.165.129.95:23085"


-- try to import json library
local status, json = pcall(require, "json")
if not status then
	-- json lib not found, download to file
	print("installing json library")
	local f = fs.open("json.lua", "w")
	f.write(http.get("https://github.com/rxi/json.lua/raw/master/json.lua").readAll())
	f.close()
	json = require("json")
	print("json library installed!")
end


function message_received(msg, ws_handle)
	print("Msg:", msg)
	
	local obj = json.decode(msg)
	local cmd, data = obj.msg.cmd, obj.msg.data

	if cmd == "exec" then
		-- `data` is the lua code to be executed
		local success, ret = pcall(loadstring(data))  -- execute w try/catch
		-- respond to sender with output
		pcall(ws_handle.send, json.encode({
			msg = {
				success = success, 
				returned = ret
			},
			recipient = obj.sender
		}))
	end
end


function ws_closed()
	os.setComputerLabel()  -- clear label
	-- uncomment below to constantly retry websocket connection
	-- os.reboot()
end


-- open WS connection
http.websocketAsync(URL, {["useragent"] = "CC"}) 
local event, url, ret
repeat
	-- EVENT websocket_success or websocket_failure
	event, url, ret = os.pullEvent()

until event == "websocket_success" or event == "websocket_failure"

-- websocket has now either failed or succeeded
if event == "websocket_success" then
	print("Connected to", url)
	os.setComputerLabel("CONN")

	-- set an alarm to ping the server in one IRL minute
	local ping_alarm = os.setAlarm((os.time() + 24/20) % 24)

	-- `ret` is now the websocket handle
	while true do
		-- listen for event: websocket_message or websocket_closed
		local event, p1, p2 = os.pullEvent()

		if event == "websocket_closed" then
			print("Websocket closed")
			ws_closed()
			break

		elseif event == "websocket_failure" then
			-- `ret` is now the websocket error
			print("Websocket failed:", ret)
			ws_closed()
			break

		elseif event == "websocket_message" then 
			message_received(p2, ret)

		elseif event == "alarm" and p1 == ping_alarm then
			-- ping server
			print("pinging")
			if pcall(ret.send, ".") then
				print("pong")
			else
				print("ping error!")
				ws_closed()
				break
			end
			-- restart alarm
			ping_alarm = os.setAlarm((os.time() + 24/20) % 24)

		end

	end

elseif event == "websocket_failure" then
	-- `ret` is now the websocket error
	print("Websocket failed:", ret)
	ws_closed()
end
