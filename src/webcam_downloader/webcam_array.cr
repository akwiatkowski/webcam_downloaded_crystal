require "logger"
require "colorize"

class WebcamDownloader::WebcamArray
  def initialize(_storage, _wget_proxy, _logger, _options = {} of String => (UInt32 | Float64))
    @storage = _storage
    @wget_proxy = _wget_proxy
    @logger = _logger

    @webcams = [] of WebcamDownloader::Webcam

    @pool_size = 3
    @pool_size = _options[":pool_size"].to_s.to_u32 if _options.has_key?(":pool_size")

    @last_index = 0

    @logger.debug "Array initialized"
  end

  getter :webcams
  property :pool_size

  def setup
    load_all_config
    copy_descs_to_storage # needed for monthly directories
    create_monthly_directories
  end

  def make_it_so
    create_monthly_directories

    pool = [] of Concurrent::Future(Webcam)
    @webcams.each_with_index do |webcam, index|
      if pool.size < @pool_size
        # pool not filles
        pool << future do
          webcam.download
          webcam
        end
      end

      if pool.size == @pool_size || @webcams.last == webcam
        # pool filles, wait for finish
        while [true] != pool.map { |f| f.completed? as Bool }.uniq
          # some were not finished
          waiting_for_count = pool.map { |f| f.running? as Bool }.select { |r| r }.size
          @logger.debug("Array is waiting for #{waiting_for_count.to_s.colorize(:yellow)} webcams")
          sleep 1
        end
        # clear pool
        pool = [] of Concurrent::Future(Webcam)
        @logger.info("Array: current pool is clear, total #{@webcams.size.to_s.colorize(:light_yellow)}")
      end
    end
  end

  # load all config YAML files
  def load_all_config
    Dir["config/*.yml"].each do |path|
      load_config_file(path)
    end

    @logger.debug "Array all config loaded - #{@webcams.size.to_s.colorize(:blue)} webcams"
  end

  # load one config YAML file and add Webcam object
  def load_config_file(path)
    s = File.read(path)
    data = YAML.parse(s)

    return if data == nil

    data.each do |hash|
      # check if definition has "desc"
      if hash[":desc"]?
        webcam = WebcamDownloader::Webcam.new(hash, @logger, @storage, @wget_proxy)
        webcam.index = @last_index
        @last_index += 1
        @webcams.push(webcam)
      end
    end

    @logger.debug "Array config load: #{path.to_s.colorize(:blue)}"
  end

  def copy_descs_to_storage
    @webcams.each do |webcam|
      @storage.desc_array << webcam.desc
    end

    # @logger.debug "#{self.class} copy_descs_to_storage"
  end

  def create_monthly_directories
    @storage.prepare_monthly_directories
  end
end
