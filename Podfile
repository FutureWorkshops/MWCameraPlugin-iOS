source 'https://cdn.cocoapods.org/'
source 'https://github.com/FutureWorkshops/FWTPodspecs.git'

workspace 'MWCamera'
platform :ios, '13.0'

inhibit_all_warnings!
use_frameworks!

project 'MWCamera/MWCamera.xcodeproj'
project 'MWCameraPlugin/MWCameraPlugin.xcodeproj'

abstract_target 'MWCamera' do
  pod 'MobileWorkflow'

  target 'MWCamera' do
    project 'MWCamera/MWCamera.xcodeproj'

    target 'MWCameraTests' do
      inherit! :search_paths
    end
  end

  target 'MWCameraPlugin' do
    project 'MWCameraPlugin/MWCameraPlugin.xcodeproj'

    target 'MWCameraPluginTests' do
      inherit! :search_paths
    end
  end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
      target.build_configurations.each do |config|
        config.build_settings['PROVISIONING_PROFILE_SPECIFIER'] = ""
    end
  end
end
