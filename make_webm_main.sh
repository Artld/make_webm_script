#!/bin/bash

FILE="/path/to/movie.mkv"
SUBS="/path/to/subtitles.ass"
AUDIO=""

/usr/bin/ffprobe -hide_banner "$FILE"
read -p "Any key to continue or Ctrl+C to exit..." -n1 -s

SS="00:16:46.800"
TO="00:17:48.600"
MAP="-map 0:0 -map 0:1"
# mkv, mp4, webm
EXT="webm"
# hevc, vp9
CV="vp9"
CRF=30
# libopus, libfdk-aac, copy
CA="copy"
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

${BASH_SOURCE%/*}/make_webm_next.sh "$FILE" "$SUBS" "$AUDIO" "$SS" "$TO" "$MAP" "$EXT" "$CV" "$CRF" "$CA" "$BA" "$TITLE" "$VIDEO_LANG" "$AUDIO_LANG" "$SUBS_LANG" "$HARDSUB" "$SKIP_PASS_1" "$TEMP"
