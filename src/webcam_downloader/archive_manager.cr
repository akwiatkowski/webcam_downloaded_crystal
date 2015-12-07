require "logger"
require "./archive_downloader"

class WebcamDownloader::ArchiveManager
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.level = Logger::INFO
    @logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
      io << severity[0] << ", [" << datetime.to_s("%H:%M:%S.%L") << "] "
      io << severity.rjust(5) << ": " << message
    end

    @sleep_between_lists = 4
    @sleep_between_image_download = 5
    @format = "hd" # full hd, not all photos available
    @resize = false

    @names = [] of String
    @downloaders = [] of WebcamDownloader::ArchiveDownloader
  end

  property :names, :logger, :format, :resize, :sleep_between_lists,
    :sleep_between_image_download

  def setup
    @names.each do |name|
      w = WebcamDownloader::ArchiveDownloader.new(@logger)
      w.logger.level = Logger::DEBUG
      w.server_host = "http://www.foto-webcam.eu/"
      w.server_webcam_path = "webcam/"
      w.server_list_path = "webcam/include/list.php"
      w.name = name

      w.format = @format
      w.resize = @resize
      w.sleep_between_lists = @sleep_between_lists
      w.sleep_between_image_download = @sleep_between_image_download

      w.setup_pre_run

      @downloaders << w
    end

  end

  def make_it_so
    while true
      @logger.info("Manager - loop start for #{@downloaders.size} downloaders")
      get_all_lists
      get_all_images

      sleep @sleep_between_lists
    end
  end

  def get_all_lists
    @downloaders.each do |d|
      d.get_image_list
    end

    @logger.info("Manager - got all lists")
  end

  def images_to_download_count
    count = 0
    @downloaders.each do |d|
      count += d.images_to_download_count
    end

    @logger.info("Manager - images to download #{count.to_s.colorize(:green)}")

    return count
  end

  def get_all_images
    while images_to_download_count > 0
      @downloaders.each do |d|
        ts = d.next_time_string_to_download
        if ts != ""
          d.download_image(ts)
        end
      end

      @logger.debug("Manager - downloader loop finished")
    end

    # mark that webcams were finished
    @downloaders.each do |d|
      d.post_download
    end

    @logger.debug("Manager - post download finished")
  end

end