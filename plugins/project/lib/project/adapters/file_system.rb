module Redcar
  class Project
    module Adapters
      class LocalFile
        def self.stat(file)
          File.stat(file)
        end

        def self.exists?(file)
          File.exists?(file)
        end

        def self.load(file)
          File.open(file, 'rb') do |f|; f.read; end
        end

        def self.save(file, contents)
          File.open(file, "wb") {|f| f.print contents }
        end
      end
      
      class FileSystem
        attr_reader :path
        
        def initialize(path)
          puts "FileSystem.initialize #{path}"
          @path = path
        end
        
        def basename
          puts "FileSystem.basename #{path}"
          File.basename(@path)
        end
        
        def exist?
          puts "FileSystem.exist? #{@path}"
          File.exist?(@path)
        end
        
        def directory?
          puts "FileSystem.directory? #{@path}"
          File.directory?(@path)
        end
        
        def file?
          puts "FileSystem.file? #{@path}"
          File.file?(@path)
        end
        
        def dirname
          puts "FileSystem.dirname #{@path}"
          File.dirname(@path)
        end
        
        def contents
          puts "FileSystem.contents #{@path}"
          fs = Dir.glob(path + "/*", File::FNM_DOTMATCH)
          fs = fs.reject {|f| [".", ".."].include?(File.basename(f))}
          unless DirMirror.show_hidden_files?
            fs = fs.reject {|f| File.basename(f) =~ /^\./ }
          end
          fs.sort_by do |fn|
            File.basename(fn).downcase
          end.sort_by do |path|
            File.directory?(path) ? -1 : 1
          end
        end
      end
    end
  end
end