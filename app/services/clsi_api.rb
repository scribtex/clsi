class ClsiApi < ActionWebService::API::Base
  api_method :getToken,
             :returns => [:string]

  api_method :compile,
             :expects => [{"xml" => :string}],
             :returns => [:string]
end
