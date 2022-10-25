#!/bin/bash

variables=(FILE AUDIO_FILE SUBS_FILE AUDIO SUBS SS TO CONT CV CRF CA BA TITLE VIDEO_LANG AUDIO_LANG SUBS_LANG HARDSUB SKIP_PASS_1 TEMP)
c=0
for arg; do
  declare "${variables[c++]}"="$arg"
done

NAME="${FILE##*/}" # remove all from beginning to last /
NAME=${NAME%.*}    # remove all from end to first  .
HOUR=${SS%%:*}
if [ "$HOUR" -eq 0 ]; then SUFFIX=${SS#*:}; else SUFFIX="$SS"; fi
SUFFIX=[${SUFFIX%.*}]
#SUFFIX+=" [CRF $CRF]"
NEW_FILE="$TEMP/$NAME $SUFFIX.$CONT"

case $CV in
  vp9)  VIDEO_OPTION="-pass 2 -c:v libvpx-vp9 -crf $CRF -b:v 0 -cpu-used 2 -tile-columns 2 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25";;
  hevc) VIDEO_OPTION="-c:v libx265 -crf $CRF -preset medium -empty_hdlr_name 1";;
  x264) VIDEO_OPTION="-c:v libx264 -crf $CRF -preset medium -empty_hdlr_name 1";;
  copy) VIDEO_OPTION="-c:v copy";;
esac

case $CONT in
  webm) CS="webvtt";;
  mkv)  CS="ass";;
  mp4)  CS="mov_text";;
esac

addMilisec () {
  if [[ "$1" != *.* ]]; then
    echo 0
  else
    IFS='.' read -ra ARR <<< "$1"
    IFS=' '
    echo "$((10#${ARR[-1]}))"
  fi
}
date2stamp () {
  /bin/date --utc --date "$1" +%s
}
dateDiff (){
  if [ "$SS" = "start" ]; then SS="00:00:00.000"; fi
  dte1=$(date2stamp "$SS")
  dte2=$(date2stamp "$TO")
  diffSec=$((dte2-dte1))
  milisec1=$(addMilisec "$SS")
  milisec2=$(addMilisec "$TO")
  diffMil=$((milisec2-milisec1))
  if (( "$diffMil" < 0 )); then
    diffSec=$((diffSec-1))
    diffMil=$((10**(${#milisec1})+diffMil))
  fi
  echo "$diffSec.$diffMil"
}

if [ "$SS" != "start" ]; then SET_SS="-ss $SS"; fi

if [ "$TO" != "end" ]; then SET_T="-t $(dateDiff)"; fi

MAP="-map 0:0"

if [ -n "$AUDIO" ]; then
  MAP+=" -map 0:$AUDIO"
fi

if [ -n "$AUDIO_FILE" ]; then
  ADD_AUDIO="-i $AUDIO_FILE"
  MAP+=" -map 1:0"
fi

if [ -n "$SUBS" ]; then
  if [ "$HARDSUB" = true ]; then
    SUBS_OPTION="-vf subtitles='$FILE':stream_index='$SUBS'"
  else
    MAP+=" -map 0:$SUBS"
    SUBS_OPTION="-c:s $CS"
  fi
fi

if [ -n "$SUBS_FILE" ]; then
  SUBS_CONT="${SUBS_FILE##*.}"
  NEW_SUBS="$TEMP/.cut.$SUBS_CONT"
  /usr/bin/ffmpeg $SET_SS -i "$SUBS_FILE" -c $SUBS_CONT $SET_T -hide_banner -y "$NEW_SUBS"
  if [ "$HARDSUB" = true ]; then
    SUBS_OPTION="-vf subtitles='$NEW_SUBS':stream_index=0"
  else
    ADD_SUBS="-i $NEW_SUBS"
    if [ -n "$AUDIO_FILE" ]; then MAP+=" -map 2:0"; else MAP+=" -map 1:0"; fi
    SUBS_OPTION="-c:s $CS"
  fi
fi

SECONDS=0

if [[ "$CV" = "vp9" ]]&&[[ "$SKIP_PASS_1" = false ]]; then
  /usr/bin/ffmpeg \
    -analyzeduration 2147483647 -probesize 2147483647 \
     $SET_SS \
    -i "$FILE" \
    -map 0:0 \
    -pass 1 \
    -c:v libvpx-vp9 -crf "$CRF" -b:v 0 -cpu-used 4 \
    -max_muxing_queue_size 1024 \
    -tile-columns 2 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25 \
     $SET_T \
    -threads 4 -hide_banner -f webm -y /dev/null
fi

/usr/bin/ffmpeg \
  -analyzeduration 2147483647 -probesize 2147483647 \
   $SET_SS \
  -i "$FILE" \
   $ADD_AUDIO \
   $ADD_SUBS \
   $MAP \
   $VIDEO_OPTION \
  -c:a $CA -b:a $BA -ac 2 \
   $SUBS_OPTION \
  -max_muxing_queue_size 1024 \
   $SET_T \
  -metadata:s:v:0 language="$VIDEO_LANG" \
  -metadata:s:a:0 language="$AUDIO_LANG" \
  -metadata:s:s:0 language="$SUBS_LANG" \
  -metadata title="$TITLE" \
  -map_metadata -1 -map_chapters -1 \
  -movflags +faststart \
  -fflags +bitexact -flags:v +bitexact -flags:a +bitexact -flags:s +bitexact \
  -threads 4 -hide_banner -y "$NEW_FILE"

duration=$SECONDS
echo "$(($duration / 60)) min $(($duration % 60)) sec"

#if [ -n "$NEW_SUBS" ]; then /bin/rm "$NEW_SUBS"; fi
