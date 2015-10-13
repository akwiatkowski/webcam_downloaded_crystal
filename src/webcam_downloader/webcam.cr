class WebcamDownloader::Webcam
  def initialize(hash, parent)
    @parent = parent as Downloader
    #@desc = (hash as Hash(YAML::Type, YAML::Type))[:desc] as String
  end

  getter :desc
end
