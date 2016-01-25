Pod::Spec.new do |s|
  s.name         = "WeiboSDK"

  s.summary      = "WeiboSDK."
  s.homepage     = "https://github.com/keyfun/weibo_ios_sdk"
  s.license      = 'HeHa'
  s.author       = { "Keyfun" => "keyfun.hk@gmail.com" }

  s.version      = "3.1.3"
  s.source       = { :git => "https://github.com/keyfun/weibo_ios_sdk.git", :tag => "3.1.3" }
  s.platform     = :ios, '6.0'
  s.requires_arc = false
  # s.source_files = 'libWeiboSDK/*.{h,m}' # no crash
  s.source_files = 'libWeiboSDK/*.{h,m}', 'Pod/Classes/SinaWeiboManager.swift' # crash
  s.resource     = 'libWeiboSDK/WeiboSDK.bundle'
  s.vendored_libraries  = 'libWeiboSDK/libWeiboSDK.a'
  s.frameworks   = 'ImageIO', 'SystemConfiguration', 'CoreText', 'QuartzCore', 'Security', 'UIKit', 'Foundation', 'CoreGraphics','CoreTelephony'
  s.libraries = 'sqlite3', 'z'
end