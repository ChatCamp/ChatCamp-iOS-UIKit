Pod::Spec.new do |s|

s.platform = :ios
s.ios.deployment_target = '9.0'
s.swift_version = '4.0'
s.name = "ChatCampUIKit"
s.summary = "ChatCamp iOS UI Kit"
s.description  = "UI Kit for ChatCamp iOS SDK"
s.requires_arc = true
s.version = "0.1.13"
s.license = { :type => "MIT", :file => "LICENSE" }
s.authors = {"Saurabh Gupta" => "saurabh.gupta@iflylabs.com", "Shashwat Srivastava"=>"shashwat@iflylabs.com", "Shubham Gupta"=>"shubham@iflylabs.com"}
s.homepage = "https://chatcamp.io"
s.source = { :git => "https://github.com/ChatCamp/ChatCamp-iOS-UI-Kit.git", :tag => "v#{s.version}"}

s.ios.frameworks = ["AVKit", "Photos", "AVFoundation", "MobileCoreServices", "SafariServices", "MapKit", "UIKit", "Foundation"]
s.dependency 'ChatCamp', '~> 0.1.22'
s.dependency 'DKImagePickerController', '4.0.0-beta2'
s.dependency 'DKCamera', '1.5.3'
s.dependency 'DKPhotoGallery', '0.0.7'
s.dependency 'Alamofire'
s.dependency 'MBProgressHUD'


s.source_files = "ChatCampUIKit/**/*.{swift}"
s.resources = "ChatCampUIKit/**/*.{png,jpeg,jpg,storyboard,xib}"
end
