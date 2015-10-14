require "./spec_helper"

describe WebcamDownloader do
  it "works" do
    w = WebcamDownloader::Downloader.new
    w.webcam_array.pool_size = 4
    w.setup
    w.one_loop
    w.one_loop

    #w.run_loop
  end
end
