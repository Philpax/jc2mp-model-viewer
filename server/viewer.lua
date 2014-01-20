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
		v:Remove()
	end
end

function ModelViewer:PlayerQuit(e)
	self:CleanupPlayer(e.player)
end

function ModelViewer:ChangeObject(e, sender)
	self:CleanupPlayer(sender)

	self.objects[sender:GetId()] = StaticObject.Create
	{
		model = e.archive .. '/' .. e.lod,
		collision = e.archive .. '/' .. e.physics,
		position = e.position,
		angle = Angle()
	}

	print('Loaded ' .. self.objects[sender:GetId()]:GetModel())
end