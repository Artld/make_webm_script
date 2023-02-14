#!/bin/bash

      FILE="/path/to/movie.mkv"
AUDIO_FILE=""
 SUBS_FILE="/path/to/subtitles.ass"

/usr/bin/ffprobe -hide_banner "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

# HH:MM:SS.ms
SS="00:16:46.800"
TO="00:17:48.600"
VIDEO="0"; AUDIO="1"; SUBS=""
# mkv, mp4, webm
CONT="webm"
SCALE="-2:720"
# vp9, x264, x265, copy
CV="vp9"
CRF=30
# 0..8
ENCODE_SPEED="2"
# libopus, libfdk_aac, copy
CA="libopus"
BA="192K"
TITLE="Episode title"
VIDEO_LANG="jpn"
AUDIO_LANG="jpn"
SUBS_LANG="eng"
HARDSUB=false
TEMP="/home/user/folder for temporary files and output"

# Preview
if [ -n "$SS" ]; then START="--start=$SS"; fi
if [ -n "$TO" ]; then END="--end=$TO"; fi
/usr/bin/mpv $START $END "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

${BASH_SOURCE%/*}/make_webm.sh "$FILE" "$AUDIO_FILE" "$SUBS_FILE" "$VIDEO" "$AUDIO" "$SUBS" "$SS" "$TO" "$CONT" "$SCALE" "$CV" "$CRF" "$ENCODE_SPEED" "$CA" "$BA" "$TITLE" "$VIDEO_LANG" "$AUDIO_LANG" "$SUBS_LANG" "$HARDSUB" "$TEMP"
