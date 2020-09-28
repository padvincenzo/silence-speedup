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
parser = argparse.ArgumentParser(description = "Speed-up your videos by speeding-up the silence, using Python and FFmpeg.")
parser.add_argument('-i', '--input_file',       type = str,                   help = "Video source path to be modified.")
parser.add_argument('-o', '--output_file',      type = str,   default = "",   help = "Output path (optional).")
parser.add_argument('-t', '--audio_threshold',  type = float, default = -30,  help = "This indicates what sample value should be treated as silence. For digital audio, a value of 0 may be fine but for audio recorded from analog, you may wish to increase the value to account for background noise. Unit of measurement: dB, default -50.")
parser.add_argument('-d', '--silence_duration', type = float, default = 0.3,  help = "Minimum value in seconds the silence should last to be considered, default 0.2.")
#parser.add_argument('-S', '--sounded_speed',    type = float, default = 1.00, help = "Speed of video fragments with audio, default 1.")
parser.add_argument('-s', '--silence_speed',    type = int,   default = 8,    help = "Speed of video fragments whith silence, default 8.")
parser.add_argument('-m', '--margin',           type = float, default = 0.1,  help = "Seconds of silence adjacent to the audio fragments to be considered as audio fragments, in order to have a context, default 0.1.")
parser.add_argument('-l', '--limit',            type = float, default = 0.0,  help = "Limit the seconds to be parsed (for a rapid check).")
parser.add_argument('-a', '--auto_detect',      action = "store_true",        help = "Use volumedetect's FFmpeg filter to detect the audio threshold.")
parser.add_argument('-x', '--no_audio',         action = "store_true",        help = "Remove audio from silence fragments.")
parser.add_argument('-X', '--silence_cut',      action = "store_true",        help = "Cut silence fragments.")
parser.add_argument('-k', '--keep_files',       action = "store_true",        help = "Do not delete temporary files from disk.")
parser.add_argument('-D', '--debug_mode',       action = "store_true",        help = "Display more information. If set, temporary files won't be deleted.")

args = parser.parse_args()


def deletePath(path):
	print("Removing folder {}...".format(path))
	try:
		rmtree(path, ignore_errors = False)
	except OSError:
		sys.exit("An error occurred while removing the folder {}. {}".format(path, OSError))

def createPath(debugMode, path):
	if debugMode:
		print("Creating the folder {}...".format(path))

	if os.path.isdir(path):
		question = "Folder {} already exists, should I remove it for you? Y/n ".format(path)

		# Need a string in input, the function name depends on Python version
		response = raw_input(question) if sys.version_info[0] < 3 else input(question)

		if response == "Y" or response == "y":
			deletePath(path)
			print("Folder removed.")
		else:
			sys.exit("Folder not removed.")
	try:
		os.mkdir(path)
	except OSError:
		sys.exit("An error occurred while removing the folder {}. {}".format(path, OSError))

def generateOutputName(fin):
	# Same path as input video
	dotIndex = fin.rfind(".")
	return "{}_mod{}".format(fin[: dotIndex], fin[dotIndex :])

def generateTmpDir(debugMode, fin):
	slashIndex = fin.rfind("/")
	dotIndex = fin.rfind(".")

	if dotIndex == -1:
		sys.exit("There's something wrong with the video name.")

	dir = "{}_tmp".format(fin[slashIndex + 1 : dotIndex])
	createPath(debugMode, dir)
	return dir

def getTime(tStart, tEnd):
	t = tEnd - tStart
	m, s = divmod(t, 60)
	h, m = divmod(m, 60)
	return "{:02d}:{:02d}:{:02d}".format(int(h), int(m), int(s))

def detectAudioThreshold(debugMode, fin, tmpDir):
	tStart = time.time()
	print("Detecting audio threshold...")
	sys.stdout.flush()

	fout = "{}/meanVolume.txt".format(tmpDir)

	command = "ffmpeg -hide_banner -i {} -af volumedetect -f null /dev/null 2>&1 | grep mean_volume | cut -d ':' -f 2 > {}".format(fin, fout)
	if debugMode:
		print("\nExecuting: {}\n".format(command))

	result = sp.call(command, shell = True)
	if result != 0:
		sys.exit("Something went wrong in threshold detection.")

	meanVolumeFile = open(fout, "r")
	meanVolume = meanVolumeFile.readline()
	meanVolumeFile.close()

	if not meanVolume:
		sys.exit("Error in {}".format(fout))

	threshold = re.match(" ((-|\+)?((\d+(\.\d+)?))) dB", meanVolume)

	if threshold is None:
		sys.exit("Unable to detect audio threshold.")

	value = float(threshold.group(1))

	tEnd = time.time()
	print("Threshold detected: {:.1f} dB. {:.1f} dB will be used as silence threshold. Time elapsed: {}".format(value, value - 5.0, getTime(tStart, tEnd)))
	sys.stdout.flush()

	return value - 5.0

def generateRawFragmentsFile(debugMode, fin, tmpDir, audioThreshold, silenceDuration, margin, limit):
	tStart = time.time()
	print("[0] Generating raw silence fragments' file...")
	sys.stdout.flush()

	limitString = "" if limit == 0 else "-to {:.3f}".format(limit)
	actualSilenceDuration = silenceDuration + 2 * margin
	command = "ffmpeg -hide_banner {} -i {} -af silencedetect=n={:.1f}dB:d={} -f null /dev/null 2>&1 | grep silencedetect | cut -d ']' -f 2 > {}/rawSilenceFragments.txt".format(limitString, fin, audioThreshold, actualSilenceDuration, tmpDir)
	if debugMode:
		print("\nExecuting: {}\n".format(command))

	result = sp.call(command, shell = True)
	if result != 0:
		sys.exit("    Something went wrong in silence detection.")

	tEnd = time.time()
	print("    Raw silence fragments' file generated, time elapsed: {}.".format(getTime(tStart, tEnd)))
	sys.stdout.flush()

def detectSilence(debugMode, fin, tmpDir, audioThreshold, silenceDuration, margin):
	tStart = time.time()
	print("[1] Detecting refined silence fragments...")
	sys.stdout.flush()

	rawFile = open("{}/rawSilenceFragments.txt".format(tmpDir), "r")
	getStartTime = re.compile(" silence_start: ((\d+(\.\d+)?)).*")
	getEndTime = re.compile(" silence_end: ((\d+(\.\d+)?)).*")

	eof = False
	lineCount = 0
	i = 0
	silenceFrames = []
	seconds = 0.0

	while not eof:
		lineStart = rawFile.readline()
		lineEnd = rawFile.readline()

		if (not lineStart) or (not lineEnd):
			eof = True
			break

		st = getStartTime.match(lineStart)
		et = getEndTime.match(lineEnd)

		if (st is None) or (et is None):
			sys.exit("    Error in file {}/rawSilenceFragments.txt, lines {} and {}".format(tmpDir, lineCount, lineCount + 1))

		lineCount += 2

		startTime = float(st.group(1)) + margin if float(st.group(1)) > 0.0 else 0.0
		endTime = float(et.group(1)) - margin

		if i > 0 and (startTime - silenceFrames[-1][1] <= margin):
			seconds += endTime - silenceFrames[-1][1]
			silenceFrames[-1] = (silenceFrames[-1][0], endTime)
		else:
			silenceFrames.append((startTime, endTime))
			seconds += endTime - startTime
			i += 1

	rawFile.close()

	if i == 0:
		sys.exit("    No silence detected, try with a higher threshold.")

	tEnd = time.time()
	print("    {} silence fragments detected for a total of {}. Time elapsed: {}.".format(i, getTime(0, seconds), getTime(tStart, tEnd)))
	sys.stdout.flush()

	return silenceFrames

def generateSpeedFilter(speed, noAudio):
	# If the speed is near 1, there's no need for a filter
	if speed >= 0.99 and speed <= 1.01:
		return "-af 'volume=enable=0'" if noAudio else ""

	filterVideo = "[0:v]setpts={:.3f}*PTS[v]".format(1.0 / speed)
	filterAudio = "[0:a]atempo={:.3f}{}[a]".format(speed, ", volume=enable=0" if noAudio else "")
	return "-filter_complex '{}; {}' -map '[v]' -map '[a]'".format(filterVideo, filterAudio)

def exportFragment(debugMode, fin, tmpDir, startTime, endTime, index, filter):
	startTimeString = "" if startTime == 0 else "-ss {:.3f}".format(startTime)
	endTimeString = "" if endTime == 0 else "-to {:.3f}".format(endTime)
	command = "ffmpeg -hide_banner -loglevel {} {} {} -i {} {} {}/f{:07d}.mp4".format("error -stats" if debugMode else "quiet", startTimeString, endTimeString, fin, filter, tmpDir, index)
	if debugMode:
		print("\nExecuting: {}\n".format(command))
	result = sp.call(command, shell = True)

	if result != 0:
		sys.exit("\nSomething went wrong with the exportation of the fragment #{} [{:.3f} s, {:.3f} s]. Here's the command that generated the error:\n{}".format(index, startTime, endTime, command))

def getPercentage(i, n):
	return "{:6.2f} %".format(float(i) / n * 100)

def printStat(debugMode, c, totalFragments):
	backPrint = "\b" * 8
	if debugMode:
		print("    Fragment extracted: {}/{}".format(c, totalFragments))
	else:
		print("{}{}".format(backPrint, getPercentage(c, totalFragments)), end = "")

def generateFragments(debugMode, fin, tmpDir, silenceFrames, soundSpeed, silenceSpeed, noAudio, silenceCut, limit):
	tStart = time.time()
	print("[2] Extracting and speeding-up fragments... ", end = "")
	if debugMode:
		print("")
	else:
		print("{}".format(getPercentage(0, 1)), end = "")
	sys.stdout.flush()

	if not silenceCut:
		silenceFilter = generateSpeedFilter(silenceSpeed, noAudio)
	soundFilter = generateSpeedFilter(1.0, False)

	# This file will contain the list of all fragments extracted
	fragmentsList = open("{}/fragmentsList.txt".format(tmpDir), "w")

	c = 0
	n = len(silenceFrames)
	totalFragments = n if silenceCut else 2 * n

	# First segment if the video starts with audio
	if silenceFrames[0][0] != 0.0:
		exportFragment(debugMode, fin, tmpDir, 0, silenceFrames[0][0], c, soundFilter)
		fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
		c = 1
		totalFragments += 1
		printStat(debugMode, c, totalFragments)

	for i in range(0, n):
		if not silenceCut:
			# Silence fragment
			exportFragment(debugMode, fin, tmpDir, silenceFrames[i][0], silenceFrames[i][1], c, silenceFilter)
			fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
			c += 1
			printStat(debugMode, c, totalFragments)
			sys.stdout.flush()

		# Audio fragment
		if i < n - 1:
			# Until the last fragment
			exportFragment(debugMode, fin, tmpDir, silenceFrames[i][1], silenceFrames[i + 1][0], c, soundFilter)
			fragmentsList.write("file 'f{:07d}.mp4'\n".format(c))
		else:
			# Last fragment
			exportFragment(debugMode, fin, tmpDir, silenceFrames[i][1], limit, c, soundFilter)
			fragmentsList.write("file 'f{:07d}.mp4'".format(c))
		c += 1
		printStat(debugMode, c, totalFragments)
		sys.stdout.flush()

	print("")
	fragmentsList.close()

	tEnd = time.time()
	print("    Video fragments succesfully extracted, time elapsed: {}.".format(getTime(tStart, tEnd)))
	sys.stdout.flush()

def recombine(debugMode, tmpDir, fout):
	tStart = time.time()
	print("[3] Reassembling video fragments...")
	sys.stdout.flush()

	command = "ffmpeg -hide_banner -loglevel {} -f concat -safe 0 -i {}/fragmentsList.txt -c copy {}".format("error -stats" if debugMode else "quiet", tmpDir, fout)
	if debugMode:
		print("\nExecuting: {}\n".format(command))
	result = sp.call(command, shell = True)
	if result != 0:
		sys.exit("    An error occurred while recombinig the video.")

	tEnd = time.time()
	print("    Video succesfully recombined. Time elapsed: {}.".format(getTime(tStart, tEnd)))


if args.input_file == None:
	sys.exit("No video source specified.")

if not os.path.isfile(args.input_file):
	sys.exit("Video source do not exists")

fin = args.input_file.replace(" ", "\\ ").replace("(", "\\(").replace(")", "\\)")
debugMode = args.debug_mode
tmpDir = generateTmpDir(debugMode, fin)

fout = args.output_file if len(args.output_file) >= 1 else generateOutputName(fin)
audioThreshold = args.audio_threshold
silenceDuration = args.silence_duration
silenceSpeed = args.silence_speed
margin = args.margin
autoDetect = args.auto_detect
noAudio = args.no_audio
silenceCut = args.silence_cut
limit = 0 if args.limit <= 0.1 else args.limit
keepFiles = True if debugMode else args.keep_files

print("\n {} --> {}\n".format(fin, fout))

tStart = time.time()

if autoDetect:
	audioThreshold = detectAudioThreshold(debugMode, fin, tmpDir)

#1
generateRawFragmentsFile(debugMode, fin, tmpDir, audioThreshold, silenceDuration, margin, limit)
#2
silenceFrames = detectSilence(debugMode, fin, tmpDir, audioThreshold, silenceDuration, margin)
#3
generateFragments(debugMode, fin, tmpDir, silenceFrames, 1.0, silenceSpeed, noAudio, silenceCut, limit)
#4
recombine(debugMode, tmpDir, fout)

if not keepFiles:
	deletePath(tmpDir)

tEnd = time.time()
print("\nYour video {} is ready! Total time elapsed: {}.".format(fout, getTime(tStart, tEnd)))
