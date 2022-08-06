# script to compute optical flow of two images given as arguments

# run with
#     python ./pyUtils/CalcOpticalFlow0.py ./dataset.test.images.1/pexels-mathias-reding-12624892.ppm ./dataset.test.images.1/pexels-mathias-reding-12624892.ppm > tempFlowTxt.txt

import sys

import numpy as np
import cv2 as cv


# read images
currentframe = cv.imread(sys.argv[1], cv.IMREAD_COLOR)
previousframe = cv.imread(sys.argv[2], cv.IMREAD_COLOR)

currentframe_gray = cv.cvtColor(currentframe, cv.COLOR_BGR2GRAY)
previousframe_gray = cv.cvtColor(previousframe, cv.COLOR_BGR2GRAY)

"""
# params for ShiTomasi corner detection
feature_params = dict( maxCorners = 100,
                       qualityLevel = 0.3,
                       minDistance = 7,
                       blockSize = 7 )
# Parameters for lucas kanade optical flow
lk_params = dict( winSize  = (15, 15),
                  maxLevel = 2,
                  criteria = (cv.TERM_CRITERIA_EPS | cv.TERM_CRITERIA_COUNT, 10, 0.03))



p0 = cv.goodFeaturesToTrack(previousframe_gray, mask = None, **feature_params)


# calculate optical flow
p1, st, err = cv.calcOpticalFlowPyrLK(previousframe_gray, currentframe_gray, p0, None, **lk_params)

# Select good points
if p1 is not None:
    good_new = p1[st==1]
    good_old = p0[st==1]
"""


"""
# draw the tracks
for i, (new, old) in enumerate(zip(good_new, good_old)):
    a, b = new.ravel()
    c, d = old.ravel()
    mask = cv.line(mask, (int(a), int(b)), (int(c), int(d)), color[i].tolist(), 2)
    frame = cv.circle(frame, (int(a), int(b)), 5, color[i].tolist(), -1)
img = cv.add(frame, mask)
cv.imshow('frame', img)
k = cv.waitKey(30) & 0xff
if k == 27:
    break
# Now update the previous frame and previous points
old_gray = frame_gray.copy()
p0 = good_new.reshape(-1, 1, 2)
cv.destroyAllWindows()
"""


# see https://www.geeksforgeeks.org/python-opencv-dense-optical-flow/

# Calculates dense optical flow by Farneback method
flow = cv.calcOpticalFlowFarneback(previousframe_gray, currentframe_gray, 
                                    None,
                                    0.5, 3, 15, 3, 5, 1.2, 0)


channelA = flow[..., 0]
channelB = flow[..., 1]
# Computes the magnitude and angle of the 2D vectors
#channelA, channelB = cv.cartToPolar(flow[..., 0], flow[..., 1])

dimensions = (int(channelA.shape[0]),int(channelA.shape[1]))

channelAResized = cv.resize(channelA, dimensions, interpolation=cv.INTER_AREA)
channelBResized = cv.resize(channelB, dimensions, interpolation=cv.INTER_AREA)



## OUTPUT side,  print dimensions and actual values for magnitude pixels and angle pixels

print(str(channelAResized.shape[0])+" "+str(channelAResized.shape[1]))

for i in range(channelAResized.shape[1]): # loop over y
    for j in range(channelAResized.shape[0]): # loop over x
        print("m "+str(j)+","+str(i)+"="+str(channelAResized[j][i]))

for i in range(channelBResized.shape[1]):
    for j in range(channelBResized.shape[0]):
        print("a "+str(j)+","+str(i)+"="+str(channelBResized[j][i]))

