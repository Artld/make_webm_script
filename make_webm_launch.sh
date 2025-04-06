#!/bin/bash

      FILE="/path/to/movie.mkv"
AUDIO_FILE=""
 SUBS_FILE="/path/to/subtitles.ass"

/usr/bin/ffprobe -hide_banner "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

# HH:MM:SS.ms
SS="00:01:56.800"
TO="00:02:18.600"
VIDEO_STREAM="0"; AUDIO_STREAM="1"; SUBS_STREAM=""
# mkv, mp4, webm
CONT="webm"
# copy, libvpx-vp9, libx264, libx265, h264_nvenc, hevc_nvenc
CV="libvpx-vp9"
# libvpx-vp9: 0–63, h26*: 0-51
CRF=30
# 0..8 for libvpx-vp9 and libx26*, 18..12 for h264_nvenc and hevc_nvenc
ENCODING_SPEED="1"
# yuv420p
PIX_FMT=""
# -2:720, -2:1080
SCALE=""
SPEED=1.2
# copy, libopus, libfdk_aac
CA="libopus"
BA="192K"
HARDSUB=false

# Metadata
TITLE="Episode title"
VIDEO_LANG="jpn"
AUDIO_LANG="jpn"
SUBS_LANG="eng"

# Filename
SUFFIX="$CV $CA crf $CRF"
TEMP="/home/user/folder for temporary files and output"

# Preview
#if [ -n "$SS" ]; then START="--start=$SS"; fi
#if [ -n "$TO" ]; then END="--end=$TO"; fi
#/usr/bin/mpv $START $END "$FILE"
#read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

${BASH_SOURCE%/*}/make_webm.sh "$FILE" "$AUDIO_FILE" "$SUBS_FILE" "$VIDEO_STREAM" "$AUDIO_STREAM" "$SUBS_STREAM" "$SS" "$TO" "$CONT" "$CV" "$CRF" "$ENCODING_SPEED" "$PIX_FMT" "$SCALE" "$SPEED" "$CA" "$BA" "$HARDSUB" "$TITLE" "$VIDEO_LANG" "$AUDIO_LANG" "$SUBS_LANG" "$SUFFIX" "$TEMP"
