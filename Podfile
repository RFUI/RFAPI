
source 'https://github.com/PBPods/PBFlex.git'
source 'https://cdn.cocoapods.org/'

target 'Example-iOS' do
    platform :ios, '8.0'
    
    pod 'RFMessageManager', :subspecs => ['SVProgressHUD'], :git => 'https://github.com/RFUI/RFMessageManager.git', :branch => 'develop'
    pod 'RFAPI', :path => '.'
    pod 'PBFlex', :configurations => ['Debug']
end

target 'Test-iOS' do
   platform :ios, '12.0'

   pod 'RFAPI', :path => '.'
end

target 'Test-macOS' do
    platform :osx, '10.10'
    pod 'RFAPI', :path => '.'
end
