DEPLOYMENT_TARGET_KEY = 'IPHONEOS_DEPLOYMENT_TARGET'.freeze
# All pods will have at least this version to prevent Xcode warnings
DEPLOYMENT_TARGET_VALUE = '9.0'.freeze

workspace 'Little Go'
project 'Little Go'
platform :ios, DEPLOYMENT_TARGET_VALUE

abstract_target 'All Targets' do
  pod 'Firebase/Crashlytics'
  pod 'MBProgressHUD'
  pod 'ZipKit'
  pod 'CocoaLumberjack'

  target 'Little Go' do
  end

  target 'Unit tests' do
  end
end

# Script inspiration: https://github.com/CocoaPods/CocoaPods/issues/7314
post_install do |installer|
  installer.pods_project.targets.each do |target|
    messageWasPrinted = false
    target.build_configurations.each do |config|
      if config.build_settings[DEPLOYMENT_TARGET_KEY].to_f < DEPLOYMENT_TARGET_VALUE.to_f
        if (! messageWasPrinted)
          puts "#{DEPLOYMENT_TARGET_KEY} found with value #{config.build_settings[DEPLOYMENT_TARGET_KEY]} for target #{target.name}. This is too low. Removing the setting so that #{DEPLOYMENT_TARGET_VALUE} can take effect."
          messageWasPrinted = true
        end
        config.build_settings.delete DEPLOYMENT_TARGET_KEY
      elsif config.build_settings[DEPLOYMENT_TARGET_KEY].to_f > DEPLOYMENT_TARGET_VALUE.to_f
        if (! messageWasPrinted)
          puts "#{DEPLOYMENT_TARGET_KEY} found with value #{config.build_settings[DEPLOYMENT_TARGET_KEY]} for target #{target.name}. This is higher than the expected value #{DEPLOYMENT_TARGET_VALUE}!"
          messageWasPrinted = true
        end
      else
      end
    end
  end
end
