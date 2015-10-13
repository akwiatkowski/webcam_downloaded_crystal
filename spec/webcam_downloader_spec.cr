require "./spec_helper"

describe WebcamDownloader do
  it "works" do
    w = WebcamDownloader::Downloader.new
    w.setup
    w.one_loop
  end
end
