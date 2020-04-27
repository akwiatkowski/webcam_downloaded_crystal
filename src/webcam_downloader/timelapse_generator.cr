require "logger"
require "colorize"

class WebcamDownloader::TimelapseGenerator
  def initialize
    @logger = Logger.new(STDOUT)
    @logger.level = Logger::DEBUG
    @logger.level = Logger::INFO
    @logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
      io << severity.to_s << ", [" << datetime.to_s("%H:%M:%S.%L") << "] "
      io << ": " << message
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

    @archived = false
    @name = "sample"
    @output_time = Time.local

    # time, path, size
    @images = [] of Tuple(Time, String, UInt64)
    @month_dirs = [] of String
    @months_path = ""

    @output_path = ""

    # mencoder
    @mencoder_preset = "fhd"
    @mencoder_width = 1920
    @mencoder_height = 1080
    @mencoder_bitrate = 10000
    @mencoder_fps = 25
    @mencoder_ratio = (@mencoder_width.to_f / @mencoder_height.to_f).as(Float64)
    @mencoder_crop = false

    # -1 true aspect ratio
    # -2 fit into movie size, aspect not maintained
    @mencoder_aspect_ratio_type = -1

    # you can create using files from external disk
    @path = "."
  end

  SPECIAL_DIRS = [".", "..", "archived"]

  property :archived, :name
  property :mencoder_preset
  property :path

  def is_archived?
    return @archived == true
  end

  def make_it_so
    scan_for_months
  end

  def months_path
    if is_archived?
      return File.join([@path, "pix", "archived"])
    else
      return File.join([@path, "pix"])
    end
  end

  def scan_for_months
    @months_path = months_path
    @month_dirs = Dir.entries(@months_path)
    @month_dirs -= SPECIAL_DIRS

    @month_dirs.each do |mp|
      scan_month_dir(mp)
    end

    sort_images
    write_list
  end

  def scan_month_dir(month_path)
    p = File.join([@months_path, month_path, @name])
    if File.exists?(p)
      scan_image_dir(p)
    end
  end

  def scan_image_dir(path)
    (Dir.entries(path) - SPECIAL_DIRS).each do |i|
      # time
      match = i.scan(/(\d{5,20})/)
      t = match[0][1]
      time = Time.unix(t.to_i)

      # path
      full_path = File.join([path, i])

      # size
      size = File.size(full_path)

      @images << {time, full_path, size}
    end
  end

  def sort_images
    @images = @images.sort do |a, b|
      a[0] <=> b[0]
    end
  end

  def get_output_path(sufix) : String
    return File.join(@path, "data", "timelapse_#{@name}_#{@output_time.to_unix}#{sufix}")
  end

  def write_list
    output_path = get_output_path(".txt")
    path_csv = get_output_path(".csv")
    path_command = get_output_path(".sh")

    @output_path = output_path

    f = File.new(output_path, "w")
    @images.each do |i|
      f.puts i[1]
    end
    f.close

    f = File.new(path_csv, "w")
    @images.each do |i|
      f.puts "#{i[0].to_unix}; '#{i[1]}'; #{i[2]}"
    end
    f.close

    f = File.new(path_command, "w")
    f.puts(generate_command)
    f.close
  end

  def generate_command
    if @mencoder_preset == "hd"
      @mencoder_width = 1280
      @mencoder_height = 720
      @mencoder_bitrate = 5000
    end

    if @mencoder_preset == "480p"
      @mencoder_width = 854
      @mencoder_height = 480
      @mencoder_bitrate = 3000
    end

    @mencoder_ratio = @mencoder_width.to_f / @mencoder_height.to_f
    @output_avi = get_output_path(".avi").as(String)

    if @mencoder_crop
      scale_crop_string = "-aspect #{@mencoder_ratio} -vf scale=#{@mencoder_aspect_ratio_type}:#{@mencoder_height},crop=#{@mencoder_width}:#{@mencoder_height} -sws 9 "
    else
      scale_crop_string = "-vf scale=#{@mencoder_aspect_ratio_type} -sws 9 "
    end

    input_string = "\"mf://@#{@output_path}\" "
    fps_string = "-mf fps=#{@mencoder_fps} "
    options_string = "-ovc xvid -xvidencopts noqpel:nogmc:trellis:nocartoon:nochroma_me:chroma_opt:lumi_mask:max_iquant=7:max_pquant=7:max_bquant=7:bitrate=#{@mencoder_bitrate}:threads=120 "
    output_string = "-o \"#{@output_avi}\" -oac copy "
    command = "mencoder #{input_string}#{fps_string}#{scale_crop_string}#{options_string}#{output_string}"

    return command
  end
end
