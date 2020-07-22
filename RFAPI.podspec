Pod::Spec.new do |s|
  s.name             = 'RFAPI'
  s.version          = '2.0.0-beta.2'
  s.summary          = 'RFAPI is a network request library specially designed for API requests. It is a URL session wrapper base on AFNetworking.'

  s.homepage         = 'https://github.com/RFUI/RFAPI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BB9z' => 'bb9z@me.com' }
  s.source           = {
    :git => 'https://github.com/RFUI/RFAPI.git',
    :tag => s.version.to_s
  }

  s.requires_arc = true
  s.osx.deployment_target = '10.10'
  s.ios.deployment_target = '8.0'
  s.tvos.deployment_target = '9.0'
  # s.watchos.deployment_target = '2.0'

  s.dependency 'JSONModel'
  s.dependency 'AFNetworking/Serialization', '>= 2.3'
  s.dependency 'AFNetworking/Security', '>= 2.3'
  s.dependency 'AFNetworking/Reachability', '>= 2.3'
  s.dependency 'RFKit/Runtime', '> 1.7'
  s.dependency 'RFInitializing', '>= 1.1'
  s.dependency 'RFMessageManager/Manager', '>= 0.5'
  s.dependency 'RFMessageManager/RFNetworkActivityMessage'
  s.source_files = ['Sources/**/*.{h,m}']
  s.public_header_files = [
    'Sources/RFAPI/RFAPI.h',
    'Sources/RFAPI/Define/*.h',
    'Sources/RFAPI/ModelTransformer/*.h',
    'Sources/RFAPI/Compatible/*.h',
  ]

  s.pod_target_xcconfig = {
    # These config should only exsists in develop branch.
    'WARNING_CFLAGS'=> [
      '-Weverything',                   # Enable all possiable as we are developing a library.
      '-Wno-gnu-statement-expression',  # Allow ?: expression.
      '-Wno-gnu-conditional-omitted-operand',
      '-Wno-auto-import',               # Still needs old #import for backward compatibility. 
      '-Wno-sign-conversion',
      '-Wno-sign-compare',
      '-Wno-objc-missing-property-synthesis'
    ].join(' ')
  }
end
