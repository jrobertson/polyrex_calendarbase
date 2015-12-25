Gem::Specification.new do |s|
  s.name = 'polyrex_calendarbase'
  s.version = '0.2.3'
  s.summary = 'A calendar object which can be output to XML format from a Polyrex document object'
  s.authors = ['James Robertson']
  s.files = Dir['lib/polyrex_calendarbase.rb']
  s.add_runtime_dependency('polyrex', '~> 1.0', '>=1.0.6')
  s.add_runtime_dependency('nokogiri', '~> 1.6', '>=1.6.6.2') 
  s.add_runtime_dependency('chronic_duration', '~> 0.10', '>=0.10.4') 
  s.add_runtime_dependency('chronic_cron', '~> 0.3', '>=0.3.1')
  s.add_runtime_dependency('rxfhelper', '~> 0.2', '>=0.2.3') 
  s.signing_key = '../privatekeys/polyrex_calendarbase.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@r0bertson.co.uk'
  s.homepage = 'https://github.com/jrobertson/polyrex_calendarbase'
end
