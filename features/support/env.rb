Dir[File.dirname(__FILE__) + '/lib/*.rb'].each {|file| require file }
require 'rspec/expectations'
require 'browbeat/features/support/env'
require 'selenium-webdriver'
require 'figs'; Figs.load()
