class WebcamDownloader::Webcam
  def initialize(_hash, _logger, _storage, _wget_proxy)
    @hash = _hash as Hash(YAML::Type, YAML::Type)
    @logger = _logger
    @storage = _storage
    @wget_proxy = _wget_proxy

    @desc = @hash[":desc"] as String

    @resize = false
    @resize = @hash[":resize"] if @hash.has_key?(":resize")

    @interval = 180_u64
    @interval = @hash[":interval"].to_s.to_u32 if @hash.has_key?(":interval")

    @group = ""
    @group = @hash[":group"] if @hash.has_key?(":group")


    @previous_md5 = ""
    @current_md5 = ""

    @last_download_at = Time.now - 3600

    @logger.debug "#{self.class} initialized: #{@desc}"
  end

  # start of getters
  getter :desc, :resize, :interval, :group

  def url
    @hash[":url"]
  end

  def download
    download! if download?
  end

  def download?
    return true
    return (Time.now - @last_download_at) >= self.interval
  end

  def download!
    _url = self.url
    _download_temp_path = @storage.path_temp_for_desc( self.desc )
    _download_temp_process_path = @storage.path_temp_processed_for_desc( self.desc )
    _path_store = @storage.path_store_for_desc( self.desc )
    # used for md5 calculation
    _download_path = _download_temp_path

    @wget_proxy.download_url(_url, _download_temp_path)

    if @storage.processor.is_valid_image?( _download_temp_path )
      # image was downloaded
      @logger.info("#{self.class} image downloaded: #{self.desc}")
      if resize
        @storage.processor.resize( _download_temp_path, _download_temp_process_path )
        @logger.info("#{self.class} image processed: #{self.desc}")
        _download_path = _download_temp_process_path
      end

      @current_md5 = @storage.processor.md5( _download_path )
      unless @current_md5 == @previous_md5
        @logger.info("#{self.class} image is different: #{self.desc}")
        # move to
        @storage.move(_download_path, _path_store)
      end

      # mark image was downloaded now
      @last_download_at = Time.now
    end

  end
end
