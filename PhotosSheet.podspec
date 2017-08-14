#
#  Be sure to run `pod spec lint PhotosSheet.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|
  s.name         = "PhotosSheet"
  s.version      = "1.1.0"
  s.summary      = "A photo selection control that has action sheet style."
  s.homepage     = "https://github.com/TangentW/PhotosSheet"
  s.license      = "MIT"
  s.author       = { "Tangent" => "805063400@qq.com" }
  s.platform     = :ios
  s.ios.deployment_target = "9.0"
  s.source       = { :git => "https://github.com/TangentW/PhotosSheet.git", :tag => "1.1.0" }
  s.source_files  = "PhotosSheet/PhotosSheet/*.swift"
  s.resources = "PhotosSheet/PhotosSheet/*.{xcassets,lproj}"
  s.frameworks  = "UIKit", "Photos"
end
