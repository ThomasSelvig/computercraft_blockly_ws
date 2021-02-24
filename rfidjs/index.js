/*
the wire between the door and the nodemcu
this server will broadcast everything, like a chatroom
the door will look for DOOR_OPEN or DOOR_ERROR messages
*/

const WebSocket = require('ws')
const { v4: uuidv4 } = require('uuid');

const express = require("express")
const fs = require('fs')
// const bodyParser = require("body-parser")

const wss = new WebSocket.Server({port: 23085})
const app = express()
app.use(express.static("blockly"))
// const index_page = fs.readFileSync("index.html", {encoding: "utf-8"})
// app.use(bodyParser.urlencoded({extended: true}))


wss.on("connection", (ws, req) => {
	ws.TID = uuidv4().split("-").join("")  // strip "-" to allow use as CC label
	// ws.TID = ws.TID.slice(0, 3)  // todo: remove this later

	ws.UA = req.headers.useragent
	console.log(`Connected: \n\tTID: ${ws.TID}\n\tU-A: ${ws.UA}`);

	if (ws.UA == "CC") {
		ws.send(JSON.stringify(
			{
				sender: "server",
				msg: {
					cmd: "exec",
					data: `os.setComputerLabel("${ws.TID}")`
				}
			}
		))
	}
	
	ws.on("message", msg => {
		console.log(`${ws.TID} -> \n\t${msg}`)
		if (msg == ".") {
			return
		}

		/*
		Structure of incoming msg (JSON)
			{
				"recipient": string (TID of connected user to receive message),
				"msg": JSON encoded message for recipient to decode
			}
		*/
		/*
		Structure of outgoing msg (JSON)
			{
				"msg": JSON encoded message for recipient to decode: {
					"cmd": "exec",
					"data": command to execute (lua)
				},
				"sender": TID of sender (for the recipient to decode)
			}
		*/
		
		let msg_obj = JSON.parse(msg)

		if (msg_obj.recipient == "server") {
			if (msg_obj.msg == "ASK_TURTLE_LIST") {
				let turtles = []
				for (let c of wss.clients) {
					if (c.UA == "CC") {
						turtles.push(c.TID)
					}
				}
				ws.send(JSON.stringify({
					sender: "server",
					msg: turtles
				}))
			}
		}

		wss.clients.forEach(ws_i => {
			if (ws_i.TID == msg_obj.recipient) {
				ws_i.send(JSON.stringify({
					msg: msg_obj.msg,
					sender: ws.TID
				}))
			}
		})
	})

	ws.on("close", (code, reason) => {
		console.log(`Disconnected: ${ws.TID} (${code}) (${reason})`)
	})
})

app.get("/", (req, res) => {
	// res.send(index_page)
	res.send(fs.readFileSync("index.html", {encoding: "utf-8"}))
})

app.listen(80, () => {
	console.log("Listening @ 80")
})