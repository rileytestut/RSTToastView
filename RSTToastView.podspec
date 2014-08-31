Pod::Spec.new do |s|
  s.name         = 'RSTToastView'
  s.version      = '0.1'
  s.homepage     = 'http://rileytestut.com/'
  s.platform     = :ios
  s.ios.deployment_target = '7.0'
  s.license      = 'MIT'
  s.author = {
    'Riley Testut' => 'riley@rileytestut.com'
  }
  s.source_files = 'RSTToastView/*.{h,m}'
  s.requires_arc = true
end