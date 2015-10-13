require "yaml"
require "logger"

class WebcamDownloader::Downloader
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG

    @storage = Storage.new(
      @logger
    )
    @wget_proxy = WgetProxy.new(
      @logger
    )

    @webcam_array = WebcamArray.new(
      @storage,
      @wget_proxy,
      @logger
    )
  end

  def setup
    @storage.setup
    @webcam_array.setup
  end

  def one_loop
    @webcam_array.make_it_so
  end
end
