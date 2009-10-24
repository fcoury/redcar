
module Redcar
  # Each Redcar::Document is associated with an EditView, and has methods for
  # reading and modifying the contents of the EditView. Every document has a
  # Mirror of some resource.
  #
  # Events: new_mirror
  class Document
    include Redcar::Model
    include Redcar::Observable
    
    class << self
      attr_accessor :default_mirror
    end
    
    attr_reader :mirror
    
    def initialize(edit_view)
      @edit_view = edit_view
    end
    
    def to_s
      controller.to_s
    end
    
    def text=(text)
      controller.text = text
    end
    
    def mirror=(new_mirror)
      notify_listeners(:new_mirror, new_mirror) do
        @mirror = new_mirror
        update_from_mirror
      end
    end
    
    private
    
    def update_from_mirror
      self.text = mirror.read
    end
  end
end