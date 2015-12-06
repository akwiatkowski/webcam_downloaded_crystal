require "../src/webcam_downloader"

t = WebcamDownloader::TimelapseGenerator.new
t.archived = true
t.name = "lienz"

t.mencoder_preset = "fhd"

t.make_it_so
