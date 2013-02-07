express = require "express"
dgram = require "dgram"
app = express()
app.use express.bodyParser()

commandSeqNumber = 1
ownPort = 8080
droneInputPort = 5556
droneOutputPort = 5556
droneIP = "192.168.1.1"

sendInstructionViaUdp = (commandString) ->
  message = new Buffer(commandString)
  client = dgram.createSocket("udp4")
  client.send(message, 0, message.length, droneInputPort, droneIP, (err, bytes) ->
    console.log err if err
    console.log bytes if bytes
    client.close()
  )

instructions = {
  takeoff: -> "AT*FTRIM=#{commandSeqNumber++}\rAT*REF=#{commandSeqNumber++},290718208\r", # Basic AT*REF instruction with bit 9th bit 1
  land: -> "AT*REF=#{commandSeqNumber++},290717696\r",
  tiltLeft: (tilt) -> "AT*PCMD=#{commandSeqNumber++},0,-#{tilt},0,0,0\r", # Set to default (hovering mode)
  tiltRight: (tilt) -> "AT*PCMD=#{commandSeqNumber++},0,#{tilt},0,0,0\r",
  turnLeft: (deg) -> "AT*PCMD=#{commandSeqNumber++},0,0,0,0,-#{deg}\r",
  turnRight: (deg) -> "AT*PCMD=#{commandSeqNumber++},0,0,0,0,#{deg}\r",
  tiltFront: (tilt) -> "AT*PCMD=#{commandSeqNumber++},0,0,-#{tilt},0,0\r",
  tiltBack: (tilt) -> "AT*PCMD=#{commandSeqNumber++},0,0,#{tilt},0,0\r",
  up: (deg) -> "AT*PCMD=#{commandSeqNumber++},0,0,0,#{deg},0\r",
  down: (deg) -> "AT*PCMD=#{commandSeqNumber++},0,0,0,-#{deg},0\r",
  progressive: (lrTilt=0, fbTilt=0, vertSpeed=0, angSpeed=0, modeBits=0) -> "AT*PCMD=#{commandSeqNumber++},#{modeBits},#{lrTilt},#{fbTilt},#{vertSpeed},#{angSpeed}\r"
}

# We want our params separated by a comma
app.get "/instructions/:name/:params", (req, res) ->
  res.setHeader('Content-Type', 'text/plain')
  instruction = instructions[req.params.name]
  params = req.params.params.split(",")
  cmd = instruction(params...) # Splat array to function arguments
  res.setHeader('Content-Length', cmd.length) 
  sendInstructionViaUdp(cmd)

  res.end(cmd)

app.get "/instructions/:name", (req, res) ->
  res.setHeader('Content-Type', 'text/plain')
  instruction = instructions[req.params.name]
  cmd = instruction() # Splat array to function arguments
  res.setHeader('Content-Length', cmd.length) 
  sendInstructionViaUdp(cmd)

  res.end(cmd)

app.listen ownPort
console.log "Server running in port #{ownPort}"


