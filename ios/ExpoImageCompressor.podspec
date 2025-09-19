Pod::Spec.new do |s|
  s.name           = 'ExpoImageCompressor'
  s.version        = '0.1.0'
  s.summary        = 'Lightweight image compression for Expo apps on iOS.'
  s.description    = 'Provides synchronous, on-device image compression for Expo and React Native projects targeting iOS.'
  s.author         = { 'rahimwws' => 'umudyan2014@gmail.com' }
  s.homepage       = 'https://github.com/rahimwws/expo-image-compressor'
  s.platforms      = {
    :ios => '15.1',
    :tvos => '15.1'
  }
  s.source         = {
    git: 'https://github.com/rahimwws/expo-image-compressor.git',
    tag: s.version.to_s
  }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"
  s.swift_versions = ['5.9']
  s.license        = { type: 'MIT', file: '../LICENSE' }
end
