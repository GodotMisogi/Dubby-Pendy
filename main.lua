function love.run()
 
	if love.math then
		love.math.setRandomSeed(os.time())
	end
 
	if love.load then love.load(arg) end
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
		screen = {width = 1500, height = 900}
	
		-- Window Setup
		love.window.setTitle('Dubby Pendy')
		love.window.setMode(screen.width, screen.height)
		
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
				-- self.m1 = 5
				-- self.m2 = 5
				-- self.l1 = 5
				-- self.l2 = 5
				-- self.t1 = 60*math.pi/180
				-- self.t2 = 31*math.pi/180
				-- self.o1 = 2
				-- self.o2 = 2
				self.m1 = love.math.random( 3, 10 )
				self.m2 = love.math.random( 3, 10 )
				self.l1 = love.math.random( 3, 10 )
				self.l2 = love.math.random( 1, 10 )
				self.t1 = love.math.random( -2*math.pi, 2*math.pi )
				self.t2 = love.math.random( -2*math.pi, 2*math.pi )
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
	
		function Hamiltonian(phase, data)
	
			local g = 10
			local update = {}
	
			t1 = phase[1]
			t2 = phase[2]
			p1 = phase[3]
			p2 = phase[4]
	
			C0 = data.l1*data.l2*(data.m1 + data.m2*math.pow(math.sin(t1-t2),2))
			C1 = (p1*p2*math.sin(t1-t2)) / C0
			C2 = (data.m2*(math.pow(data.l2*p1, 2)) + (data.m1+data.m2)*(math.pow(data.l1*p2, 2)) - 2*data.l1*data.l2*data.m2*p1*p2*math.cos(t1-t2))*math.sin(2*(t1-t2)) / (2*(math.pow(C0,2)))
	
			-- Time derivatives
			update[1] = (data.l2*p1 - data.l1*p2*math.cos(t1-t2)) / (data.l1*C0)
			update[2] = (data.l1*(data.m1+data.m2)*p2 - data.l2*data.m2*p1*math.cos(t1-t2)) / (data.l2*data.m2*C0)
			update[3] = -(data.m1 + data.m2)*g*data.l1*math.sin(t1) - C1 + C2
			update[4] = -data.m2*g*data.l2*math.sin(t2) + C1 - C2
	
			return update
		end
	
		function Solver(data, dt)
	
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
	
			return data
		end
	
		function map(func, table)
			local ntable = {}    
	
			for k,v in pairs(table) do
				ntable[k] = func(v)
			end
			
			return ntable
		end
	
		function polarToBizarreCartesian(r,theta)
			local coords = {r*math.sin(theta), r*math.cos(theta)}
			return coords
		end
	
		function getDimensions(input)
	
			frac1 = 15*(input.m1/(input.m1 + input.m2))
			frac2 = 15*(input.m2/(input.m1 + input.m2))
			bob1 = 0.85 * math.min(screen.width/2, screen.height/4) * (input.l1 / (input.l1 + input.l2))
			bob2 = 0.85 * math.min(screen.width/2, screen.height/4) * (input.l2 / (input.l1 + input.l2))
	
			return frac1, frac2, bob1, bob2
		end
	
		R1, R2, P1, P2 = getDimensions(data)
	
		function updatePosition(data)
	
			local pos0 = {screen.width/2, screen.height/4}
			local pos1 = polarToBizarreCartesian(P1, data.t1)
			local pos2 = polarToBizarreCartesian(P2, data.t2)
	
			local B1 = directSum(pos0, pos1)
			local B2 = directSum(B1, pos2)
	
			return B1, B2
		end
	
		function graphCoordinates(data)
		
			local pos0 = {screen.width/2, 3*screen.height/4}
			local pos1 = {0.5 * math.min(screen.width/2, screen.height/4) * data.t1/(2*math.pi), 0.85 * math.min(screen.width/2, screen.height/4) * data.p1/(200*(data.m1 + data.m2))}
			local pos2 = {0.5 * math.min(screen.width/2, screen.height/4) * data.t2/(2*math.pi), 0.85 * math.min(screen.width/2, screen.height/4) * data.p2/(200*(data.m1 + data.m2))}
			-- math.sqrt(math.pow(data.p1,2) + math.pow(data.p2,2))
			-- math.sqrt(math.pow(data.p1,2) + math.pow(data.p2,2))
			local X1 = directSum(pos0, pos1)
			local X2 = directSum(pos0, pos2)
		
			return X1, X2
		end
	
		canvas_upper = love.graphics.newCanvas()
		canvas_lower = love.graphics.newCanvas()
	
	end
	
	function love.update()
	
		local dt = 0.03;
		updates = Solver(data, dt)
		B1, B2 = updatePosition(updates)
		G1, G2 = graphCoordinates(data)
		t1, p1, t2, p2 = G1[1], G1[2], G2[1], G2[2]
		x1, y1, x2, y2 = B1[1], B1[2], B2[1], B2[2]
	
	end
	
	function love.draw()	
		drawBackground()
		love.graphics.setCanvas()
		drawGraphs()
	end
	
	function drawGraphs()
		love.graphics.setCanvas(canvas_lower)
		-- love.graphics.setCanvas
		-- love.graphics.setColor(1, 0.35, 0)
		-- Inner bob particle track
		--love.graphics.circle("fill", x1, y1, 2, 200)
		if not past then past = {} else
	
			love.graphics.setColor(1, 0.5, 0)
			-- Axis plot
			love.graphics.line(past.t1, past.p1, t1, p1)
			-- Inner bob path
			--love.graphics.line(past.x1, past.y1, x1, y1)
	
			love.graphics.setColor(0.4, 0.7, 1)
			-- Axis plot
			love.graphics.line(past.t2, past.p2, t2, p2)
	
			-- if p2 <= screen.height/2 or p2 >= screen.height then
			-- 	love.graphics.scale(1.1, 1.1)
			-- end
	
			-- Outer bob path
			love.graphics.setCanvas(canvas_upper)
			love.graphics.line(past.x2, past.y2, x2, y2)
			love.graphics.circle("fill", x2, y2, 2)
			
		end
		past.x2, past.y2, past.x1, past.y1  = x2, y2, x1, y1
		past.p2, past.t2, past.p1, past.t1 = p2, t2, p1, t1
	
		love.graphics.setColor(1, 1, 1)
		love.graphics.draw(canvas_upper)
		love.graphics.draw(canvas_lower, 0, 0, 0, 1, 1, canvas_lower:getWidth()/2, canvas_lower:getHeight()/2, 0, screen.height/2)
	end
	
	function drawBackground()
		filename = "cmunss.ttf"
		size = 15
		love.graphics.setNewFont(filename, size)
		love.graphics.setBackgroundColor(0.15,0.15,0.15)
	
		--Lines
		love.graphics.setColor(0.9, 0.9, 0.9)
		love.graphics.setLineWidth( 2 )
		love.graphics.line(screen.width/2, screen.height/4, x1, y1)
		love.graphics.line(x1, y1, x2, y2)
		love.graphics.setLineWidth( 0 )
		love.graphics.setColor(0.4, 1, 0.7)
		-- Divider
		love.graphics.line(0, screen.height/2, screen.width, screen.height/2)
	
		--Graph
		love.graphics.setColor(1, 1, 1, 0.8)
		love.graphics.setLineWidth(1)
		-- Axes
		love.graphics.line(screen.width/2, screen.height/2, screen.width/2, screen.height)
		love.graphics.line(0, 3*screen.height/4, screen.width, 3*screen.height/4)
		-- Bottom arrow
		love.graphics.polygon('fill', (1 - 0.008)*screen.width/2, (1 - 0.015)*screen.height, (1 + 0.008)*screen.width/2, (1 - 0.015)*screen.height, screen.width/2, screen.height)
		-- Top arrow
		love.graphics.polygon('fill', (1 - 0.008)*screen.width/2, (1 + 0.03)*screen.height/2, (1 + 0.008)*screen.width/2, (1 + 0.03)*screen.height/2, screen.width/2, screen.height/2)
		-- Left arrow
		love.graphics.polygon('fill', 0.01*screen.width, (1 + 0.008)*3*screen.height/4, 0.01*screen.width, (1 - 0.008)*3*screen.height/4, 0, 3*screen.height/4)
		-- Right arrow
		love.graphics.polygon('fill', (1-0.01)*screen.width, (1 + 0.008)*3*screen.height/4, (1 - 0.01)*screen.width, (1 - 0.008)*3*screen.height/4, screen.width, 3*screen.height/4)
		-- X-ticks
		-- love.graphics.line(screen.width/2 + 10*math.pi, (1 - 0.008)*3*screen.height/4, screen.width/2 + 10*math.pi, (1 + 0.008)*3*screen.height/4)
		-- Labels
		love.graphics.print("p", (1 + 0.015)*screen.width/2, (1 + 0.025)*screen.height/2)
		love.graphics.print("θ", (1 - 0.02)*screen.width, (1 - 0.03)*3*screen.height/4)
	
		love.graphics.setLineWidth(0)
	
		--Bobs
		--Blue
		love.graphics.setColor(0.4, 0.7, 1)
		love.graphics.circle("fill", x2, y2, R2)
		--Orange
		love.graphics.setColor(1, 0.5, 0)
		love.graphics.circle("fill", x1, y1, R1)
		love.graphics.setColor(1, 1, 0)
		--Center
		love.graphics.circle("fill", screen.width/2, screen.height/4, 2)
		love.graphics.setColor(1, 1, 1)
		love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 0, 0)
		love.graphics.print("Angular Momentum of Red Bob: "..tostring(updates.p1), 0, 15)
		love.graphics.print("Angular Momentum of Blue Bob: "..tostring(updates.p2), 0, 30)
		love.graphics.print("Random Input", 38, 72)
		love.graphics.print("Mouse Coordinates:"..tostring(love.mouse.getX())..tostring(love.mouse.getY()), 0, 50)
		love.graphics.setColor(1, 1, 1, 0.3)
		love.graphics.rectangle("fill", 20, 70, 120, 20)
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
		love.graphics.setCanvas(canvas_upper)
		love.graphics.clear()
		love.graphics.setCanvas(canvas_lower)
		love.graphics.clear()
		love.graphics.setCanvas()
		if seed then
			love.window.showMessageBox("Loaded", "Loaded seed from clipboard: "..seed, "info", true)
			print("Loading...")
		end
		data = Generator(seed)
		R1, R2, P1, P2 = getDimensions(data)
	
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
	
	function love.keypressed(key, isrepeat)
	
		-- Reset
		if key=="r" then
			reset()
		-- Fullscreen
		elseif key == "f" then
			fullscreen = not fullscreen
			success = love.window.setFullscreen(fullscreen,"desktop")
		-- Save seed
		elseif key == "s" then
			displaySeed()
		-- Load seed
		elseif key == "l" then
			local seed = love.system.getClipboardText();
			reset(seed)
		-- Pause
		elseif key == "space" then
			pause(paused)
			paused = not paused;
		-- Clear canvas
		elseif key == "d" then
			love.graphics.setCanvas(canvas_upper)
			love.graphics.clear()
			love.graphics.setCanvas(canvas_lower)
			love.graphics.clear()
			love.graphics.setCanvas()
		elseif key == "q" then
			love.event.quit()
		 end
	end
	
	-- function love.mousepressed(x, y, button, istouch)
	-- 	if ((20 <= x or x <= 20+120) and (70 <= y or y <= 70+20)) then
	-- 		reset()
	-- 	end
	--  end
	
	--Flower
	--7 10 8 6 -3.28 -5.28 4 -2
	
	--Wavey
	--8 5 3 5 -1.28 6.72 -3 2
	
	--Loopy
	--3 7 5 5 -1.28 -4.28 4 2
	
	--Patrick
	--4 8 3 7 120.06776159731 -9.9019489420537 -3 1
	
	-- CUCK
	--9 9 5 3 -6.28 4.72 2 -1
	
	-- Old Atom
	-- 8 6 5 6 -6.28 2.72 -3 2
	
	--Chiyochichi?
	--5 10 4 10 3.72 -1.28 -4 0
	
	--Heart
	--10 4 7 8 -4.28 0.72 1 2
	
	-- SHMish
	--3 10 10 1 4.72 4.72 0 0
	
	--Decent Phase Space
	--10 8 4 9 -1.2831853071796 -3.2831853071796 2 0
	--5 5 4 4 3.7168146928204 -4.2831853071796 1 0
	--6 8 9 8 -5.2831853071796 2.7168146928204 1 2
	--6 1 9 1 1.1 1 1 1
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
