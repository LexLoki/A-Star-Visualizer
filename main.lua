
local a_star = require 'a_star'
local my
local is_paused=false

io.stdout:setvbuf("no")

function love.load()
	love.window.setMode(1000,1000)
	local w,h = love.graphics.getDimensions()
	my = a_star.new(50,50,w,h)
end

function love.update(dt)
	if not is_paused then
		my:update(dt)
	end
end

function love.keypressed(key)
	if key=='return' then
		if my.is_running then
			is_paused = not is_paused
		else
			my:startPathFinding()
		end
	end
end

function love.mousepressed(x,y,b)
	print(b)
	if b==1 then
		my:put_obstacle(x,y)
	else
		my:take_obstacle(x,y)
	end
end

function love.mousemoved(x,y,dx,dy)
	if love.mouse.isDown(1) then
		my:put_obstacle(x,y)
	elseif love.mouse.isDown(2) then
		my:take_obstacle(x,y)
	end
end

function love.draw()
	my:draw()
end