require "cc/workspace/fs_node"

module CC
  class Workspace
    autoload :Exclusion, "cc/workspace/exclusion"

    class EscapeError < StandardError; end

    def initialize(work_dir = ".")
      @work_dir = Pathname(work_dir).expand_path.freeze
      @root_node = FSNode.new(@work_dir)
    end

    def initialize_copy(source)
      @work_dir = source.work_dir.clone
      @root_node = source.root_node.clone
    end

    def paths
      Dir.chdir(work_dir) do
        root_node.paths.map do |path|
          relative_path = path.relative_path_from(work_dir)
          if relative_path.directory?
            relative_path.to_s + "/"
          else
            relative_path.to_s
          end
        end
      end
    end

    def add(paths)
      Array(paths).each do |path|
        path = Pathname(path)
        contain! path
        path_chunks = normalized_path_chunks(path)
        if path_chunks == ["."]
          root_node.add_all
        else
          root_node.add(*path_chunks)
        end
      end
    end

    def add_all
      root_node.add_all
    end

    def remove(patterns)
      Array(patterns).each do |pattern|
        exclusion = Exclusion.new(pattern)
        paths = Dir.chdir(work_dir) { exclusion.expand }
        if exclusion.negated?
          paths.each { |path| add path }
        else
          paths.each do |path|
            path = Pathname(path)
            contain! path
            root_node.remove(*normalized_path_chunks(path))
          end
        end
      end
    end

    protected

    attr_reader :work_dir, :root_node

    private

    def contain!(path)
      if path.
         expand_path(work_dir).
         cleanpath.
         relative_path_from(work_dir).
         to_s.start_with? ".."
        raise EscapeError, "Workspace at #{work_dir} can not handle #{path} because it's outside of it."
      end
    end

    def normalized_path_chunks(path)
      path.
        expand_path(work_dir).
        cleanpath.
        relative_path_from(work_dir).
        each_filename.to_a
    end
  end
end
