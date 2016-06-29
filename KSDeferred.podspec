Pod::Spec.new do |s|
  s.name         = "KSDeferred"
  s.version      = "0.3.3"
  s.summary      = "Async library inspired by CommonJS Promises/A spec."
  s.homepage     = "https://github.com/kseebaldt/deferred"
  s.license      = 'MIT'
  s.author       = { "Kurtis Seebaldt" => "kseebaldt@gmail.com" }
  s.source       = { :git => "https://github.com/kseebaldt/deferred.git", :tag => "0.3.3" }
  s.requires_arc = true

  s.ios.deployment_target = '5.1'
  s.osx.deployment_target = '10.7'
  s.watchos.deployment_target = '2.0'
  s.watchos.exclude_files = "Deferred/KSURLConnectionClient.{h,m}"
  s.tvos.deployment_target = '9.0'
  s.tvos.exclude_files = "Deferred/KSURLConnectionClient.{h,m}"

  s.source_files = 'Deferred', 'Deferred/**/*.{h,m}'
end
