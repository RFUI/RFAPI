
target 'Example-iOS' do
    platform :ios, '8.0'
    pod 'AFNetworking', '~> 2.6', :subspecs => ['NSURLConnection']
    pod 'RFMessageManager', :git => 'https://github.com/RFUI/RFMessageManager.git', :subspecs => ['SVProgressHUD']
    pod 'RFAPI', :path => '.'

    target 'Test-iOS' do
    end
end

target 'Test-macOS' do
    platform :osx, '10.9'
    pod 'AFNetworking', '~> 2.6', :subspecs => ['NSURLConnection']
    pod 'RFAPI', :path => '.'
end
