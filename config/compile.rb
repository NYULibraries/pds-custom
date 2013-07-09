require 'compass'
# Need to require bootstrap before sprockets loads
require 'bootstrap-sass'
require 'nyulibraries_assets'
require 'fileutils'
require 'microservice_precompiler'
# Copy images and css to dist
%w(css images).each do |asset|
  FileUtils.rm_rf "./dist/#{asset}"
  FileUtils.cp_r "./assets/#{asset}", "./dist"
end
nyulibraries_assets_javascripts_path = 
  "#{Compass::Frameworks['nyulibraries_assets'].stylesheets_directory}/../javascripts"
bootstrap_assets_base = "#{Compass::Frameworks['bootstrap'].stylesheets_directory}/.."
bootstrap_javascripts_path = "#{bootstrap_assets_base}/javascripts"
bootstrap_images_path = "#{bootstrap_assets_base}/images"
# Copy the bootstrap glyphicons to dist
FileUtils.cp_r "#{bootstrap_images_path}", "./dist"
pds_javascripts_path = "./assets/javascripts"
precompiler = MicroservicePrecompiler::Builder.new
precompiler.compass_build
precompiler.build_path = "./dist"
precompiler.send(:sprockets_env).append_path bootstrap_javascripts_path
precompiler.send(:sprockets_env).append_path nyulibraries_assets_javascripts_path
precompiler.send(:sprockets_env).append_path pds_javascripts_path
precompiler.project_root = "./assets"
precompiler.sprockets_build [:javascripts]
