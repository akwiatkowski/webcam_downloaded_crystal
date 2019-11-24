require "../src/webcam_downloader"

t = WebcamDownloader::TimelapseGenerator.new
t.archived = false
t.name = "zakopianka"
t.path = "/media/cdrom/backup/webcam_downloader/"

t.mencoder_preset = "fhd"

t.make_it_so
