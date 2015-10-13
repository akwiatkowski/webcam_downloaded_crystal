require "yaml"
require "logger"

class WebcamDownloader::Downloader
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG


    @processor = Processor.new(
      @logger
    )
    @storage = Storage.new(
      @logger,
      @processor
    )
    @wget_proxy = WgetProxy.new(
      @logger
    )

    @webcam_array = WebcamArray.new(
      @storage,
      @wget_proxy,
      @logger
    )

    @stats_writer = StatsWriter.new(
      @logger,
      @webcam_array
    )
  end

  def setup
    @storage.setup
    @webcam_array.setup
  end

  def one_loop
    @webcam_array.make_it_so
    @stats_writer.make_it_so
  end
end
