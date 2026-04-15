require_relative "lib/ai_git/version"

Gem::Specification.new do |spec|
  spec.name          = 'ai_git'
  spec.version       = AIGit::VERSION
  spec.summary       = 'AI-powered git commit and push tool using Ollama'
  spec.description   = 'Generates intelligent commit messages using Ollama LLMs'
  spec.license      = 'BSD-3-Clause'
  spec.author       = 'Kaíque Kandy Koga'
  spec.files        = Dir['lib/**/*.rb', 'bin/ai_git']
  spec.executables = ['ai_git']
  spec.requirements = []
  spec.required_ruby_version = '>= 4.0'

  spec.homepage = 'https://github.com/koga/ai_git'
end
