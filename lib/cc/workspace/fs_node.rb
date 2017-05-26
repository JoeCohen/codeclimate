module CC
  class Workspace
    class FSNode
      class UnacceptablePathChunkError < StandardError; end

      def initialize(path)
        @path = Pathname(path)
        @dir = @path.directory?
        @children = {}
      end

      def initialize_copy(source)
        @children = {}
        source.children.each do |name, node|
          @children[name] = node.clone
        end
      end

      def paths
        if complete?
          [path]
        else
          children.values.flat_map(&:paths).sort
        end
      end

      def add(child, *rest)
        if directory? && (path / child).exist?
          child_node = children[child] ||= FSNode.new(path / child)
          if rest.empty?
            child_node.add_all
          else
            child_node.add(*rest)
          end
        end
      end

      def add_all
        if directory?
          path.children.each do |child_path|
            add child_path.basename.to_s
          end
        end
      end

      def remove(child, *rest)
        if directory? && children.key?(child)
          if rest.empty?
            children.delete child
          else
            children[child].remove(*rest)
            if children[child].children.empty?
              remove child
            end
          end
        end
      end

      protected

      attr_reader :path, :children

      def complete?
        (
        !directory? ||
          children.keys.sort == path.children.map { |path| path.basename.to_s }.sort &&
            children.values.all? { |child| child.complete? }
        )
      end

      def directory?
        @dir
      end
    end
  end
end
