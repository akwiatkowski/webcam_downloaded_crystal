require "yaml"
#require "webcam_downloader/webcam"

class WebcamDownloader::Downloader
  def initialize
    @webcams = [] of WebcamDownloader::Webcam
  end

  def load_config
    Dir["config/*.yml"].each do |path|
      load_config_file(path)
    end
  end

  def load_config_file(path)
    s = File.read(path)
    data = YAML.load(s) as Array

    data.each do |h|
      @webcams.push WebcamDownloader::Webcam.new(h)
    end

    puts "config loaded #{path}"
  end




end
