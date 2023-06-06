function love.conf(t)
	local love_major, love_minor = love.getVersion()

	t.window.title = "AtlasB (Binary Tree) Demo (LÖVE " .. love_major .. "." .. love_minor .. ")"
	t.window.resizable = true
end
