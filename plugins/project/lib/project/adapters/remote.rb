require 'net/ssh'
require 'net/sftp'
require 'fileutils'

module Redcar
  class Project
    module Adapters
      class RemoteConnection
        def self.host
          '12.200.147.200'
        end
        
        def self.user
          'git'
        end
        
        def self.password
          'teste'
        end
        
        def self.connection
          @@connection ||= begin
            print "Connecting to #{host}... "
            ret = Net::SSH.start(host, user, :password => password)
            puts "done!"
            ret
          end
        end
      end
      
      class RemoteFile
        def self.connection
          RemoteConnection.connection
        end
        
        def self.sftp
          self.connection.sftp
        end
        
        def self.stat(file)
          sftp.stat!(file)
        end
        
        def self.exists?(file)
          (@exist||={})[file] ||= connection.exec!("test -e #{file} && echo y") =~ /^y/
        end
        
        def self.paths(file)
          base_temp = '/tmp'
          file_name = File.basename(file)
          path = File.dirname(file)
          
          local_path = "#{base_temp}/#{RemoteConnection.host}#{path}"
          local_file = "#{local_path}/#{file_name}"
          
          [local_path, local_file]
        end
        
        def self.load(file)
          local_path, local_file = paths(file)

          print "Downloading: #{file} as: #{local_file}... "
          FileUtils.mkdir_p local_path
          sftp.download! file, local_file
          puts "done"
          File.open(local_file, 'rb') do |f|; f.read; end
        end
        
        def self.save(file, contents)
          local_path, local_file = paths(file)
          
          ret = File.open(local_file, "wb") {|f| f.print contents }
          print "Uploading: #{local_file} as #{file}... "
          sftp.upload! local_file, file
          puts "done"
          ret
        end
      end
      
      class RemoteFactory
        attr_reader :path

        def initialize(path)
          @path = path
          @basename = File.basename(path)
          puts "RemoteFactory.new #{@path} #{@basename}"
        end
        
        def connection
          RemoteConnection.connection
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