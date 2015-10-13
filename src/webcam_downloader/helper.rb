class WebcamDownloader::Helper
  def self.monthly_prefix(time)
    time.strftime('%Y_%m')
  end
end
