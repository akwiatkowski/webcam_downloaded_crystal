require "json"

class WebcamDownloader::StatsWriter
  def initialize(_logger, _webcam_array)
    @logger = _logger
    @webcam_array = _webcam_array

    @path = File.join("www", "data.json")
  end

  def make_it_so
    result = String.build do |node|
      node.json_array do |array|
        @webcam_array.webcams.each do |webcam|
          array << webcam.json_data
        end
      end
    end

    File.write(@path, result)
    @logger.debug("Stats JSON saved")
  end
end
