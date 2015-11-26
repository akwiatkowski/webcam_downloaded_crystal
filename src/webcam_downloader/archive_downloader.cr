require "logger"

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

    @sleep_between_lists = 2
    @sleep_between_image_download = 3

    @format = "hd"
  end

  property :server_host, :server_list_path, :server_webcam_path, :name, :server_path

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
    @logger.info "Get images for '#{time_string}'"

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

  def download_image(time_string)
    time_split = time_string.split("/")
    time = Time.new(
      time_split[0].to_i,
      time_split[1].to_i,
      time_split[2].to_i,
      time_split[3][0..1].to_i,
      time_split[3][2..3].to_i
    )

    store_path = @storage.path_store_for_archived_name(@name, time)
    # if exists no download
    return false if File.exists?(store_path)
    # create path
    store_dir_path = File.dirname(store_path)
    Dir.mkdir_p(store_dir_path) unless Dir.exists?(store_dir_path)
    # download image
    u = image_url(time_string)
    @wget_proxy.download_url(u, store_path)

    if File.exists?(store_path)
      @logger.info "Image downloaded '#{time_string}', size #{File.size(store_path)}"
      File.delete(store_path) if File.size(store_path) == 0

      sleep @sleep_between_image_download
      return true
    else
      sleep @sleep_between_image_download
      return false
    end

  end

  def download_images_for_list(list)
    list.each do |time_string|
      download_image(time_string)
    end
    # TODO store some info
  end


  def make_it_so
    @logger.info "Start of '#{@name}'"

    @tmp_storage_path = @storage.path_temp_for_desc("archive_#{@name}")

    # get from last
    list = get_image_list(time_string = "")
    download_images_for_list(list)

    sleep @sleep_between_lists

    last_time_string = ""
    last_time_string = list.last if list.size > 0

    while last_time_string != ""
      list = get_image_list(time_string = "")
      download_images_for_list(list)

      last_time_string = ""
      last_time_string = list.last if list.size > 0

      sleep @sleep_between_lists
    end

  end


end
