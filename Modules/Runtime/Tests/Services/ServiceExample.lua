local Service = {}

function Service.OnInit(self: Service)
	print("Service 'OnInit' called!")
end

export type Service = typeof(Service)

return Service
