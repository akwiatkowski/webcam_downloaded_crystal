require "../src/webcam_downloader"

w = WebcamDownloader::Downloader.new
w.webcam_array.pool_size = 4
w.setup
w.run_loop
