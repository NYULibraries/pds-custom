require 'pry'
require 'compass'
# Need to require bootstrap before sprockets loads
require 'bootstrap-sass'
require 'fileutils'
require 'microservice_precompiler'
precompiler = MicroservicePrecompiler::Builder.new
precompiler.compass_build
# Copy images and css to dist
%w(css images).each do |asset|
  FileUtils.rm_rf "./dist/#{asset}"
  FileUtils.cp_r "./assets/#{asset}", "./dist"
end
precompiler.build_path = "./dist"
bootstrap_javascripts_path = 
  "#{Compass::Frameworks['bootstrap'].stylesheets_directory}/../javascripts"
precompiler.send(:sprockets_env).append_path bootstrap_javascripts_path
precompiler.project_root = "./assets"
precompiler.sprockets_build [:javascripts]
