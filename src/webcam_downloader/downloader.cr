require "yaml"
require "logger"

class WebcamDownloader::Downloader
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.level = Logger::INFO
    @logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
                          io << severity[0] << ", [" << datetime.to_s("%H:%M:%S.%L") << "] "
                          io << severity.rjust(5) << ": " << message
                        end

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

  getter :webcam_array, :logger, :storage, :wget_proxy

  def setup
    @storage.setup
    @webcam_array.setup

    @logger.info "Setup complete"
  end

  def one_loop
    @webcam_array.make_it_so
    @stats_writer.make_it_so

    @logger.info "Loop complete"
  end

  def run_loop
    @logger.info "Infinite loop start"

    loop do
      one_loop
      sleep(10)
    end
  end
end
