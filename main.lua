local bump = require 'bump/bump'

local world = bump.newWorld(64)

local level = {}

Vector = {}
Vector.__index = Vector
setmetatable(Vector, {
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:init(...)
		return self
	end
})
function Vector:init(x, y)
    self.x = x
    self.y = y
end

local camera = Vector(0,0)
local scale = 3
local gravity = 180

local player = {
    pos = Vector(0,0),
    velocity = Vector(0,0),
    grounded = false,
    width = 32,
    height = 32,
    speed = 140,
    jump = 200
}
function player.draw()
    love.graphics.setColor(255,0,0)
    love.graphics.rectangle("fill", player.pos.x - camera.x, player.pos.y - camera.y, player.width, player.height)
end
function player.move(dt)
	local goalX, goalY = player.pos.x + player.velocity.x * dt, player.pos.y + player.velocity.y * dt
	local actualX, actualY, cols, len = world:move(player, goalX, goalY)
	player.pos.x, player.pos.y = actualX, actualY
	if len == 0 then player.grounded = false end
	for i, col in ipairs(cols) do
		local other = col.other
		if col.normal.y == -1 then
			player.velocity.y = 0
			player.grounded = true
		elseif col.normal.y == 1 then
			player.velocity.y = 0
		end
	end
end

Platform = {}
Platform.__index = Platform
setmetatable(Platform, {
	__call = function (cls, ...)
		local self = setmetatable({}, cls)
		self:init(...)
		return self
	end
})
function Platform:init(x,y,w,h)
	self.pos = Vector(x,y)
	self.width = w
	self.height = h
	self.isPlatform = true
	world:add(self, self.pos.x, self.pos.y, self.width, self.height)
end
function Platform:draw()
	love.graphics.setColor(22, 53, 200)
	love.graphics.rectangle("fill", self.pos.x - camera.x, self.pos.y - camera.y, self.width, self.height)
end
function Platform:update(dt)
end
--[[
MovingPlatform = {}
MovingPlatform.__index = MovingPlatform
setmetatable(MovingPlatform, {
	__index = Platform,
	__call = function(cls, ...)
		local self = setmetatable({}, cls)
		self:init(...)
		return self
	end,
})

function MovingPlatform:init(x,y,w,h,d,s)
	Platform:init(self, x,y,w,h)
	self.d = d
	self.s = s
	self.t = 0
end

function MovingPlatform:update(dt)
	
end
]]
local platforms = {}
local quads = {}
local tileset = {}

function love.load()
	love.graphics.setDefaultFilter('nearest', 'nearest', 1)
	camera.width = love.graphics.getWidth() / scale
	camera.height = love.graphics.getHeight() / scale
	loadLevel("test_level")
end

function love.update(dt)
	if not player.grounded then
    	player.velocity.y = player.velocity.y + (gravity * dt)
	end
    
    if player.grounded and love.keyboard.isDown("up") then
        player.velocity.y = -player.jump
        player.grounded = false
    end
    
    if love.keyboard.isDown("left") then
        player.velocity.x = -player.speed
    elseif love.keyboard.isDown("right") then
        player.velocity.x = player.speed
    else
        player.velocity.x = 0
    end

	player.move(dt)
    
    camera.x = (player.pos.x + player.width/2) - (camera.width/2)
    camera.y = (player.pos.y + player.height/2) - (camera.height/2)
end

function love.draw()
	love.graphics.scale(scale)
    player.draw()
	drawTiles()
end

function loadLevel(level_name)
	level = require(level_name)
	tileset.img = love.graphics.newImage(level.tilesets[1].image)
	local margin, spacing = level.tilesets[1].margin, level.tilesets[1].spacing
	tileset.width = math.floor((tileset.img:getWidth() - margin) / (level.tilewidth + spacing))
	tileset.height = math.floor((tileset.img:getHeight() - margin) / (level.tileheight + spacing))
	for i = 0, tileset.height-1 do
		for j = 0, tileset.width-1 do
			local x, y = (j * (level.tilewidth + spacing)) + margin, (i * (level.tileheight + spacing)) + margin
			table.insert(quads, love.graphics.newQuad(x, y, level.tilewidth, level.tileheight, tileset.img:getWidth(), tileset.img:getHeight()))
		end
	end
	for i, layer in ipairs(level.layers) do
		if layer.type == 'objectgroup' then
			for j, obj in ipairs(layer.objects) do
				if obj.type == 'Player' then
					player.pos.x, player.pos.y = obj.x, obj.y
					world:add(player, player.pos.x, player.pos.y, player.width, player.height)
				elseif obj.type == 'Platform' then
				    table.insert(platforms, Platform(obj.x,obj.y,obj.width,obj.height))
				end
			end
		end
	end
end

function drawTiles()
	local start_x, start_y = math.max(math.floor(camera.x / level.tilewidth), 0), math.max(math.floor(camera.y / level.tileheight), 0)
	local end_x, end_y = math.min(math.floor((camera.x + camera.width) / level.tilewidth), level.width-1), math.min(math.floor((camera.y + camera.height) / level.tileheight), level.height-1)
	love.graphics.setColor(255, 255, 255, 255)
	for i = start_y, end_y do
		for j = start_x, end_x do
			local level_index = math.floor(i * level.width) + j
			for k, layer in ipairs(level.layers) do
				if layer.type == 'tilelayer' then
					local quad_index = layer.data[level_index + 1]
					if quad_index ~= 0 then
						love.graphics.draw(tileset.img, quads[quad_index], (j * level.tilewidth) - camera.x, (i * level.tileheight) - camera.y)
					end
				end
			end
		end
	end
end