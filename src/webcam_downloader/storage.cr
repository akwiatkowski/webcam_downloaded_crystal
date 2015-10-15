class WebcamDownloader::Storage
  def initialize(_logger, _processor)
    @logger = _logger
    @processor = _processor

    @monthly_prefix = ""

    @desc_array = [] of String

    @logger.debug "Storage initialized"
  end

  property :desc_array
  getter :processor

  def setup
    prepare_directories
  end

  def prepare_directories
    %w(tmp data pix www) + [File.join("www", "pix")].each do |path|
      Dir.mkdir_p(path) unless Dir.exists?(path)
    end
  end

  def prepare_monthly_directories
    mp = WebcamDownloader::Helper.monthly_prefix(Time.now)
    return if @monthly_prefix == mp

    # monthly dir
    f = File.join("pix", mp)
    Dir.mkdir_p(f) unless Dir.exists?(f)

    # dir per webcam
    @desc_array.each do |desc|
      f = File.join("pix", mp, desc)
      Dir.mkdir(f) unless Dir.exists?(f)
    end

    @monthly_prefix = mp

    @logger.debug("Storage prepared monthly directories for #{mp}")
  end

  # paths for webcam
  def path_temp_for_desc(desc)
    return File.join("tmp", "tmp_" + desc + Time.now.epoch.to_s + ".jpg.tmp")
  end

  def path_temp_processed_for_desc(desc)
    return File.join("tmp", "tmp_" + desc + Time.now.epoch.to_s + "_proc.jpg.tmp")
  end

  def path_store_for_desc(desc)
    return File.join("pix", @monthly_prefix, desc, "#{desc}_#{Time.now.epoch}.jpg")
  end

  def move(from_path, to_path)
    `mv #{from_path} #{to_path}`
  end

  def latest_path(desc)
    return File.join("www", "pix", "#{desc}.jpg")
  end

  def latest_link(desc, _path_store)
    command = "ln -sf \"../../#{_path_store}\" \"#{latest_path(desc)}\""
    `#{command}`
  end
end
