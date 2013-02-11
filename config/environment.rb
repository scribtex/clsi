# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.17' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  config.gem "systemu"
  config.gem "rack", :version => "1.1.3"

  config.time_zone = 'UTC'

  config.action_controller.session = {
    :session_key => '_clsi_session',
    :secret      => 'cbd744cdfaf96380fddbae8d5ca2facff1fce7f4b93c6d98feaf9986ff09e83dbd3ca79f827a0cf654f16c3c0c948acaad5d616fdbf50144708f4f10de3c855e'
  }
end

# This ensures the POST data is never parsed. Doing so can overload the parser with
# large requests and we parse it ourselves later.
Rack::Request::FORM_DATA_MEDIA_TYPES.clear
Rack::Request::PARSEABLE_DATA_MEDIA_TYPES.clear
ActionController::Base.param_parsers.clear
