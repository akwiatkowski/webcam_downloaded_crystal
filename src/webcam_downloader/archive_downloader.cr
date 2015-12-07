require "logger"
require "colorize"

class WebcamDownloader::ArchiveDownloader
  def initialize(logger = Logger.new(STDOUT))
    @logger = logger
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
    @latest_time = Time.now

    @list = Array(String).new
    @list_index = 0

    @sleep_between_lists = 4
    @sleep_between_lists_inter = 0.8
    @sleep_between_image_download = 5
    @sleep_failed_list = 5

    @already_count = 0
    @failed_count = 0
    @last_failed_count = 0
    @last_failed_stop_max = 4 # if more than 20 image download errors stop script
    @success_count = 0
    @enabled = true
    @latest_enabled = true
    @first_run = true
    @total_size = UInt64.new(0)

    @format = "hd" # full hd, not all photos available

    @format = "hu" # full few MP image
    @resize = true
    @resize_jpeg_quality = 85
  end

  property :server_host, :server_list_path, :server_webcam_path, :name, :server_path
  property :sleep_between_lists, :sleep_between_image_download, :format, :resize, :resize_jpeg_quality
  property :logger
  getter :list


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

  def get_image_list(ts = @last_time_string)
    @logger.info "Get images for '#{@name.to_s.colorize(:yellow)}' time '#{ts.to_s.colorize(:green)}'"

    u = url(ts)
    @wget_proxy.download_url(u, @tmp_storage_path)
    s = File.read(@tmp_storage_path)

    if s.size == 0
      @logger.error("Blank file list downloaded")
      return @list
    end

    d = JSON.parse(s) as Hash(String, JSON::Type)
    a = Array(String).new
    if d.has_key?("history")
      # puts .class
      (d["history"] as Array(JSON::Type)).each do |t|
       a << t.to_s
      end
    end

    @list = a.reverse
    return @list
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
      @logger.info "Image downloaded '#{@name.to_s.colorize(:yellow)}' time '#{time_string.to_s.colorize(:green)}', size #{(size / 1024).to_s.colorize(:light_blue)} kB"
      if size == 0
        watchdog_mark_failure
        File.delete(store_path)
      else
        watchdog_mark_success
        @total_size += size

        if @resize
          resize_image(store_path)
        end

      end

      # mark which image was downloaded as latest
      # it will be used to periodically download latest images
      @latest_time = time if @latest_time < time

      sleep @sleep_between_image_download
      return true
    else
      watchdog_mark_failure
      sleep @sleep_between_image_download
      return false
    end

  end

  def resize_image(stored)
    tmp_store_path = stored + "_resized"
    @processor.resize(stored, tmp_store_path, @resize_jpeg_quality)

    if File.exists?(tmp_store_path)
      command_rm = "rm \"#{stored}\""
      command_mv = "mv \"#{tmp_store_path}\" \"#{stored}\""

      size_pre = File.size(stored)
      size_post = File.size(tmp_store_path)
      reduction = size_pre / size_post

      @logger.info("Resize image #{stored}, size from #{size_pre.to_s.colorize(:green)} to #{size_post.to_s.colorize(:blue)}")
      @logger.info("Reduction #{reduction.to_s.colorize(:blue)}")

      `#{command_rm}`
      `#{command_mv}`
    end
  end

  def download_images_for_list
    @list.each do |time_string|
      download_image(time_string)
      sleep @sleep_between_lists_inter
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
    t = File.read(state_path).to_s.strip
    @logger.info "Last time of '#{@name.to_s.colorize(:yellow)}' loaded '#{t}'"
    return t
  end

  def setup_pre_run
    @logger.info "Prerun of '#{@name.to_s.colorize(:yellow)}'"
    @tmp_storage_path = @storage.path_temp_for_desc("archive_#{@name}")
    @last_time_string = load_last_time_string
  end

  def next_time_string_to_download
    if @list_index >= @list.size
      return ""
    else
      t = @list[@list_index]
      @list_index += 1
      return t
    end
  end

  def images_to_download_count
    return @list.size - @list_index
  end

  def post_download
    @last_time_string = ""
    if @list.size > 0
      @last_time_string = @list.last
      store_last_time_string(@last_time_string)
    end
    @first_run = false

    @logger.info "Success #{@success_count.to_s.colorize(:blue)}, already #{@already_count.to_s.colorize(:green)}, failed #{@failed_count.to_s.colorize(:red)}, last failed #{@last_failed_count.to_s.colorize(:red)}"
    @logger.info "Total size #{(@total_size / (1024 ** 2)).to_s.colorize(:magenta)} MB"
  end

  # from time to time download latest to update collection
  def download_latest
    temp_time_string = @last_time_string
    @last_time_string = ""

    @logger.info "Downloading latest"

    execute_loop

    @last_time_string = temp_time_string
  end

  def is_latest_needed?
    if Time.now - @latest_time > Time::Span.new(6, 0, 0)
      return true
    else
      return false
    end
  end

  def execute_loop
    get_image_list

    if @first_run && @list.size == 0
      # blank response
      sleep @sleep_failed_list
      get_image_list
    end

    download_images_for_list
    post_download

    sleep @sleep_between_lists
  end

  def make_it_so
    setup_pre_run
    while @enabled && (@first_run || @last_time_string != "")
      execute_loop

      if is_latest_needed? && @latest_enabled
        download_latest
      end
    end
  end

end
