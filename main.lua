function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
 
	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then love.timer.step() end
 
	local dt = 0
 
	-- Main loop time.
	while true do
		-- Process events.
		if love.event then
			love.event.pump()
			for name, a,b,c,d,e,f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a
					end
				end
				love.handlers[name](a,b,c,d,e,f)
			end
		end
 
		-- Update dt, as we'll be passing it to update
		if love.timer then
			love.timer.step()
			dt = love.timer.getDelta()
		end
 
		-- Call update and draw
		if love.update then love.update(dt) end -- will pass 0 if love.timer is disabled
 
		if love.graphics and love.graphics.isActive() then
			love.graphics.clear(love.graphics.getBackgroundColor())
			love.graphics.origin()
			if love.draw then love.draw() end
			love.graphics.present()
		end
 
		if love.timer then love.timer.sleep(0.001) end
	end
 
end

function love.load()

	-- Window Dimensions
	screen = {width = 800, height = 600}

	-- Window Setup
	love.window.setTitle('Dubby Pendy')
	love.window.setMode(screen.width, screen.height)

	g = 10

	function directSum(a, b)
		local c = {}
		for i,v in pairs(a) do
			c[i] = a[i] + b[i]
		end
		return c
	end

	function scalarMultiply(scalar, table)
		local output = {}
		for i,v in pairs(table) do
			output[i] = scalar*table[i]
		end
		return output
	end 

	past = false

	function Generator(seed)
	
		local self = {}
 
 		if not seed then
			self.m1 = love.math.random( 3, 10 )
			self.m2 = love.math.random( 3, 10 )
			self.l1 = love.math.random( 3, 10 ) 
			self.l2 = love.math.random( 1, 10 )
			self.t1 = love.math.random( -6.28, 6.28 )
			self.t2 = love.math.random( -6.28, 6.28 )
			self.o1 = love.math.random( -4, 4 )
			self.o2 = love.math.random( -2, 2 )
		else
			local params = {"m1", "m2", "l1", "l2", "t1", "t2", "o1", "o2"}
			local i = 1;
			for param in string.gmatch(seed, "[^ ]+") do
				param = tonumber(param)

				if type(param)~="number" or not (params[i]) then error("Tried to load something invalid") end
				
				self[params[i]] = param;
				i=i+1
			end
		end

		self.p1 = (self.m1+self.m2)*(math.pow(self.l1, 2))*self.o1 + self.m2*self.l1*self.l2*self.o2*math.cos(self.t1-self.t2)
		self.p2 = self.m2*(math.pow(self.l2, 2))*self.o2 + self.m2*self.l1*self.l2*self.o1*math.cos(self.t1-self.t2)

		currentSeed = self.m1 .. " " ..
		self.m2 .. " " ..
		self.l1 .. " " ..
		self.l2 .. " " ..
		self.t1 .. " " ..
		self.t2 .. " " ..
		self.o1 .. " " ..
		self.o2

		print("data is "..currentSeed)

		return self

	end

	data = Generator()

	function Solver(dt)

		local phase = {data.t1, data.t2, data.p1, data.p2}

		local k1 = Hamiltonian(phase, data)
		local k2 = Hamiltonian(directSum(phase, scalarMultiply(dt/2, k1)), data)
		local k3 = Hamiltonian(directSum(phase, scalarMultiply(dt/2, k2)), data)
		local k4 = Hamiltonian(directSum(phase, scalarMultiply(dt, k3)), data)

		local R = scalarMultiply(1/6 * dt, directSum(directSum(k1, scalarMultiply(2.0, k2)), directSum(scalarMultiply(2.0, k3), k4)))

		data.t1 = data.t1 + R[1]
		data.t2 = data.t2 + R[2]
		data.p1 = data.p1 + R[3]
		data.p2 = data.p2 + R[4]

	end

	function Hamiltonian(phase, data)

		local update = {}

		t1 = phase[1]
		t2 = phase[2]
		p1 = phase[3]
		p2 = phase[4]

		C0 = data.l1*data.l2*(data.m1 + data.m2*math.pow(math.sin(t1-t2),2))
		C1 = (p1*p2*math.sin(t1-t2)) / C0
		C2 = (data.m2*(math.pow(data.l2*p1, 2)) + (data.m1+data.m2)*(math.pow(data.l1*p2, 2)) - 2*data.l1*data.l2*data.m2*p1*p2*math.cos(t1-t2))*math.sin(2*(t1-t2)) /(2*(math.pow(C0,2)))

		-- Time derivatives
		update[1] = (data.l2*p1 - data.l1*p2*math.cos(t1-t2)) / (data.l1*C0)
		update[2] = (data.l1*(data.m1+data.m2)*p2 - data.l2*data.m2*p1*math.cos(t1-t2)) / (data.l2*data.m2*C0)
		update[3] = -(data.m1 + data.m2)*g*data.l1*math.sin(t1) - C1 + C2
		update[4] = -data.m2*g*data.l2*math.sin(t2) + C1 - C2

		return update
	end

	function getDimensions(input)

		R1 = 15*(input.m1/(input.m1 + input.m2))
		R2 = 15*(input.m2/(input.m1 + input.m2))
		P1 = 0.85 * math.min(screen.width/2, screen.height/2) * (input.l1 / (input.l1 + input.l2))
		P2 = 0.85 * math.min(screen.width/2, screen.height/2) * (input.l2 / (input.l1 + input.l2))

		local pos0 = {screen.width/2, screen.height/2}
		local pos1 = {P1*math.sin(input.t1), P1*math.cos(input.t1)}
		local pos2 = {P2*math.sin(input.t2), P2*math.cos(input.t2)}

		local B1 = directSum(pos0, pos1)
		local B2 = directSum(B1, pos2)

		return R1, R2, P1, P2
	end

	R1, R2, P1, P2 = getDimensions(data)

	function updatePosition()
		
		local pos0 = {screen.width/2, screen.height/2}
		local pos1 = {P1*math.sin(data.t1), P1*math.cos(data.t1)}
		local pos2 = {P2*math.sin(data.t2), P2*math.cos(data.t2)}

		B1 = directSum(pos0, pos1)
		B2 = directSum(B1, pos2)
		
		return B1, B2
	end

	canvas = love.graphics.newCanvas()
	
end

function love.update()

	local dt = 0.03;
	Solver(dt)
	B1, B2 = updatePosition()
	x1, y1, x2, y2 = B1[1], B1[2], B2[1], B2[2]

end

function love.draw()
	
	love.graphics.setCanvas(canvas)
	love.graphics.setColor(255, 100, 0)
	--love.graphics.circle("fill", x1, y1, 2, 200)
	if not past then past = {} else
		--love.graphics.line(past.x1, past.y1, x1, y1)
		love.graphics.setColor(0, 100, 255) 
		love.graphics.line(past.x2, past.y2, x2, y2)
	end
	past.x2, past.y2 = x2, y2;
	past.x1, past.y1 = x1, y1;

	love.graphics.setColor(0, 100, 255)
	love.graphics.circle("fill", x2, y2, 3, 200)
	love.graphics.setCanvas( )
	love.graphics.setColor(255, 255, 255)
	love.graphics.draw(canvas)

	--Lines
	love.graphics.setColor(240, 240, 240)
	love.graphics.setLineWidth( 4 )
	love.graphics.line(screen.width/2, screen.height/2, x1, y1)
	love.graphics.line(x1, y1, x2, y2)	
	love.graphics.setLineWidth(0 )

	--Bobs
	love.graphics.setColor(0, 100, 255)
	love.graphics.circle("fill", x2, y2, R2, 200)
	love.graphics.setColor(255, 255, 0)
	love.graphics.circle("fill", screen.width/2, screen.height/2, 2, 200)
	love.graphics.setColor(255, 100, 0)
	love.graphics.circle("fill", x1, y1, R1, 200)

end

function displaySeed()

	pause()
	love.window.showMessageBox("Seed", "Seed copied to clipboard", "info", false)
	pause(not paused)
	print("Saving...")
	love.system.setClipboardText(currentSeed)

end

function reset(seed)

	past = false
	love.graphics.setCanvas(canvas)
	love.graphics.clear()
	love.graphics.setCanvas()
	if seed then
		love.window.showMessageBox("Loaded", "Loaded seed from clipboard: "..seed, "info", true)
		print("Loading...")
	end
	data = Generator(seed)
	getDimensions(data)

end

fullscreen = false;
paused = false;

justdoit = love.update

function pause(resume)
	
	if resume then
		love.update = justdoit
	else
		love.update = nil
	end

end

function love.keypressed(kek)

	-- Reset
	if kek=="space" then
		reset()
	-- Fullscreen
	elseif kek == "f" then
		fullscreen = not fullscreen
		success = love.window.setFullscreen( fullscreen )
	-- Save seed
	elseif kek == "s" then
		displaySeed()
	-- Load seed
	elseif kek == "l" then
		local seed = love.system.getClipboardText();
		reset(seed)
	-- Pause
	elseif kek == "p" then
		pause(paused)
		paused = not paused;
	-- Clear canvas
	elseif kek == "d" then
		love.graphics.setCanvas(canvas)
		love.graphics.clear()
		love.graphics.setCanvas()
	end
	
end
