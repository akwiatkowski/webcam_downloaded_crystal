require "../src/webcam_downloader"

w = WebcamDownloader::ArchiveDownloader.new
w.server_host = "http://www.foto-webcam.eu/"
w.server_webcam_path = "webcam/"
w.server_list_path = "webcam/include/list.php"
w.name = "duel"
w.make_it_so
