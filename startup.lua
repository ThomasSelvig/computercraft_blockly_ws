

function exec_from_ws(wsc)
	--[[ returns bool(remote code ran successfully) ]]

	inc = wsc.receive()  -- receive
	if inc == "DOOR_OPEN" then
		redstone.setOutput("left", true)
		sleep(3)
		redstone.setOutput("left", false)
	elseif inc == "DOOR_ERROR" then
		print("Access denied")
	end
end


function main()
	-- connect to remote wss
	local wsc, err = http.websocket("ws://85.165.129.95:23085")
	if wsc then
		-- connected
		while true do
			ret = pcall(exec_from_ws, wsc)
		end
	end
end


main()
