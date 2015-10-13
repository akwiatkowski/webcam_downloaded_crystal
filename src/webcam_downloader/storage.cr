class WebcamDownloader::Storage
  def initialize(_logger)
    @logger = _logger
    @monthly_prefix = ""

    @desc_array = [] of String

    @logger.debug "#{self.class} initialized"
  end

  def setup
    prepare
  end

  def prepare
    %w(tmp data pix latest) + [File.join("latest", "pix")].each do |path|
      Dir.mkdir_p(path) unless Dir.exists?(path)
    end
  end

  def prepare_monthly_directories
    mp = WebcamDownloader::Helper.monthly_prefix(Time.now)
    return if @monthly_prefix == mp

    logger.debug("Prepare monthly directories for #{mp}")

    # monthly dir
    f = File.join("pix", mp)
    Dir.mkdir_p(f) unless Dir.exists?(f)

    # dir per webcam
    downloader.webcams.each do |webcam|
      f = File.join("pix", mp, webcam.desc)
      Dir.mkdir(f) unless Dir.exists?(f)
    end

    @monthly_prefix = mp

    @logger.debug("Prepare monthly directories for #{mp} - finished")
  end
end
