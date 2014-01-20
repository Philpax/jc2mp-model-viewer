function ModelViewer:__init()	; EventBase.__init(self)
								; NetworkBase.__init(self)
	self:NetworkSubscribe('ChangeObject')
	self:EventSubscribe('ModuleUnload')
	self:EventSubscribe('PlayerQuit')

	self.objects = {}

	DefaultWorld:SetTime(12)
	DefaultWorld:SetTimeStep(0)
end

function ModelViewer:CleanupPlayer(player)
	local id = player:GetId()
	
	if self.objects[id] then
		self.objects[id]:Remove()
	end
	
	self.objects[id] = nil
end

function ModelViewer:ModuleUnload()
	for k, v in pairs(self.objects) do
		if self.objects[k] then
			self.objects[k]:Remove()
		end
	end
end

function ModelViewer:PlayerQuit(e)
	self:CleanupPlayer(e.player)
end

function ModelViewer:ChangeObject(e, sender)
	self:CleanupPlayer(sender)

	if string.sub(e.archive, string.len(e.archive)) == 'z' then
		e.archive = string.sub(e.archive, 1, string.len(e.archive) - 1)
	end

	self.objects[sender:GetId()] = StaticObject.Create({
		model = e.archive .. '/' .. e.lod,
		collision = e.archive .. '/' .. e.physics,
		position = e.position,
		angle = Angle(),
		fixed = false
	})

	print('Loaded ' .. self.objects[sender:GetId()]:GetModel())
end