#!/bin/bash

      FILE="/path/to/movie.mkv"
AUDIO_FILE=""
 SUBS_FILE="/path/to/subtitles.ass"

/usr/bin/ffprobe -hide_banner "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

# HH:MM:SS.ms, start, end
SS="00:16:46.800"
TO="00:17:48.600"
AUDIO="1"; SUBS=""
# mkv, mp4, webm
CONT="webm"
# vp9, hevc, x264, copy
CV="vp9"
CRF=30
# for hevc/x264 only: ultrafast, superfast, veryfast, faster, fast, medium, slow, slower, veryslow
PRESET="medium"
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
if [ "$SS" != "start" ]; then START="--start=$SS"; fi
if [ "$TO" != "end" ]; then END="--end=$TO"; fi
/usr/bin/mpv $START $END "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

${BASH_SOURCE%/*}/make_webm_next.sh "$FILE" "$AUDIO_FILE" "$SUBS_FILE" "$AUDIO" "$SUBS" "$SS" "$TO" "$CONT" "$CV" "$CRF" "$PRESET" "$CA" "$BA" "$TITLE" "$VIDEO_LANG" "$AUDIO_LANG" "$SUBS_LANG" "$HARDSUB" "$TEMP"
