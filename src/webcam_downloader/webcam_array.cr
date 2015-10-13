require "logger"

class WebcamDownloader::WebcamArray
  def initialize(_storage, _wget_proxy, _logger)
    @storage = _storage
    @wget_proxy = _wget_proxy
    @logger = _logger

    @webcams = [] of WebcamDownloader::Webcam

    @logger.debug "#{self.class} initialized"
  end

  def setup
    load_all_config
    copy_descs_to_storage # needed for monthly directories
    create_monthly_directories
  end

  # load all config YAML files
  def load_all_config
    Dir["config/*.yml"].each do |path|
      load_config_file(path)
    end

    @logger.debug "#{self.class} all config loaded: #{@webcams.size}"
  end

  # load one config YAML file and add Webcam object
  def load_config_file(path)
    s = File.read(path)
    data = YAML.load(s) as Array

    data.each do |h|
      @webcams.push WebcamDownloader::Webcam.new(h, @logger)
    end

    @logger.debug "#{self.class} config loaded: #{path}"
  end

  def copy_descs_to_storage
    @webcams.each do |webcam|
      @storage.desc_array << webcam.desc
    end

    @logger.debug "#{self.class} copy_descs_to_storage"
  end

  def create_monthly_directories
    @storage.prepare_monthly_directories
  end

end
