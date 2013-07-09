# Require compass first so the extensions see it
require 'compass'
# Need to require bootstrap before sprockets loads
# since that's how the bootstrap gem determines if we're 
# asset pipelining
require 'bootstrap-sass'
require 'nyulibraries_assets'
require 'fileutils'
require 'microservice_precompiler'

ASSETS = %w(css images javascripts)
# Get the various paths
nyulibraries_assets_javascripts_path = 
  "#{Compass::Frameworks['nyulibraries_assets'].stylesheets_directory}/../javascripts"
bootstrap_assets_base = "#{Compass::Frameworks['bootstrap'].stylesheets_directory}/.."
bootstrap_javascripts_path = "#{bootstrap_assets_base}/javascripts"
bootstrap_images_path = "#{bootstrap_assets_base}/images"
# Clean up old distribution
FileUtils.rm_rf "./dist"
# Create dist dirs
ASSETS.each do |asset|
  FileUtils.mkdir_p "./dist/#{asset}"
end
# Copy the bootstrap glyphicons to dist
FileUtils.cp_r "#{bootstrap_images_path}", "./dist"
pds_javascripts_path = "./assets/javascripts"
precompiler = MicroservicePrecompiler::Builder.new
precompiler.compass_build
# Copy compiled assets to dist except 
ASSETS.each do |asset|
  FileUtils.cp_r "./assets/#{asset}", "./dist" unless asset.eql? "javascripts"
end
precompiler.build_path = "./dist"
precompiler.send(:sprockets_env).append_path bootstrap_javascripts_path
precompiler.send(:sprockets_env).append_path nyulibraries_assets_javascripts_path
precompiler.send(:sprockets_env).append_path pds_javascripts_path
precompiler.project_root = "./assets"
precompiler.sprockets_build [:javascripts]

