platform :ios, '16.0'
use_frameworks!
inhibit_all_warnings!

project 'RetailRewardsRescue.xcodeproj'

target 'RetailRewardsRescue' do
  pod 'RxSwift', '~> 6.7'
  pod 'RxCocoa', '~> 6.7'
  pod 'RxRelay', '~> 6.7'
  pod 'Alamofire', '~> 5.9'
  pod 'SDWebImage', '~> 5.20'
  pod 'Sentry', '~> 8.49'
end

target 'RetailRewardsRescueTests' do
  inherit! :search_paths
  pod 'RxTest', '~> 6.7'
  pod 'RxBlocking', '~> 6.7'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '16.0'
    end
  end
end
