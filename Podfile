source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '7.0'

inhibit_all_warnings!

pod 'SVPullToRefresh'
pod 'RestKit', '0.22.0'
pod 'KissXML'
pod 'SVProgressHud', '1.1.2'
pod 'SDWebImage', '3.7.1'
pod 'ECSlidingViewController', '2.0.3'
pod 'CocoaLumberjack', '1.8.0'
pod 'UIImage+PDF'

#A workaround to the issue discussed here: http://stackoverflow.com/q/22328882/2611971
post_install do | installer |
    installer.project.build_configurations.each do |config|
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
    end
end
