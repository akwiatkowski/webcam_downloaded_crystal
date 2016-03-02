require "../src/webcam_downloader"

w = WebcamDownloader::ArchiveManager.new
w.logger.level = Logger::DEBUG
w.logger.level = Logger::INFO
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

  # new, much
  "winklern",
  "laax",

  # quite
  "lorenzalm",
  "freiwandeck",
  "meran",
  "konkordiahuette",
  "hochkoenig",
  "sonnblick",

  # less interesting
  "falkert",
  "kaiserburg",
  "rangersdorf",
  "burgstalleralm",
  "heiligenblut",
  "kals",
  "hochkar",
  "sonnblickbasis",
  "pendling-ost",
  "sonnenbichl",
  "tegelberg",
  "schroecken",
  "wien"

].uniq

w.format = "hd"
w.resize = false
w.sleep_between_lists = 5
w.sleep_between_image_download = 3

w.setup
w.make_it_so

sleep 0.1
