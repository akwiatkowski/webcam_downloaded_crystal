class WebcamDownloader::Webcam
  def initialize(_hash, _logger, _storage, _wget_proxy)
    @hash = _hash as Hash(YAML::Type, YAML::Type)
    @logger = _logger
    @storage = _storage
    @wget_proxy = _wget_proxy

    @desc = @hash[":desc"] as String

    # resize params
    @resize = false
    @resize = @hash[":resize"] if @hash.has_key?(":resize")

    @jpeg_quality = 84
    @jpeg_quality = @hash[":jpg_quality"].to_s.to_u16 if @hash.has_key?(":jpg_quality")

    @interval = 180_u64
    @interval = @hash[":interval"].to_s.to_u32 if @hash.has_key?(":interval")

    @group = ""
    @group = @hash[":group"] if @hash.has_key?(":group")

    # stats
    @stats = {} of String => ( UInt64 | Float64 )
    @stats["download_attemp"] = 0_u64
    @stats["download_done"] = 0_u64
    @stats["download_identical"] = 0_u64

    @stats["time_download_sum"] = 0.0
    @stats["time_download_count"] = 0_u64
    @stats["time_process_sum"] = 0.0
    @stats["time_process_count"] = 0_u64


    @previous_md5 = ""
    @current_md5 = ""

    @last_download_at = Time.now - 3600

    @logger.debug "#{self.class} initialized: #{@desc}"
  end

  # start of getters
  getter :desc, :resize, :interval, :group, :last_download_at

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
    @stats["download_attemp"] += 1

    _url = self.url
    _download_temp_path = @storage.path_temp_for_desc( self.desc )
    _download_temp_process_path = @storage.path_temp_processed_for_desc( self.desc )
    _path_store = @storage.path_store_for_desc( self.desc )
    # used for md5 calculation
    _download_path = _download_temp_path

    t = Time.now
    @wget_proxy.download_url(_url, _download_temp_path)
    download_time = Time.now - t
    @stats["time_download_sum"] += download_time.to_f
    @stats["time_download_count"] += 1

    if @storage.processor.is_valid_image?( _download_temp_path )
      # image was downloaded
      @logger.info("#{self.class} image downloaded: #{self.desc}")
      if resize
        t = Time.now
        @storage.processor.resize( _download_temp_path, _download_temp_process_path, @jpeg_quality )
        process_time = Time.now - t
        @stats["time_process_sum"] += download_time.to_f
        @stats["time_process_count"] += 1

        @logger.info("#{self.class} image processed: #{self.desc}")
        _download_path = _download_temp_process_path
      end

      @current_md5 = @storage.processor.md5( _download_path )
      unless @current_md5 == @previous_md5
        @logger.info("#{self.class} image is different: #{self.desc}")
        # move to
        @storage.move(_download_path, _path_store)
        # create link in latest
        @storage.latest_link(desc, _path_store)
        # stats
        @stats["download_done"] += 1
      else
        # stats
        @stats["download_identical"] += 1
      end

      # mark image was downloaded now
      @last_download_at = Time.now
    end

  end

  def json_data
    return {
      "desc" => desc,
      "interval" => interval,
      "group" => group,
      "last_download_at" => last_download_at.epoch,
      "stats" => @stats
    }
  end
end
