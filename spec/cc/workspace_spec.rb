require "spec_helper"

module CC
  describe Workspace do
    include FileSystemHelpers

    around { |example| within_temp_dir(&example) }

    it "responds with added paths, if unfiltered" do
      make_tree <<-EOM
        foo/thing.rb
        foo/other.rb
        bar/baz.rb
        nope/also_nope.rb
      EOM

      workspace = Workspace.new
      workspace.add(%w[foo bar/baz.rb])
      expect(workspace.paths).to eq %w[bar/ foo/]
    end

    it "doesn't remove if given nil or empty exclude_paths" do
      make_tree <<-EOM
        foo.rb
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(nil)
      workspace.remove([])
      expect(workspace.paths).to eq ["./"]
    end

    it "filters to a minimized set of paths in the current directory" do
      make_tree <<-EOM
        .bundle/vendor/dependency.rb
        .bundle/vendor/dependency/inner.rb
        .git/FETCH_HEAD
        .git/refs/heads/master
        .gitignore
        .node_modules/crazy/stuff
        .node_modules/other/crazy/stuff
        Gemfile
        Gemfile.lock
        app/assets/vendor/javascripts/ouch.js
        app/assets/vendor/stylesheets/ouch.css
        lib/foo.rb
        lib/foo/bar.rb
        lib/foo/baz.rb
        lib/quix/a.rb
        lib/quix/b.rb
        spec/foo/bar_spec.rb
        spec/foo/baz_spec.rb
        spec/foo_spec.rb
        vendor/assets/jquery.js
        vendor/assets/underscore.js
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(%w[
        .bundle
        .git
        .gitignore
        .node_modules/**/*
        app/assets/vendor
        spec/foo/baz_spec.rb
        vendor/**
      ])

      expect(workspace.paths).to eq %w[
        Gemfile
        Gemfile.lock
        lib/
        spec/foo/bar_spec.rb
        spec/foo_spec.rb
      ]
    end

    it "can be filtered again, e.g. per engine" do
      make_tree <<-EOM
        .node_modules/crazy/stuff
        .node_modules/other/crazy/stuff
        Gemfile
        Gemfile.lock
        lib/foo.rb
        lib/foo/bar.rb
        lib/foo/baz.rb
        lib/quix/a.rb
        lib/quix/b.rb
        skeleton/torso/ribcage/heart.rb
        skeleton/torso/belly/liver.rb
        spec/foo/bar_spec.rb
        spec/foo/baz_spec.rb
        spec/foo_spec.rb
        vendor/assets/jquery.js
        vendor/assets/underscore.js
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(%w[.node_modules])
      workspace2 = workspace.clone
      workspace2.remove(%w[vendor **/ribcage/**])

      expect(workspace.paths).to eq %w[
        Gemfile
        Gemfile.lock
        lib/
        skeleton/
        spec/
        vendor/
      ]
      expect(workspace2.paths).to eq %w[
        Gemfile
        Gemfile.lock
        lib/
        skeleton/torso/belly/
        spec/
      ]
    end

    it "supports patterns" do
      make_tree <<-EOM
        lib/foo.py
        lib/foo.pyc
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(%w[**/*.pyc])

      expect(workspace.paths).to eq %w[lib/foo.py]
    end

    it "supports negated exclude patterns" do
      make_tree <<-EOM
        lib/foo.py
        lib/foo.pyc
        lib/fafa.pyc
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(%w[**/*.pyc !lib/fafa.pyc])

      expect(workspace.paths).to eq %w[lib/fafa.pyc lib/foo.py]
    end

    it "supports negated exclude patterns and also this respects globs" do
      make_tree <<-EOM
        test/dog.rb
        test/test_helper.rb
        test/dog_helper.rb
        test/something_else_helper.rb
      EOM

      workspace = Workspace.new
      workspace.add_all
      workspace.remove(%w[test/*.rb !test/*_helper.rb test/dog_helper.rb])

      expect(workspace.paths).to eq %w[test/something_else_helper.rb test/test_helper.rb]
    end

    it "can be given an explicit set of initial paths" do
      make_tree <<-EOM
        .bundle/vendored/bar.rb
        .bundle/vendored/foo.rb
        Gemfile
        Gemfile.lock
        lib/foo.rb
        lib/foo/bar.rb
        lib/foo/baz.rb
        spec/foo/bar_spec.rb
        spec/foo/baz_spec.rb
        spec/foo_spec.rb
        vendor/foo.js
        vendor/foo/bar.css
      EOM

      workspace = Workspace.new
      workspace.add(%w[lib/foo spec/foo/bar_spec.rb])
      workspace.remove(%w[lib/foo/bar.rb])

      expect(workspace.paths).to eq %w[
        lib/foo/baz.rb
        spec/foo/bar_spec.rb
      ]
    end

    it "adds all files when adding ./" do
      make_tree <<-EOM
        .bundle/vendored/bar.rb
        Gemfile
        Gemfile.lock
        lib/foo.rb
        spec/foo_spec.rb
        vendor/foo.js
      EOM

      workspace = Workspace.new
      workspace.add(%w[./])

      expect(workspace.paths).to eq %w[
        ./
      ]
    end

    it "raises an exception when trying to add files outside of workspace root" do
      make_tree <<-EOM
        lib/foo.rb
      EOM

      workspace = Workspace.new
      expect do
        workspace.add(%w[lib/../../])
      end.to raise_error(described_class::EscapeError)
    end

    describe "relative path arguments" do
      it "supports adding the current path" do
        make_tree <<-EOM
          foo.txt
          foo/bar.rb
        EOM

        workspace = Workspace.new
        workspace.add(%w[./])
        expect(workspace.paths).to eq ["./"]
      end

      it "supports adding the current path" do
        make_tree <<-EOM
          foo.rb
          bar.rb
          other/stuff.txt
        EOM

        workspace = Workspace.new
        workspace.add(%w[./foo.rb])
        expect(workspace.paths).to eq ["foo.rb"]
      end
    end
  end
end
