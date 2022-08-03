# script to grab a frame from the camera and store it as a image

#FIXME 1.08.2022< UNTESTED!!! >

import cv2

videoDeviceIdx = 0
videoStream = cv2.VideoCapture(videoDeviceIdx)

ret, frame = videoStream.read()

cv2.imwrite('outCurrentFrameFromCamera.png',frame)
