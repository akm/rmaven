require 'rake'
require(File.join(File.dirname(__FILE__), 'lib', 'rakeable'))

Gem::Specification.new do |spec|
  spec.name = "rakeable"
  spec.version = Rakeable::VERSION
  spec.platform = Gem::Platform::RUBY
  spec.summary = "Rakeable enables using maven through rake"
  spec.author = "Takeshi Akima"
  spec.email = "rubeus@googlegroups.com"
  spec.homepage = "http://code.google.com/p/rubeus/"
  spec.rubyforge_project = "rubybizcommons"
  spec.has_rdoc = false

  spec.files = FileList['bin/*', '{lib,test}/**/*.{rb,rake}'].to_a
  spec.require_path = "lib"
  spec.requirements = ["none"]
  spec.autorequire = 'rakeable' # autorequire is deprecated
  
  bin_files = FileList['bin/*'].to_a.map{|file| file.gsub(/^bin\//, '')}
  spec.executables = bin_files

  spec.default_executable = 'rakeable'
end
