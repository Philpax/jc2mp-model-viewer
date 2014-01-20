function ModelViewer:__init()	; EventBase.__init(self)
								; NetworkBase.__init(self)

	self:EventSubscribe( "PlayerChat" )
	self:EventSubscribe( "PlayerQuit" )
	self:EventSubscribe( "ModuleUnload" )

	self:NetworkSubscribe( "RequestObjectChange" )
	self:NetworkSubscribe( "TimeChange" )

	self.position = Vector3( 4339, 6175, -4631 )
	self.viewers = {}

	self.world = World.Create()
	self.world:SetTime( 12 )
	self.world:SetTimeStep( 0 )
end

function ModelViewer:SetCurrentObject( model, collision )
	if self.object then
		self.object:Remove()
		self.object = nil
	end

	self.object = StaticObject.Create
	{
		model = model, -- Model path

		collision = collision, -- Physics path (can be nil or empty)

		position = self.position,

		angle = Angle(),

		world = self.world,	-- The world in which to spawn this object in 
							-- (DefaultWorld by default)
		enabled = true, -- Whether this object is visible to players (true by default)

		fixed = true 	-- Whether this object is fixed in the world (true by default);
						-- if you set this to false, the object uses physics to simulate
						-- movement between positions, allowing for the creation of moving
						-- objects with players on them; however, this may reduce performance
						-- and introduce physics glitches, so only disable fixed when 100%
						-- necessary
	}

	self.object:SetStreamDistance( 2000 )

	print( "Loaded " .. model )
	Network:SendToPlayers( self.viewers, "ObjectChange", { model, collision } )
end

function ModelViewer:IsPlayerActive( player )
	return self.viewers[ player:GetId() ] ~= nil
end

function ModelViewer:AddPlayer( player )
	self.viewers[ player:GetId() ] = player
	player:SetWorld( self.world )

	local model = ""
	local collision = ""

	if self.object then
		model = self.object:GetModel()
		collision = self.object:GetCollision()
	end

	Network:Send( player, "PlayerJoinView", 
		{ model, collision, self.position } )
end

function ModelViewer:RemovePlayer( player )
	self.viewers[ player:GetId() ] = nil
	player:SetWorld( DefaultWorld )

	Network:Send( player, "PlayerQuitView" )
end

-- Events
function ModelViewer:PlayerChat( e )
	if e.text == "/modelviewer" then
		if not self:IsPlayerActive( e.player ) then
			if e.player:GetWorld() == DefaultWorld then
				self:AddPlayer( e.player )
			else
				e.player:SendChatMessage( 
					"You are not in the main world!",
					Color.Red )
			end

			return false
		else
			self:RemovePlayer( e.player )

			return false
		end
	end

	return true
end

function ModelViewer:PlayerQuit( e )
	self:RemovePlayer( e.player )
end

function ModelViewer:ModuleUnload()
	if self.object then
		self.object:Remove()
	end
end

-- Network Events
function ModelViewer:RequestObjectChange( e, sender )
	-- Could pop up a vote on whether to change the current
	-- model or not
	local model = e[1] .. "/" .. e[2]
	local collision = e[1] .. "/" .. e[3]
	self:SetCurrentObject( model, collision )
end

function ModelViewer:TimeChange( time, sender )
	self.world:SetTime( time )

	Network:SendToPlayers( self.viewers, "TimeChange", { time, sender } )
end