require "../src/webcam_downloader"

# http://www.foto-webcam.eu/
# TODO
# flattach
# lorenzalm
# lienz - !!!
# kronplatz - !!!
# gantkofel - !!!
# meran - !!!
# ankogel-sued - !!!
# schareck - !
# gletscher-sued - !
# obervellach - !!
# ederplan - !!!
# winklern - !!
# burgstalleralm
# heiligenblut
# meran - !!!
# konkordiahuette
# hochkar
# gernkogel - !
# hochkoenig
# zellamsee - !!
# schroecken
# innichen-Leitlhof

w = WebcamDownloader::ArchiveDownloader.new
w.server_host = "http://www.foto-webcam.eu/"
w.server_webcam_path = "webcam/"
w.server_list_path = "webcam/include/list.php"
w.name = "lienz"
w.make_it_so
