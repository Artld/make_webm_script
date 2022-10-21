#!/bin/bash

FILE="/path/to/movie.mkv"
AUDIO_FILE=""
SUBS_FILE="/path/to/subtitles.ass"

/usr/bin/ffprobe -hide_banner "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

SS="00:16:46.800"
TO="00:17:48.600"
AUDIO="1"; SUBS=""
# mkv, mp4, webm
CONT="webm"
# hevc, vp9, copy
CV="vp9"
CRF=30
# libopus, libfdk_aac, copy
CA="libopus"
BA="192K"
TITLE="Episode title"
VIDEO_LANG="jpn"
AUDIO_LANG="jpn"
SUBS_LANG="eng"
HARDSUB=false
SKIP_PASS_1=false
TEMP="/home/user/folder for temporary files and output"

# Preview
/usr/bin/mpv --start=$SS --end=$TO "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

${BASH_SOURCE%/*}/make_webm_next.sh "$FILE" "$AUDIO_FILE" "$SUBS_FILE" "$AUDIO" "$SUBS" "$SS" "$TO" "$CONT" "$CV" "$CRF" "$CA" "$BA" "$TITLE" "$VIDEO_LANG" "$AUDIO_LANG" "$SUBS_LANG" "$HARDSUB" "$SKIP_PASS_1" "$TEMP"
