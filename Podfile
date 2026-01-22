# Uncomment the next line to define a global platform for your project
platform :ios, '17.4'

target 'starving' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for starving
  pod 'FirebaseCore', '~> 11.5.0'
  pod 'FirebaseAuth', '~> 11.5.0'
  pod 'FirebaseFirestore', '~> 11.5.0'
  pod 'GoogleSignIn'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '12.0'
    end
  end
end
