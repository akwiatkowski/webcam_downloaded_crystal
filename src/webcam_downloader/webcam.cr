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

    @stats["download_total_size_stored"] = 0_u64
    @stats["download_total_size_unprocessed"] = 0_u64

    @previous_md5 = ""
    @current_md5 = ""

    @last_download_at = Time.now - Time::Span.new(1, 0, 0)
    @started_at = Time.now

    @index = 0

    @logger.debug "#{log_name} initialized"
  end

  # start of getters
  getter :desc, :resize, :interval, :group, :last_download_at, :started_at
  property :index

  def url
    _url = nil
    _url = @hash[":url"] if @hash.has_key?(":url")
    _url = generate_url if @hash.has_key?(":url_schema")
  end

  def generate_url(time = nil)
    _schema =  @hash[":url_schema"]

    _time_modulo = 0
    _time_modulo = @hash[":time_modulo"].to_s.to_i64 if @hash.has_key?(":time_modulo")

    _time_offset = 0
    _time_offset = @hash[":time_offset"].to_s.to_i64 if @hash.has_key?(":time_offset")

    time = Time.now.epoch if time.nil?
    time = time as Int64

    if _time_modulo != 0
      time -= time % _time_modulo
    end

    # time offset
    if _time_offset != 0
      time += _time_offset
      time -= _time_modulo
    end

    s = Time.epoch(time).to_s(_schema as String)

    @logger.info("#{log_name} generated url #{s}")

    return s
  end

  def log_name
    "#{index} - #{desc}"
  end

  def download
    download! if download?
  end

  def download?
    t = @last_download_at.epoch - Time.now.epoch + self.interval
    if t <= 0
      return true
    else
      @logger.info("#{log_name} need to wait more #{t} seconds")
      return false
    end
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
      @logger.info("#{log_name} image downloaded, size #{Helper.size_to_human( File.size(_download_temp_path) )}")
      @stats["download_total_size_unprocessed"] += File.size( _download_temp_path )

      if resize
        t = Time.now
        @storage.processor.resize( _download_temp_path, _download_temp_process_path, @jpeg_quality )
        process_time = Time.now - t
        @stats["time_process_sum"] += download_time.to_f
        @stats["time_process_count"] += 1

        @logger.info("#{log_name} image processed")
        _download_path = _download_temp_process_path
      end

      @stats["download_total_size_stored"] += File.size( _download_path )

      @current_md5 = @storage.processor.md5( _download_path )
      unless @current_md5 == @previous_md5
        # move to
        @storage.move(_download_path, _path_store)
        # create link in latest
        @storage.latest_link(desc, _path_store)
        # stats
        @stats["download_done"] += 1
        # mark hash
        @previous_md5 = @current_md5

        @logger.debug("#{log_name} image is different, stored")
      else
        @logger.info("#{log_name} image is identical")
        # stats
        @stats["download_identical"] += 1
      end

      # mark image was downloaded now
      @last_download_at = Time.now
      @logger.info("#{log_name} image is finished, size #{Helper.size_to_human( File.size(_path_store) )}")
    end

  end

  def json_data
    return {
      "index" => index,
      "desc" => desc,
      "url" => url,
      "interval" => interval,
      "group" => group,
      "last_download_at" => last_download_at.epoch,
      "started_at" => started_at.epoch,
      "stats" => @stats
    }
  end
end
