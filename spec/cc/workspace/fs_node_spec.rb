require "spec_helper"

module CC
  class Workspace
    describe FSNode do
      include FileSystemHelpers

      subject(:node) { described_class.new(".") }

      around do |example|
        within_temp_dir do
          make_fixture_tree

          example.run
        end
      end

      it "doesn't needlessly descend if nothing excluded" do
        node.add_all
        expect(node.paths).to eq [Pathname(".")]
      end

      it "excludes files, descending as needed" do
        node.add_all
        node.remove ".git", "refs"
        node.remove "code", "a", "bar.rb"
        expect(node.paths).to eq [Pathname(".git/FETCH_HEAD"), Pathname("code/a/baz.rb"), Pathname("code/foo.rb"), Pathname("foo.txt"), Pathname("lib")]
      end

      it "includes files, descending as needed" do
        node.add ".git", "refs"
        node.add "code", "foo.rb"
        node.add "code", "a", "bar.rb"
        expect(node.paths).to eq [Pathname(".git/refs"), Pathname("code/a/bar.rb"), Pathname("code/foo.rb")]
      end

      it "excludes files after explicit includes" do
        node.add ".git", "refs"
        node.add "code"
        node.remove ".git", "refs", "heads", "master"
        node.remove "code", "a", "bar.rb"
        expect(node.paths).to eq [Pathname("code/a/baz.rb"), Pathname("code/foo.rb")]
      end

      it "excludes directory after excluding only part of it" do
        node.add_all
        node.remove "code", "a", "bar.rb"
        node.remove "code"
        expect(node.paths).to eq [Pathname(".git"), Pathname("foo.txt"), Pathname("lib")]
      end

      it "excludes directory after excluding all files in i" do
        node.add_all
        node.remove "code", "a", "bar.rb"
        node.remove "code", "a", "baz.rb"
        node.remove "code", "foo.rb"
        expect(node.paths).to eq [Pathname(".git"), Pathname("foo.txt"), Pathname("lib")]
      end

      it "handles including nonexistent files" do
        node.add "does-not-exist"
        expect(node.paths).to eq []
      end

      it "handles excluding nonexistent files" do
        node.add_all
        node.remove "code", "does-not-exist"
        expect(node.paths).to eq [Pathname(".")]
      end

      def make_fixture_tree
        make_tree <<-EOM
          .git/FETCH_HEAD
          .git/refs/heads/master
          code/a/bar.rb
          code/a/baz.rb
          code/foo.rb
          foo.txt
          lib/thing.rb
        EOM
      end
    end
  end
end
