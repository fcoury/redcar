module Redcar
  class Project
    class TransferSpeedbar < Redcar::Speedbar
      class << self
        attr_accessor :action
        attr_accessor :target
      end
      
      label :label, "Please wait, #{self.action} #{self.target}..."
    end
  end
end