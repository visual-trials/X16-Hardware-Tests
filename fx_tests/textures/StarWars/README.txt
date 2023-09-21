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

# We want a framerate of 19.8412698413, BUT ffmpeg can only do 19.84fps (for video)
# So the audio rate should have been 43869.02Hz, but we are going to use 43866.2123827
   (19.84/19.8412698413*43869.02 = 43866.2123827)

DO THIS: (320x136@19.84fps)
./ffmpeg -t 01:00 -i Walkers.mp4 -vf scale=320:-1,crop=320:136:0:22 -r 19.84 output/output_%04d.png

./ffmpeg -t 01:00 -i Walkers.mp4 -vn -ar 43866 -f s16le -ac 1 -acodec pcm_s16le output.raw

