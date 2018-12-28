Gem::Specification.new do |s|
  s.name = 'polyrex_calendarbase'
  s.version = '0.3.1'
  s.summary = 'A calendar object which can be output to XML format from a ' + 
      'Polyrex document object'
  s.authors = ['James Robertson']
  s.files = Dir['lib/polyrex_calendarbase.rb','stylesheet/*']
  s.add_runtime_dependency('polyrex', '~> 1.2', '>=1.2.1')
  s.add_runtime_dependency('nokogiri', '~> 1.9', '>=1.9.1') 
  s.add_runtime_dependency('chronic_duration', '~> 0.10', '>=0.10.6') 
  s.add_runtime_dependency('chronic_cron', '~> 0.5', '>=0.5.0')
  s.add_runtime_dependency('rxfhelper', '~> 0.9', '>=0.9.2') 
  s.signing_key = '../privatekeys/polyrex_calendarbase.pem'
  s.cert_chain  = ['gem-public_cert.pem']
  s.license = 'MIT'
  s.email = 'james@jamesrobertson.eu'
  s.homepage = 'https://github.com/jrobertson/polyrex_calendarbase'
end
