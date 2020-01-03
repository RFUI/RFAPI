
source 'https://github.com/PBPods/PBFlex.git'
source 'https://cdn.cocoapods.org/'

target 'Example-iOS' do
    platform :ios, '8.0'
    
    pod 'RFMessageManager', :subspecs => ['SVProgressHUD'], :git => 'https://github.com/RFUI/RFMessageManager.git', :branch => 'develop'
    pod 'RFAPI', :path => '.'
    pod 'PBFlex', :configurations => ['Debug']

    target 'Test-iOS' do
    end
end

target 'Test-macOS' do
    platform :osx, '10.9'
    pod 'RFAPI', :path => '.'
end
