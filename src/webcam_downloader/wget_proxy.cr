class WebcamDownloader::WgetProxy
  def initialize(_logger)
    @logger = _logger

    @logger.debug "#{self.class} initialized"
  end
end
