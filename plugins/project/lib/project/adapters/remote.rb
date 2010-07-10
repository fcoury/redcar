require 'net/ssh'
require 'net/sftp'
require 'pathname'

module Redcar
  class Project
    module Adapters
      class RemoteFactory
        attr_reader :path

        def initialize(path)
          @path = path
          @basename = File.basename(path)
          @host = 'fcoury.info'
          @user = 'fcoury'
          @pass = 'dreamtempra13'
          
          puts "RemoteFactory.new #{@path} #{@basename}"
        end
        
        def connection
          @@connection ||= begin
            print "Connecting to #{@host}... "
            ret = Net::SSH.start(@host, @user, :password => @pass)
            puts "done!"
            ret
          end
        end
        
        def basename
          @basename
        end
        
        def exec(what)
          puts "Exec: #{what}"
          connection.exec! what
        end
        
        def exists?
          @exist ||= (exec("test -e #{@path} && echo y") =~ /^y/)
        end
        
        def directory?
          @directory ||= (exec("test -d #{@path} && echo y") =~ /^y/)
        end
        
        def contents
          contents = []
          result = exec %Q(
            for file in #{@path}/*; do 
              test -f "$file" && echo "file|$file"
              test -d "$file" && echo "dir|$file"
            done
          )
          
          return [] unless result
          
          result.each do |line|
            type, name = line.chomp.split('|')
            unless ['.', '..'].include?(name)
              contents << RemoteNode.new("#{name}", type)
              puts ":: contents :: Type: #{type} | Name: #{name}"
            end
          end
          
          contents.sort_by do |c|
            c.basename
          end.sort_by do |c|
            c.directory? ? -1 : 1
          end.tap do |c|
            # puts "Contents: #{c.map(&:basename).inspect}"
          end
        end
      end

      class RemoteNode
        attr_reader :path, :type
        
        def initialize(path, type='dir')
          @path = path
          @basename = File.basename(@path)
          @type = type
          # puts "RemoteNode.new #{path} #{type} #{@basename}"
        end
        
        def basename
          @basename
        end
        
        def exist?
          true
        end
        
        def directory?
          @type == 'dir'
        end
        
        def file?
          @type == 'file'
        end
        
        def dirname
          @path
        end
        
        def contents
          RemoteFactory.new(path).contents
        end
      end
    end
  end
end