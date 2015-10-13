class WebcamDownloader::Webcam
  def initialize(_hash, _logger, _storage, _wget_proxy)
    @hash = _hash as Hash(YAML::Type, YAML::Type)
    @logger = _logger
    @storage = _storage
    @wget_proxy = _wget_proxy

    @desc = @hash[":desc"] as String

    @logger.debug "#{self.class} initialized: #{@desc}"
  end

  getter :desc

  def url
    @hash[":url"]
  end

  def download
    _url = self.url
    _download_temp_path = @storage.path_temp_for_desc( self.desc )
    _path_store_for_desc = @storage.path_store_for_desc( self.desc )

    @wget_proxy.download_url(_url, _download_temp_path)
  end
end
