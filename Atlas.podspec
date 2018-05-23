Pod::Spec.new do |s|
  s.name                        = "Atlas"
  s.version                     = '1.1.2'
  s.summary                     = "Atlas is a library of communications user interface components integrated with LayerKit."
  s.homepage                    = 'https://github.com/layerhq/Atlas-iOS'
  s.social_media_url            = 'http://twitter.com/layer'
  s.documentation_url           = 'https://docs.layer.com/sdk/atlas_ios/introduction'
  s.license                     = 'Apache2'
  s.author                      = { 'Kevin Coleman'   => 'kevin@layer.com',
                                    'Blake Watters'   => 'blake@layer.com',
                                    'Klemen Verdnik'  => 'klemen@layer.com',
                                    'Ben Blakely'     => 'ben@layer.com',
                                    'Daniel Maness'   => 'daniel@layer.com',
                                    'Mark Krenek'     => 'mark@layer.com' }
  s.source                      = { git: "https://github.com/layerhq/Atlas-iOS.git", tag: "v#{s.version}" }
  s.platform                    = :ios, '8.0'

  s.requires_arc                = true
  s.source_files                = 'Code/**/*.{h,m}'
  s.public_header_files         = 'Code/**/*.h'
  s.ios.resource_bundle         = { 'AtlasResource' => 'Resources/*' }
  s.ios.frameworks              = %w{ UIKit CoreLocation MobileCoreServices }
  s.ios.deployment_target       = '8.0'
  s.dependency                  'LayerKit', '>= 0.26.9'
end
