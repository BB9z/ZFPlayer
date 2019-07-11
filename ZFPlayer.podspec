Pod::Spec.new do |s|
    s.name         = 'ZFPlayer'
    s.version      = '1.2.0'
    s.summary      = 'AVPlayer wrapper.'
    s.homepage     = 'https://github.com/BB9z/ZFPlayer'
    s.license      = 'MIT'
    s.authors      = [ 'BB9z', 'renzifeng' ]
    s.platform     = :ios, '8.0'
    s.source       = { :git => 'https://github.com/BB9z/ZFPlayer.git' }
    s.source_files = 'ZFPlayer/*.{h,m}'
    s.framework    = 'UIKit', 'AVFoundation', 'CoreImage'
    s.requires_arc = true

    s.dependency 'RFAlpha/RFKVOWrapper'
    s.dependency 'RFAlpha/RFTimer'
    s.dependency 'RFInitializing'
    s.dependency 'RFKit/Category/UIView'
    s.dependency 'RFKit/Runtime'
end
