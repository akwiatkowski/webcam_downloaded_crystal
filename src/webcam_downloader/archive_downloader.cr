require "logger"
require "colorize"

class WebcamDownloader::ArchiveDownloader
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.level = Logger::INFO
    @logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
      io << severity[0] << ", [" << datetime.to_s("%H:%M:%S.%L") << "] "
      io << severity.rjust(5) << ": " << message
    end

    @wget_proxy = WgetProxy.new(
      @logger
    )
    @processor = Processor.new(
      @logger
    )
    @storage = Storage.new(
      @logger,
      @processor
    )

    @storage.prepare_directories

    @server_host = ""
    @server_list_path = ""
    @server_webcam_path = ""
    @name = ""

    @tmp_storage_path = ""
    @last_time_string = ""
    @last_time = Time.now

    @sleep_between_lists = 2
    @sleep_between_image_download = 3

    @already_count = 0
    @failed_count = 0
    @last_failed_count = 0
    @last_failed_stop_max = 4 # if more than 20 image download errors stop script
    @success_count = 0
    @enabled = true
    @total_size = UInt64.new(0)

    @format = "hd"
  end

  property :server_host, :server_list_path, :server_webcam_path, :name, :server_path
  getter :logger

  def watchdog_mark_failure
    if @last_failed_count >= @last_failed_stop_max
      @logger.error("Too many image failures #{@last_failed_count}, stopping")
      @enabled = false
    else
      @last_failed_count += 1
    end

    @failed_count += 1
  end

  def watchdog_mark_success
    @last_failed_count = 0
    @success_count += 1
  end

  def url(time_string = "")
    return "#{@server_host}#{@server_list_path}?wc=#{@name}&img=#{time_string}"
  end

  def image_url(time_string, format = @format)
    # format
    # * hd - fullhd
    # * hu - some megapixels
    return "#{@server_host}#{@server_webcam_path}#{@name}/#{time_string}_#{format}.jpg"
  end

  def get_image_list(time_string = "")
    @logger.info "Get images for '#{time_string.to_s.colorize(:green)}'"

    u = url(time_string)
    @wget_proxy.download_url(u, @tmp_storage_path)
    s = File.read(@tmp_storage_path)

    d = JSON.parse(s) as Hash(String, JSON::Type)
    a = Array(String).new
    if d.has_key?("history")
      # puts .class
      (d["history"] as Array(JSON::Type)).each do |t|
       a << t.to_s
      end
    end

    return a.reverse
  end

  def convert_time_string_to_time(time_string)
    time_split = time_string.split("/")
    time = Time.new(
      time_split[0].to_i,
      time_split[1].to_i,
      time_split[2].to_i,
      time_split[3][0..1].to_i,
      time_split[3][2..3].to_i
    )
    return time
  end

  def download_image(time_string)
    return false unless @enabled

    time = convert_time_string_to_time(time_string)

    store_path = @storage.path_store_for_archived_name(@name, time)
    # if exists no download
    if File.exists?(store_path)
      @already_count += 1
      return false
    end
    # create path
    store_dir_path = File.dirname(store_path)
    Dir.mkdir_p(store_dir_path) unless Dir.exists?(store_dir_path)
    # download image
    u = image_url(time_string)
    @logger.debug("Download image '#{u.to_s.colorize(:red)}'")
    @wget_proxy.download_url(u, store_path)

    if File.exists?(store_path)
      size = File.size(store_path)
      @logger.info "Image downloaded '#{time_string.to_s.colorize(:green)}', size #{size.to_s.colorize(:blue)}"
      if size == 0
        watchdog_mark_failure
        File.delete(store_path)
      else
        watchdog_mark_success
        @total_size += size
      end

      sleep @sleep_between_image_download
      return true
    else
      watchdog_mark_failure
      sleep @sleep_between_image_download
      return false
    end

  end



  def download_images_for_list(list)
    list.each do |time_string|
      download_image(time_string)
    end
  end

  def state_path
    File.join("data", "archived_#{@name}")
  end

  def store_last_time_string(time_string)
    f = File.new(state_path, "w")
    f.puts time_string
    f.close
  end

  def load_last_time_string
    return "" unless File.exists?(state_path)
    return File.read(state_path).to_s.strip
  end

  def make_it_so
    @logger.info "Start of '#{@name.to_s.colorize(:yellow)}'"

    @tmp_storage_path = @storage.path_temp_for_desc("archive_#{@name}")

    @last_time_string = load_last_time_string

    # get from last
    list = get_image_list(@last_time_string)
    download_images_for_list(list)

    sleep @sleep_between_lists

    @last_time_string = ""
    @last_time_string = list.last if list.size > 0

    while @enabled && @last_time_string != ""
      @logger.info "Success #{@success_count.to_s.colorize(:blue)}, already #{@already_count.to_s.colorize(:green)}, failed #{@failed_count.to_s.colorize(:red)}, last failed #{@last_failed_count.to_s.colorize(:red)}"
      @logger.info "Total size #{(@total_size / (1024 ** 2)).to_s.colorize(:purple)} MB"

      list = get_image_list(@last_time_string)
      download_images_for_list(list)

      if list.size > 0
        @last_time_string = list.last
        store_last_time_string(@last_time_string)
      end

      sleep @sleep_between_lists
    end

  end


end
