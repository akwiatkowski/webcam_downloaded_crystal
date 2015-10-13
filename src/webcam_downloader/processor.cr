require "crypto/md5"

class WebcamDownloader::Processor
  def initialize(_logger)
    @logger = _logger

    @resolution = "1920x1080"
    @jpeg_quality = 84 # not used

    @logger.debug "#{self.class} initialized"
  end

  def is_valid_image?(path)
    return ( File.exists?(path) && File.size(path) > 0 )
  end

  def resize(from_path, to_path, jpeg_quality)
    command = "convert \"#{from_path}\" -resize '#{@resolution}>' -quality #{jpeg_quality}% \"#{to_path}\""
    #command = "cp #{from_path} #{to_path}"
    `#{command}`
  end

  def md5(path)
    return "" unless File.exists?(path)
    return Crypto::MD5.hex_digest( File.read(path) )
  end
end
