platform :ios, '10.0'
use_frameworks!

source 'https://github.com/CocoaPods/Specs.git'

workspace 'Barista.xcworkspace'

def barista_pods
  pod 'SalesforceAnalytics', :path => 'mobile_sdk/SalesforceMobileSDK-iOS'
  pod 'SalesforceSDKCore', :path => 'mobile_sdk/SalesforceMobileSDK-iOS'
  pod 'SmartStore', :path => 'mobile_sdk/SalesforceMobileSDK-iOS'
  pod 'SmartSync', :path => 'mobile_sdk/SalesforceMobileSDK-iOS'
  pod 'SalesforceSwiftSDK', :path => 'mobile_sdk/SalesforceMobileSDK-iOS'
  pod 'PromiseKit', :git => 'https://github.com/mxcl/PromiseKit', :tag => '5.0.3'
  pod 'RxSwift', '~> 4.1'
  pod 'RxCocoa', '~> 4.1'
  pod 'Fabric'
  pod 'Crashlytics'
end

target 'Consumer' do
  project 'Consumer/Consumer.xcodeproj'
  barista_pods
end

target 'Common' do
  project 'Common/Common.xcodeproj'
  barista_pods
end

target 'Provider' do
  project 'Provider/Provider.xcodeproj'
  barista_pods
end

# Fix for xcode9/fmdb/sqlcipher/cocoapod issue - see https://discuss.zetetic.net/t/ios-11-xcode-issue-implicit-declaration-of-function-sqlite3-key-is-invalid-in-c99/2198/27
post_install do | installer |
  print "SQLCipher: link Pods/Headers/sqlite3.h"
  system "mkdir -p Pods/Headers/Private && ln -s ../../SQLCipher/sqlite3.h Pods/Headers/Private"
end
