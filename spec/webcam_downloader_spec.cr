require "./spec_helper"

describe WebcamDownloader do
  it "works" do
    w = WebcamDownloader::Downloader.new
    w.load_config 
  end
end
