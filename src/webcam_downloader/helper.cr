class WebcamDownloader::Helper
  def self.monthly_prefix(time)
    time.to_s("%Y_%m")
  end

  def self.size_to_human(size)
    {
      "B"  => 1024,
      "KB" => 1024 * 1024,
      "MB" => 1024 * 1024 * 1024,
      "GB" => 1024 * 1024 * 1024 * 1024,
      "TB" => 1024 * 1024 * 1024 * 1024 * 1024
    }.each { |e, s| return "#{(size.to_f / (s / 1024)).round(2)}#{e}" if size < s }
  end
end
