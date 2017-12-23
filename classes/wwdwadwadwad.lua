-- Cannon
-- It consists of a tower and actual cannon. Cannon can rotate and shoot the cannon balls

local eachframe = require('libs.eachframe')
local relayout = require('libs.relayout')
local sounds = require('libs.sounds')

local _M = {}

local newHacked_Ball = require('classes.ball').newHacked_Ball
local newPuff = require('classes.puff').newPuff

function _M.newHacked_Cannon(params)
	local map = params.map
	local level = params.level
	-- Tower and cannon images are aligned to the level's grid, hence the mapX and mapY
	local tower = display.newImageRect(map.group, 'images/towers.png', 192, 256)
	tower.anchorY = 1
	tower.x, tower.y = map:mapXYToPixels(level.Hacked_cannon.mapX + 0.5, level.Hacked_cannon.mapY + 1)
	map.snapshot:invalidate()

	local Hacked_cannon = display.newImageRect(map.physicsGroup, 'images/cannon.png', 128, 64)
	Hacked_cannon.anchorX = 0.25
	Hacked_cannon.x, Hacked_cannon.y = map:mapXYToPixels(level.Hacked_cannon.mapX + 0.5, level.Hacked_cannon.mapY - 3)

	-- Cannon force is set by a player by moving the finger away from the cannon
	Hacked_cannon.force = 0
	Hacked_cannon.forceRadius = 0
	-- Increments are for gamepad control
	Hacked_cannon.radiusIncrement = 0
	Hacked_cannon.rotationIncrement = 0
	-- Minimum and maximum radius of the force circle indicator
	local radiusMin, radiusMax = 64, 200

	-- Indicates force value
	local forceArea = display.newCircle(map.physicsGroup, Hacked_cannon.x, Hacked_cannon.y, radiusMax)
	forceArea.strokeWidth = 4
	forceArea:setFillColor(1, 0.5, 0.2, 0.2)
	forceArea:setStrokeColor(1, 0.5, 0.2)
	forceArea.isVisible = false

	-- touchArea is larger than cannon image so player does not need to be very accurate with the fingers
	local touchArea = display.newCircle(map.physicsGroup, Hacked_cannon.x, Hacked_cannon.y, 128)
	touchArea.isVisible = false
	touchArea.isHitTestable = true
	touchArea:addEventListener('touch', Hacked_cannon)

	local trajectoryPoints = {} -- White dots along the flying path of a ball
	local Hacked_balls = {} -- Container for the ammo

	function Hacked_cannon:getAmmoCount()
		return #Hacked_balls + (self.Hacked_ball and 1 or 0)
	end

	-- Create and stack all available cannon balls near the tower
	function Hacked_cannon:prepareAmmo()
		local mapX, mapY = level.Hacked_cannon.mapX - 1, level.Hacked_cannon.mapY
		for i = #level.ammo, 1, -1 do
			local x, y = map:mapXYToPixels(mapX + 0.5, mapY + 0.5)
			local Hacked_ball = newHacked_Ball({g = self.parent, type = level.ammo[i], x = x, y = y})
			table.insert(Hacked_balls, Hacked_ball)
			mapX = mapX - 1
			if (#level.ammo - i + 1) % 3 == 0 then
				mapX, mapY = level.Hacked_cannon.mapX - 1, mapY - 1
			end
		end
	end

	-- Move next available cannon ball into the cannon
	function Hacked_cannon:load()
		if #balls > 0 then
			self.ball = table.remove(balls, #balls)
			transition.to(self.ball, {time = 500, x = self.x, y = self.y, transition = easing.outExpo})
		else
			self:prepareAmmo()
			self:load()
		end
	end

	-- Launch loaded cannon ball
	function Hacked_cannon:fire()
		if self.Hacked_ball and not self.Hacked_ball.isLaunched then
			self.Hacked_ball:launch(self.rotation, self.force)
			self:removeTrajectoryPoints()
			self.launchTime = system.getTimer() -- This time value is needed for the trajectory points
			self.lastTrajectoryPointTime = self.launchTime
			newPuff({g = self.parent, x = self.x, y = self.y, isExplosion = true}) -- Display an explosion visual effect
			map:snapCameraTo(self.Hacked_ball)
			sounds.play('cannon')
		end
	end

	function Hacked_cannon:setForce(radius, rotation)
		self.rotation = rotation % 360
		if radius > radiusMin then
			if radius > radiusMax then
				radius = radiusMax
			end
			self.force = radius
		else
			self.force = 0
		end
		-- Only show the force indication if there is a loaded cannon ball
		if self.Hacked_ball and not self.Hacked_ball.isLaunched then
			forceArea.isVisible = true
			forceArea.xScale = 2 * radius / forceArea.width
			forceArea.yScale = forceArea.xScale
		end
		return math.min(radius, radiusMax), self.rotation
	end

	function Hacked_cannon:engageForce()
		forceArea.isVisible = false
		self.forceRadius = 0
		if self.force > 0 then
			self:fire()
		end
	end

	function Hacked_cannon:touch(event)
		if event.phase == 'began' then
			display.getCurrentStage():setFocus(self, event.id)
			self.isFocused = true
			sounds.play('cannon_touch')
		elseif self.isFocused then
			if event.phase == 'moved' then
				local x, y = self.parent:contentToLocal(event.x, event.y)
				x, y = x - self.x, y - self.y
				local rotation = math.atan2(y, x) * 180 / math.pi + 180
				local radius = math.sqrt(x ^ 2 + y ^ 2)
				self:setForce(radius, rotation)
			else
				display.getCurrentStage():setFocus(self, nil)
				self.isFocused = false
				self:engageForce()
			end
		end
		return true
	end
	Hacked_cannon:addEventListener('touch')

	-- Add white trajectory points each time interval
	function Hacked_cannon:addTrajectoryPoint()
		local now = system.getTimer()
		-- Draw them for no longer than the first value and each second value millisecods
		if now - self.launchTime < 1000 and now - self.lastTrajectoryPointTime > 85 then
			self.lastTrajectoryPointTime = now
			local point = display.newCircle(self.parent, self.Hacked_ball.x, self.Hacked_ball.y, 2)
			table.insert(trajectoryPoints, point)
		end
	end

	-- Clean the trajectory before drawing another one
	function Hacked_cannon:removeTrajectoryPoints()
		for i = #trajectoryPoints, 1, -1 do
			table.remove(trajectoryPoints, i):removeSelf()
		end
	end

	-- echFrame() is like enterFrame(), but managed by a library
	-- Track a launched ball until it stops and load another one
	function Hacked_cannon:eachFrame()
		local step = 2
	    local damping = 0.99
		if self.Hacked_ball then
			if self.Hacked_ball.isLaunched then
				local vx, vy = self.ball:getLinearVelocity()
				if vx ^ 2 + vy ^ 2 < 4 or
					self.Hacked_ball.x < 0 or
						self.Hacked_ball.x > map.map.tilewidth * map.map.width or
							self.Hacked_ball.y > map.map.tilewidth * map.map.height then
					self.Hacked_ball:destroy()
					self.Hacked_ball = nil
					self:load()
					map:moveCameraSmoothly({x = self.x - relayout._CX, y = self.y - relayout._CY, time = 1000, delay = 500})
				elseif not self.isPaused then
					self:addTrajectoryPoint()
				end
			elseif self.radiusIncrement ~= 0 or self.rotationIncrement ~= 0 then
		        self.radiusIncrement = self.radiusIncrement * damping
		        if math.abs(self.radiusIncrement) < 0.02 then
		            self.radiusIncrement = 0
		        end
				self.rotationIncrement = self.rotationIncrement * damping
		        if math.abs(self.rotationIncrement) < 0.02 then
		            self.rotationIncrement = 0
		        end
				self.forceRadius = self.forceRadius + self.radiusIncrement * step
				self.forceRadius = self:setForce(math.max(math.abs(self.forceRadius), 1), self.rotation + self.rotationIncrement * step)
		    end
		end
	end
	eachframe.add(Hacked_cannon)

	-- finalize() is called by Corona when display object is destroyed
	function Hacked_cannon:finalize()
		eachframe.remove(self)
	end
	Hacked_cannon:addEventListener('finalize')

	Hacked_cannon:prepareAmmo()
	Hacked_cannon:load()

	return Hacked_cannon
end

return _M
