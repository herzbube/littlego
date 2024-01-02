DEPLOYMENT_TARGET_KEY = 'IPHONEOS_DEPLOYMENT_TARGET'.freeze
# All pods will have at least this version to prevent Xcode warnings
DEPLOYMENT_TARGET_VALUE = '15.0'.freeze

# Workaround for the error "The following Swift pods cannot yet be integrated as
# static libraries". This error was printed for various pods when updating to
# the newest FirebaseCrashlytics. The error prevented the update to complete
# successfully, even though this project does not use Swift. The error message
# recommended to add the following line to
# "[...] opt into those targets generating module maps [...]".
# If possible this workaround should be removed again sometime in the future.
use_modular_headers!

workspace 'Little Go'
project 'Little Go'
platform :ios, DEPLOYMENT_TARGET_VALUE

abstract_target 'All Targets' do
  pod 'FirebaseCrashlytics'
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
