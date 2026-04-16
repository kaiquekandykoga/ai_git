require_relative "lib/ai_git/version"

Gem::Specification.new do |spec|
  spec.name          = 'ai_git'
  spec.version       = AIGit::VERSION
  spec.summary       = 'AI‑powered Git commit + push tool using SLMs'
  spec.description   = 'AI‑powered Git commit + push tool using SLMs'
  spec.license      = 'BSD-3-Clause'
  spec.author       = 'Kaíque Kandy Koga'
  spec.files        = Dir['lib/**/*.rb', 'bin/ai_git']
  spec.executables = ['ai_git']
  spec.requirements = []
  spec.required_ruby_version = '>= 4.0'

  spec.homepage = 'https://github.com/kaiquekandykoga/ai_git'
end
