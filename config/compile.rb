require 'pry'
require 'compass'
# Need to require bootstrap before sprockets loads
require 'bootstrap-sass'
require 'microservice_precompiler'
precompiler = MicroservicePrecompiler::Builder.new
precompiler.compass_build
precompiler.build_path = "./dist"
bootstrap_javascripts_path = 
  "#{Compass::Frameworks['bootstrap'].stylesheets_directory}/../javascripts"
precompiler.send(:sprockets_env).append_path bootstrap_javascripts_path
precompiler.project_root = "./assets"
precompiler.sprockets_build [:javascripts]
