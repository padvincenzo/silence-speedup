# Only for Python 2.x
from __future__ import print_function
import sys
import numpy as np
import subprocess as sp
import re
import math
from shutil import rmtree
import os
import time
import argparse

# Script arguments
parser = argparse.ArgumentParser(description = "Speed-up your videos (or audios) by speeding-up the silence, using Python and FFmpeg.")
parser.add_argument('-i', '--input_file',       type = str,                   help = "Video source path to be modified.")
parser.add_argument('-o', '--output_file',      type = str,   default = "",   help = "Output path (optional).")
parser.add_argument('-t', '--audio_threshold',  type = int,   default = -30,  help = "This indicates what sample value should be treated as silence. For digital audio, a value of 0 may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Unit of measurement: dB, default -50.")
parser.add_argument('-d', '--silence_duration', type = float, default = 0.4,  help = "Minimum value in seconds the silence should last to be considered, default 0.2.")
#parser.add_argument('-S', '--sounded_speed',    type = float, default = 1.00, help = "Speed of video fragments with audio, default 1.")
parser.add_argument('-s', '--silence_speed',    type = int,   default = 8,    help = "Speed of video fragments whith silence, default 8.")
parser.add_argument('-m', '--margin',           type = float, default = 0.01, help = "Seconds of silence adjacent to the audio fragments to be considered as audio fragments, in order to have a context, default 0.1.")
parser.add_argument('-k', '--keep_files',       action = 'store_true',        help = "Do not delete temporary files from disk.")

args = parser.parse_args()


def deletePath(s): # Dangerous! Watch out!
	print("Removing folder {}...".format(s))
	try:
		rmtree(s, ignore_errors = False)
	except OSError:
		print ("An error occurred while removing the folder {}.".format(s))
		print(OSError)

def createPath(s):
	#print("Creating the folder {}...".format(s))
	if os.path.isdir(s):
		response = input("Folder {} already exists, should I remove it for you? Y/n ".format(s))
		if response == "Y" or response == "y":
			deletePath(s)
			print("Folder removed.")
		else:
			assert False, "Folder not removed."
	try:
		os.mkdir(s)
	except OSError:
		assert False, "An error occurred while removing the folder {}.".format(s)

def generateOutputName(fin):
	# Stesso path del file input
	dotIndex = fin.rfind(".")
	return "{}_mod{}".format(fin[: dotIndex], fin[dotIndex :])

def generateTmpDir(fin):
	slashIndex = fin.rfind("/")
	dotIndex = fin.rfind(".")
	dir = "{}_tmp".format(fin[slashIndex + 1 : dotIndex])
	createPath(dir)
	return dir

def getTime(tStart, tEnd):
	t = tEnd - tStart
	m, s = divmod(t, 60)
	h, m = divmod(m, 60)
	return "{:02d}:{:02d}:{:02d}".format(int(h), int(m), int(s))

def detectSilence(fin, tmpDir, silenceThreshold = -30, silenceDuration = 0.4, margin = 0.01):
	tStart = time.time()
	print("Detecting silence fragments...")
	sys.stdout.flush()

	actualSilenceDuration = silenceDuration + 2 * margin
	command = "ffmpeg -hide_banner -i {} -af silencedetect=n={}dB:d={} -f null /dev/null 2>&1 | grep silencedetect | cut -d ']' -f 2 > {}/raw.txt".format(fin, silenceThreshold, actualSilenceDuration, tmpDir)
	sp.call(command, shell = True)

	rawFile = open("{}/raw.txt".format(tmpDir), "r")
	getStartTime = re.compile(" silence_start: ((\d+(\.\d+)?)).*")
	getEndTime = re.compile(" silence_end: ((\d+(\.\d+)?)).*")

	eof = False
	lineCount = 0
	i = 0
	silenceFrames = []

	while not eof:
		lineStart = rawFile.readline()
		lineEnd = rawFile.readline()

		if (not lineStart) or (not lineEnd):
			eof = True
			break

		st = getStartTime.match(lineStart)
		et = getEndTime.match(lineEnd)

		assert (st is not None) and (et is not None), "Error in file {}/raw.txt, lines {} and {}".format(tmpDir, lineCount, lineCount + 1)
		lineCount += 2

		startTime = float(st.group(1)) + margin if float(st.group(1)) > 0.0 else 0.0
		endTime = float(et.group(1)) - margin

		if i > 0 and (startTime - silenceFrames[-1][1] <= margin):
			silenceFrames[-1] = (silenceFrames[-1][0], endTime)
		else:
			silenceFrames.append((startTime, endTime))
			i += 1

	rawFile.close()

	assert i > 0, "No silence detected, try with a higher threshold."

	tEnd = time.time()
	print("{} silence fragments detected, time: {}.".format(i, getTime(tStart, tEnd)))
	sys.stdout.flush()

	return silenceFrames

def generateFilter(speed = 1.0):
	if speed >= 0.99 and speed <= 1.01:
		return ""

	filterVideo = "[0:v]setpts={:.2f}*PTS[v]".format(1 / speed)
	filterAudio = "[0:a]atempo={:.2f}[a]".format(speed)
	return "-filter_complex '{};{}' -map '[v]' -map '[a]'".format(filterVideo, filterAudio)

def exportFragment(fin, tmpDir, startTime, endTime, index, filter = ""):
	startTimeString = "" if startTime == 0.0 else "-ss {:.3f}".format(startTime)
	endTimeString = "" if endTime == "end" else "-to {:.3f}".format(endTime)
	command = "ffmpeg -hide_banner -loglevel quiet {} {} -i {} {} {}/f{:07d}.mp4".format(startTimeString, endTimeString, fin, filter, tmpDir, index)
	sp.call(command, shell = True)

def generateFragments(fin, tmpDir, silenceFrames, silenceSpeed):
	tStart = time.time()
	print("Extracting and speeding-up fragments...   0.00 %", end = "")
	sys.stdout.flush()

	backPrint = "\b" * 8

	silenceFilter = generateFilter(silenceSpeed)
	soundFilter = generateFilter(1.0)

	# This file will contain the list of all fragments extracted
	fragmentsList = open("{}/fragmentsList.txt".format(tmpDir), "w")

	i = 0
	c = 0
	n = len(silenceFrames)

	# First segment if the video starts with audio
	if silenceFrames[0][0] != 0.0:
		exportFragment(fin, tmpDir, 0, silenceFrames[0][0], c, soundFilter)
		fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
		c = 1
		print("{}{:6.2f} %".format(backPrint, float(c) / n * 100), end = "")

	for frame in silenceFrames:
		# Silence fragment
		exportFragment(fin, tmpDir, silenceFrames[i][0], silenceFrames[i][1], c, silenceFilter)
		fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
		c += 1
		print("{}{:6.2f} %".format(backPrint, float(c) / n * 100), end = "")

		# Audio fragment
		if i < n - 1:
			exportFragment(fin, tmpDir, silenceFrames[i][1], silenceFrames[i + 1][0], c, soundFilter)
			fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
		else:
			exportFragment(fin, tmpDir, silenceFrames[i][1], "end", c, soundFilter)
			fragmentsList.write("file 'f{:07d}.mp4'".format(c))
		c += 1
		print("{}{:6.2f} %".format(backPrint, float(c) / n * 100), end = "")

		i += 1

	print("{}100.00 %".format(backPrint))
	sys.stdout.flush()
	fragmentsList.close()

	tEnd = time.time()
	print("Video fragments succesfully extracted, time: {}.".format(getTime(tStart, tEnd)))
	sys.stdout.flush()

def recombine(tmpDir, fout):
	tStart = time.time()
	print("Reassembling video fragments...")
	sys.stdout.flush()

	command = "ffmpeg -hide_banner -loglevel quiet -f concat -safe 0 -i {}/fragmentsList.txt -c copy {}".format(tmpDir, fout)
	result = sp.call(command, shell = True)
	assert result == 0, "An error occurred while recombinig the video."

	tEnd = time.time()
	print("Video succesfully recombined, time: {}.".format(getTime(tStart, tEnd)))


assert args.input_file != None, "No video source specified"
assert os.path.isfile(args.input_file), "Video source do not exists"

tmpDir = generateTmpDir(args.input_file)

fin = args.input_file
fout = args.output_file if len(args.output_file) >= 1 and (not os.path.isfile(args.input_file)) else generateOutputName(fin)
silenceThreshold = args.silence_threshold
silenceDuration = args.silence_duration
silenceSpeed = args.silence_speed
margin = args.margin
keepFiles = args.keep_files

print("\n {} --> {}\n".format(fin, fout))

tStart = time.time()

silenceFrames = detectSilence(fin, tmpDir, silenceThreshold, silenceDuration, margin)
generateFragments(fin, tmpDir, silenceFrames, silenceSpeed)
recombine(tmpDir, fout)

if not keepFiles:
	deletePath(tmpDir)

tEnd = time.time()
print("Your video is ready! Total time: {}.".format(getTime(tStart, tEnd)))
