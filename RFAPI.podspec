Pod::Spec.new do |s|
  s.name             = 'RFAPI'
  s.version          = '2.1.1'
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

  s.subspec 'Core' do |ss|
    ss.dependency 'AFNetworking/Serialization', '>= 2.3'
    ss.dependency 'AFNetworking/Security', '>= 2.3'
    ss.dependency 'AFNetworking/Reachability', '>= 2.3'
    ss.dependency 'RFKit/Runtime', '> 1.7'
    ss.dependency 'RFInitializing', '>= 1.1'
    ss.dependency 'RFMessageManager/Manager', '>= 0.5'
    ss.dependency 'RFMessageManager/RFNetworkActivityMessage'
    ss.source_files = ['Sources/RFAPI/**/*.{h,m}']
    ss.public_header_files = [
      'Sources/RFAPI/RFAPI.h',
      'Sources/RFAPI/Define/*.h',
      'Sources/RFAPI/ModelTransformer/*.h',
      'Sources/RFAPI/Compatible/*.h',
    ]
  end

  s.subspec 'JSONModel' do |ss|
    ss.dependency 'RFAPI/Core'
    ss.dependency 'JSONModel'
    ss.source_files = ['Sources/JSONModelTransformer/**/*.{h,m}']
    ss.public_header_files = [
      'Sources/JSONModelTransformer/*.h',
    ]
  end

  s.pod_target_xcconfig = {
  }
end
