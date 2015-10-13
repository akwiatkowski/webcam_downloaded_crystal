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
  end

  # load all config YAML files
  def load_config
    Dir["config/*.yml"].each do |path|
      load_config_file(path)
    end
  end

  # load one config YAML file and add Webcam object
  def load_config_file(path)
    s = File.read(path)
    data = YAML.load(s) as Array

    data.each do |h|
      @webcams.push WebcamDownloader::Webcam.new(h, self)
    end

    puts "config loaded #{path}"
  end

end
