class WebcamDownloader::Helper
  def self.monthly_prefix(time)
    time.to_s("%Y_%m")
  end
end
