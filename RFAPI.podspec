Pod::Spec.new do |s|
  s.name             = 'RFAPI'
  s.version          = '1.0.0'
  s.summary          = 'API Manager.'

  s.homepage         = 'https://github.com/RFUI/RFAPI'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BB9z' => 'bb9z@me.com' }
  s.source           = { :git => 'https://github.com/RFUI/RFAPI.git', :tag => s.version.to_s }

  s.requires_arc = true
  s.osx.deployment_target = '10.8'
  s.ios.deployment_target = '7.0'
  s.tvos.deployment_target = '9.0'

  s.dependency 'JSONModel'
  s.dependency 'RFKit/Runtime'
  s.dependency 'RFKit/Category/NSDictionary'
  s.dependency 'RFKit/Category/NSFileManager'
  s.dependency 'RFInitializing'
  s.dependency 'RFMessageManager/Manager'
  s.dependency 'RFMessageManager/RFNetworkActivityIndicatorMessage'
  s.source_files = ['*.{h,m}', 'RFAPIDefine/*.{h,m}']
  s.public_header_files = ['*.h', 'RFAPIDefine/*.h']

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
