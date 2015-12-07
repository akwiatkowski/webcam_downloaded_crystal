require "../src/webcam_downloader"

w = WebcamDownloader::ArchiveManager.new
w.logger.level = Logger::DEBUG
w.names = [
  "flattach",
  "dobratsch",
  "lienz",
  "ankogel-sued",
  "schareck",
  "gletscher-sued",
  "obervellach",
  "moertschach",
  "wallackhaus",
  "stveit",
  "kronplatz",
  "gantkofel",
  "zellamsee",
  "passthurn",
  "innsbruck",
  "traunstein",
  "hochries",
  "pendling-ost",
  "wank",
  "karwendel",
  "norderney",
]

w.format = "hd"
w.resize = false
w.sleep_between_lists = 10
w.sleep_between_image_download = 4

w.setup
w.make_it_so


sleep 0.1
