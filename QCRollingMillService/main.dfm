object Service1: TService1
  OldCreateOrder = False
  OnCreate = ServiceCreate
  DisplayName = 'Service1'
  AfterInstall = ServiceAfterInstall
  OnShutdown = ServiceShutdown
  OnStart = ServiceStart
  OnStop = ServiceStop
  Height = 150
  Width = 215
end
