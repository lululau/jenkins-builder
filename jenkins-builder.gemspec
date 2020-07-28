
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "jenkins/builder/version"

Gem::Specification.new do |spec|
  spec.name          = "jenkins-builder"
  spec.version       = Jenkins::Builder::VERSION
  spec.authors       = ["Liu Xiang"]
  spec.email         = ["liuxiang921@gmail.com"]

  spec.summary       = %{Build Jenkins Jobs}
  spec.description   = %{Build Jenkins Jobs}
  spec.homepage      = "https://github.com/lululau/jenkins-builder"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'thor', '~> 0.20.0'
  spec.add_dependency 'jenkins_api_client', '~> 1.5.3'
  spec.add_dependency 'security', '~> 0.1.3'
  spec.add_dependency 'pastel', '~> 0.7.2'
  spec.add_dependency 'tty-spinner', '~> 0.8.0'
  spec.add_dependency 'ferrum', '~> 0.9'

  spec.add_development_dependency "bundler", "~> 2.1.2"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry", "~> 0.11.3"
  spec.add_development_dependency "pry-doc", "~> 0.13.4"
  spec.add_development_dependency "pry-byebug", "~> 3.6.0"
end
