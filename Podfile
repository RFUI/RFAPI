
source 'https://github.com/PBPods/PBFlex.git'
source 'https://cdn.cocoapods.org/'

target 'Example-iOS' do
    platform :ios, '9.0'
    
    pod 'RFMessageManager', :subspecs => ['SVProgressHUD']
    pod 'RFAPI', :path => '.'
#    pod 'PBFlex', :configurations => ['Debug']
end

target 'Test-iOS' do
   platform :ios, '12.0'

   pod 'RFAPI', :path => '.'
end

target 'Test-macOS' do
    platform :osx, '10.13'
    pod 'RFAPI', :path => '.'
end

target 'Test-tvOS' do
    platform :tvos, '12.0'
    pod 'RFAPI', :path => '.'
end
