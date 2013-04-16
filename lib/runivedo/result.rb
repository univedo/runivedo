module Runivedo
  class Result < RemoteObject
    include Enumerable
    RemoteObject.register_ro_class('UResult', self)

    
  end
end
