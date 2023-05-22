# frozen_string_literal: true

require_relative "lib/peplum/version"

Gem::Specification.new do |spec|
  spec.name = "peplum"
  spec.version = Peplum::VERSION
  spec.authors = ["Tasos Laskos"]
  spec.email = ["tasos.laskos@gmail.com"]

  spec.summary = "Distributed computing made easy."
  spec.description = "Distributed computing made easy."
  spec.homepage = "http://ecsypno.com/"
  spec.required_ruby_version = ">= 2.6.0"

  spec.files  = Dir.glob( 'bin/*')
  spec.files += %w(bin/.gitkeep)
  spec.files += Dir.glob( 'lib/**/*')
  spec.files += Dir.glob( 'examples/**/*')
  spec.files += %w(peplum.gemspec)

  spec.add_dependency 'cuboid'
end
