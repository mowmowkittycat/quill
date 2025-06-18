local RunService = game:GetService("RunService")

local chapter = {}


function chapter:init()
	
	self.connection = RunService.Stepped:Connect(function()
		self:run_chapter_method(true)
	end)
end

function chapter:destroy()
	if self.connection then
		self.connection:Disconnect()
	end
end


return chapter