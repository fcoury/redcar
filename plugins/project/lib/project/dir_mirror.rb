
module Redcar
  class Project
    class DirMirror
      class << self
        attr_accessor :show_hidden_files
        
        def show_hidden_files?
          show_hidden_files
        end
      end
        
      include Redcar::Tree::Mirror
      attr_reader :path
      
      # @param [String] a path to a directory
      def initialize(path)
        puts "DirMirror.new #{path} - #{caller.first}"
        @root ||= Adapters::RemoteFactory.new(path)
        @path = path
        @changed = true
      end
      
      def title
        @root.basename + '/'
      end
      
      # Does the directory exist?
      def exists?
        @root.exists? && @root.directory?
      end
      
      # Have the toplevel nodes changed?
      #
      # @return [Boolean]
      def changed?
        @changed
      end
      
      # Drag and drop is allowed in Dir trees
      def drag_and_drop?
        true
      end
      
      # The files and directories in the top of the directory.
      def top
        puts "DirMirror.top :: #{@root} - #{caller.first}"
        @changed = false
        Node.create_all_from_path(@root)
      end
      
      # We specify a :file data type to take advantage of OS integration.
      def data_type
        :file
      end
      
      # Return the Node for this path.
      #
      # @return [Node]
      def from_data(path)
        Node.create_from_path(path)
      end
      
      # Turn the nodes into data.
      def to_data(nodes)
        nodes.map {|node| node.path }
      end
      
      class Node
        include Redcar::Tree::Mirror::NodeMirror

        attr_reader :path

        def self.create_all_from_path(path)
          puts ":: create_all_from_path #{path.path} #{caller.first}"
          Adapters::RemoteFactory.new(path.path).contents.map {|fn| create_from_path(fn) }
        end
        
        def self.create_from_path(path)
          # puts ":: create_from_path #{path}"
          cache[path] ||= Node.new(Adapters::RemoteNode.new(path.path, path.type))
        end
        
        def self.cache
          @cache ||= {}
        end
        
        def initialize(path)
          # puts ":: initialize #{path}"
          @path = path
          @children = []
        end
        
        def text
          @path.basename
        end
        
        def icon
          if @path.file?
            :file
          elsif @path.directory?
            :directory
          end
        end
        
        def leaf?
          puts ":: leaf? #{@path}"
          file?
        end
        
        def file?
          puts ":: file? #{@path}"
          @path.file?
        end
        
        def directory?
          puts ":: directory? #{@path}"
          @path.directory?
        end
        
        def parent_dir
          puts ":: parent_dir #{@path}"
          @path.dirname
        end
        
        def directory
          puts ":: directory #{@path}"
          directory? ? @path.path : @path.dirname
        end
        
        def calculate_children
          puts ":: calculate_children #{@path.inspect}"
          (@@children||={})[path.path] = Node.create_all_from_path(@path)
        end
        
        def children
          # puts ":: children #{@path}"
          # @children
          # Node.create_all_from_path(@path)
          (@@children||={})[path.path] || []
        end
        
        def tooltip_text
          @path.basename
        end
      end
    end
  end
end
