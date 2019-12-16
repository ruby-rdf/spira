guard "ctags-bundler", emacs: true do
  watch(/^(lib|spec\/support)\/.*\.rb$/)
  watch("Gemfile.lock")
end

guard "rspec" do
  watch(/^lib\/.*\.rb$/) { "spec" }
  watch(/^spec\/.*_spec\.rb$/)
end
