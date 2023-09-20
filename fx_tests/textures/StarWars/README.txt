Walkers: https://www.youtube.com/watch?v=J3u3731eGTM

FFMPEG: https://gist.github.com/FranciscoG/c63760be6d77ab44d919772b2b7b8f82

# -i  followed by video file sets input stream
# -r  set framerat.   1 = 1 frame per second. 
# and then set the output file with the number replacement

# more info:  https://ffmpeg.org/ffmpeg.html#Main-options
# https://superuser.com/questions/135117/how-to-convert-video-to-images

# add -t MM:SS to reduce how much of the video you want to connvert
# crop: https://video.stackexchange.com/questions/4563/how-can-i-crop-a-video-with-ffmpeg

# reduce the file size of the pngs b

DO THIS: (320x136@20fps)
./ffmpeg -ss 01:12 -t 00:15 -i Walkers.mp4 -vf scale=320:-1,crop=320:136:0:22  -r 20 output/output_%04d.png

