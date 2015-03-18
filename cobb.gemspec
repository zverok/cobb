require './lib/cobb/version'
 
Gem::Specification.new do |s|
  s.name = 'cobb'
  s.version = Cobb::VERSION
  s.authors = ['Victor Shepelev']
  s.email = 'zverok.offline@gmail.com'
  s.description = <<-EOF
    Yet another web scraping library, targeting
  EOF
  s.summary = 'Pretty word cloud maker for Ruby'
  s.homepage = 'http://github.com/zverok/cobb'
  s.licenses = ['MIT']

  s.files = `git ls-files`.split($RS).reject do |file|
    file =~ /^(?:
    spec\/.*
    |Gemfile
    |Rakefile
    |\.rspec
    |\.gitignore
    |\.rubocop.yml
    |\.rubocop_todo.yml
    |\.travis.yml
    |.*\.eps
    )$/x
  end
  s.executables = s.files.grep(/^bin\//) { |f| File.basename(f) }
  
  s.require_paths = ["lib"]
  s.rubygems_version = '2.2.2'
  
  s.add_dependency 'faraday'
  s.add_dependency 'hashie'
  s.add_dependency 'naught'
  s.add_dependency 'addressable'
  s.add_dependency 'naught'
  
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'bundler'
  s.add_development_dependency 'ruby-prof'
end
