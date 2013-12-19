# Require compass first so the extensions see it
require 'compass'
# Need to require bootstrap before sprockets loads
# since that's how the bootstrap gem determines if we're 
# asset pipelining
require 'bootstrap-sass'
require 'nyulibraries-assets'
require 'fileutils'
require 'microservice_precompiler'

ASSETS = %w(css images javascripts)
# Get the various paths
nyulibraries_assets_base = 
  "#{Compass::Frameworks['nyulibraries-assets'].stylesheets_directory}/.."
nyulibraries_assets_javascripts_path = "#{nyulibraries_assets_base}/javascripts"
nyulibraries_assets_images_path = "#{nyulibraries_assets_base}/images"
bootstrap_assets_base = "#{Compass::Frameworks['bootstrap'].stylesheets_directory}/.."
bootstrap_javascripts_path = "#{bootstrap_assets_base}/javascripts"
bootstrap_images_path = "#{bootstrap_assets_base}/images"
# Clean up old compiled css
FileUtils.rm_rf "./assets/css"
# Clean up old distribution
FileUtils.rm_rf "./dist"
# Create dist dirs
ASSETS.each do |asset|
  FileUtils.mkdir_p "./dist/#{asset}"
end
# Copy the bootstrap glyphicons to assets
FileUtils.cp_r "#{bootstrap_images_path}", "./assets"
# Copy the nyulibraries images to assets
FileUtils.cp_r "#{nyulibraries_assets_images_path}", "./assets"
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

