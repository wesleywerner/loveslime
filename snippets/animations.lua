
-- _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _
--              _                 _   _
--   __ _ _ __ (_)_ __ ___   __ _| |_(_) ___  _ __  ___
--  / _` | '_ \| | '_ ` _ \ / _` | __| |/ _ \| '_ \/ __|
-- | (_| | | | | | | | | | | (_| | |_| | (_) | | | \__ \
--  \__,_|_| |_|_|_| |_| |_|\__,_|\__|_|\___/|_| |_|___/
--

--- Draw an actor's animation frame.
--
-- @tparam actor entity
-- The actor to draw.
--
-- @local
function animations:getDrawParameters (entity)

	-- if this actor has a still image
	if entity.image then
		if entity.x and entity.feet then
			local x, y = entity.drawX, entity.drawY
			local sx, sy = 1, 1
			local r, ox, oy = 0, 0, 0
			-- flip when going east
			if entity.direction == "east" then
				sx = -1
				ox = entity.width
			end
			return entity.image, x, y, r, sx, sy, ox, oy
		end
	end

	local sprites = entity.sprites

	if not sprites then
		return
	end

	local frames = sprites.animations[entity.key]

	if frames then

		local frame = frames[sprites.index]

		if not frame.quad then
			frame.quad = love.graphics.newQuad (
				frame.x, frame.y,
				frame.width, frame.height,
				sprites.size.width, sprites.size.height)
		end

		-- position
		local x, y = entity.drawX, entity.drawY
		-- rotation
		local r = 0
		-- scale
		local sx, sy = 1, 1
		-- origin
		local ox, oy = 0, 0

		-- invert scale to flip
		if frame.flip == true then
			sx = -1
			ox = entity.width
		end

		local tileset = cache(entity.sprites.filename)

		return tileset, frame.quad, x, y, r, sx, sy, ox, oy

	end

end


--- Update animation.
--
-- @tparam actor entity
-- The entity to update.
--
-- @tparam int dt
-- Delta time since last update.
--
-- @local
function animations:update (entity, dt)

	-- entity.sprites: sprite animation definition
	-- entity.name: fed back to the event.animation callback on loop
	-- entity.key: animation key to update
	-- entity.x, entity.y: position on screen

	local sprites = entity.sprites

	-- if there are no sprites, only a still image
	if not sprites and entity.image then
		if entity.x and entity.feet then
			entity.drawX = entity.x - entity.feet.x
			entity.drawY = entity.y - entity.feet.y
		end
		return
	end

	if not sprites then
		return
	end

	local frames = sprites.animations[entity.key]

	if not frames then
		return
	end

	-- initialize and clamp the index.
	-- when switching between animation keys, the index
	-- is not reset.
	sprites.index = sprites.index or 1
	sprites.index = math.min (sprites.index, #frames)

	if frames then

		local frame = frames[sprites.index]

		if not frame then
			print (sprites.index, #frames, entity.key, sprites.lastkey)
			error ("frame is empty")
		end
		sprites.lastkey = entity.key

		-- reduce the frame timer
		sprites.timer = (sprites.timer or 1) - dt

		if sprites.timer <= 0 then

			-- move to the next frame
			sprites.index = sprites.index + 1

			-- wrap the animation
			if sprites.index > #frames then
				-- animation loop ended
				sprites.index = 1
				-- reload the correct frame
				frame = frames[sprites.index]
				-- notify event
				events.animation (actor, entity.key)
			end

			-- set the timer for this frame
			sprites.timer = frame.delay or 0.2

		end

		if not frame then
			print (sprites.index, entity.key, #frames)
			error ("frame is empty")
		end

		-- update the draw offset for actor sprites
		if entity.x and entity.feet then
			entity.drawX = entity.x - entity.feet.x + frame.xoffset
			entity.drawY = entity.y - entity.feet.y + frame.yoffset
		end

	end

end
