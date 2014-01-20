function ModelViewer:__init()	; EventBase.__init(self)
								; NetworkBase.__init(self)
	
	self.window = Window.Create()
	self.window:SetSizeRel( Vector2( 0.3, 1 ) )
	self.window:SetPosition( 
		Vector2( Render.Width - self.window:GetWidth(), 0 ) )
	self.window:SetTitle( "Model Viewer" )
	self.window:SetVisible( false )

	self.tree = Tree.Create( self.window )
	self.tree:SetDock( GwenPosition.Fill )

	self.physics_text = Label.Create( self.window )
	self.physics_text:SetDock( GwenPosition.Bottom )
	self.physics_text:SetText( "Collision: Nothing selected" )
	self.physics_text:SetHeight(16)
	self.physics_text:SetAlignment( GwenPosition.Bottom )

	self.model_text = Label.Create( self.window )
	self.model_text:SetDock( GwenPosition.Bottom )
	self.model_text:SetText( "Model: Nothing selected" )
	self.model_text:SetHeight(16)
	self.model_text:SetAlignment( GwenPosition.Bottom )

	self.locked_text = Label.Create( self.window )
	self.locked_text:SetDock( GwenPosition.Bottom )
	self.locked_text:SetText( "Locked: false" )
	self.locked_text:SetHeight(16)
	self.locked_text:SetAlignment( GwenPosition.Bottom )

	self.position = Vector3.Zero

	self:NetworkSubscribe( "ObjectChange" )
	self:NetworkSubscribe( "PlayerJoinView" )
	self:NetworkSubscribe( "PlayerQuitView" )
	self:EventSubscribe( "LocalPlayerInput" )

	self.input_timer = Timer()

	for k, v in ipairs( models ) do
		node = self.tree:AddNode( v.name )

		for k2, v2 in ipairs( v.files ) do
			child_node = node:AddNode( v2.model )
			child_node:Subscribe( "Select", self, self.ModelSelected )
		end
	end
end

function ModelViewer:SetActive( active )
	self.window:SetVisible( active )

	if active then
		self.orbit_camera = OrbitCamera()
		self.orbit_camera.targetPosition = self.position
	else
		self.orbit_camera:Destroy()
		self.orbit_camera = nil
	end
end

function ModelViewer:GetLock()
	return self.orbit_camera.locked
end

function ModelViewer:SetLock( lock )
	Mouse:SetVisible( lock )
	self.orbit_camera.locked = not self.orbit_camera.locked
	self.locked_text:SetText( 
		"Locked: " .. tostring( self.orbit_camera.locked ) )
end

-- Events
function ModelViewer:ObjectChange( e )
	self.model_text:SetText( "Model: " .. e[1] )
	self.physics_text:SetText( "Collision: " .. e[2] )
end

function ModelViewer:PlayerJoinView( e )
	self.position = e[3]
	self:ObjectChange( e )
	self:SetActive( true )
end

function ModelViewer:PlayerQuitView( e )
	self:SetActive( false )
end

function ModelViewer:LocalPlayerInput( e )
	if not self.window:GetVisible() then return true end

	if e.input == Action.Reload then
		if self.input_timer:GetSeconds() > 0.25 then
			self:SetLock( not self:GetLock() )
			self.window:SetEnabled( self:GetLock() )

			self.input_timer:Restart()
			return false
		end
	end

	if self.orbit_camera.locked then return false end

	return true
end

function ModelViewer:ModelSelected( window )
	local lod = window:GetText()
	local archive = window:GetParent():GetText()
	local physics = ""

	-- Dirty++
	for k, v in ipairs(models) do
		if v.name == archive then
			for k2, v2 in pairs(v.files) do
				if v2.model == lod then
					physics = v2.physics
					break
				end
			end
		end
	end

	archive = FileName.basename( archive, "\\" )

	Network:Send( "RequestObjectChange", { archive, lod, physics } )
end