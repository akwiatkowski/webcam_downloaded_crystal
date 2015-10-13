require "yaml"
require "logger"

class WebcamDownloader::Downloader
  def initialize
    @logger = Logger.new(STDOUT)
    @webcams = [] of WebcamDownloader::Webcam

    @storage = Storage.new
    @wget_proxy = WgetProxy.new
  end

  def setup
    # assign objects
    @storage.downloader = self
    @storage.logger = @logger

    @wget_proxy.logger = @logger
    @wget_proxy.downloader = self

    # load config
    load_config

    # prepare dir structure
    #@storage.prepare
  end

  ####

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

  def one_loop
    @storage.prepare_monthly_directories



    @webcams.each do |webcam|
      webcam.download
    end
  end




end
