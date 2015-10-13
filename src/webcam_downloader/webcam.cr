class WebcamDownloader::Webcam
  def initialize(_hash, _logger)
    @hash = _hash as Hash(YAML::Type, YAML::Type)
    @logger = _logger

    @desc = @hash[":desc"] as String

    @logger.debug "#{self.class} initialized: #{@desc}"
  end

  getter :desc
end
