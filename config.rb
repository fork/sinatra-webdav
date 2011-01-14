HoptoadNotifier.configure do |config|
  config.api_key = '3e64565740e20a63886c9f09e93f09b4'
end

DAV::Resource.backend = DAV::FileBackend
