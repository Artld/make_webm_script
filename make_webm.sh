#!/bin/bash

variables=(FILE AUDIO_FILE SUBS_FILE VIDEO AUDIO SUBS SS TO CONT SCALE PIX_FMT CV CRF ENCODE_SPEED CA BA TITLE VIDEO_LANG AUDIO_LANG SUBS_LANG HARDSUB TEMP)
i=0
for arg; do
  declare "${variables[i++]}"="$arg"
done

NAME="${FILE##*/}" # remove all from beginning to last /
NAME=${NAME%.*}    # remove all from end to first  .
if [ -n "$SS" ]; then
  HOUR=${SS%%:*}
  if [ "$HOUR" -eq 0 ]; then SUFFIX=${SS#*:}; else SUFFIX="$SS"; fi
  NAME+=" [${SUFFIX%.*}]"
fi
NEW_FILE="$TEMP/$NAME.$CONT"

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

if [ -n "$SS" ]; then SET_SS="-ss $SS"; else SS="00:00:00.000"; fi

if [ -n "$TO" ]; then SET_T="-t $(dateDiff)"; fi

joinVF () {
  if [ -n "$VF" ]; then VF+=","; else VF="-vf "; fi
  VF="${VF}$1"
}

filterSubs () {
  echo "subtitles='$1':stream_index=0"
}

if [ -n "$VIDEO" ]; then
  MAP="-map 0:$VIDEO";
  case $CV in
    vp9)  VIDEO_OPTION="-c:v libvpx-vp9 -crf $CRF -b:v 0 -tile-columns 2 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25";;
    x26*) PRESETS=("veryslow" "slower" "slow" "medium" "fast" "faster" "veryfast" "superfast" "ultrafast")
          VIDEO_OPTION="-c:v lib$CV -crf $CRF -preset ${PRESETS[$ENCODE_SPEED]} -empty_hdlr_name 1";;
    copy) VIDEO_OPTION="-c:v copy";;
  esac
  if [ -n "$SCALE" ]; then joinVF "scale=$SCALE:flags=lanczos"; fi
  if [ -n "$PIX_FMT" ]; then joinVF "format=$PIX_FMT"; fi
fi

if [ -n "$AUDIO" ]; then
  AUDIO_OPTION="-c:a $CA -b:a $BA -ac 2"
  MAP+=" -map 0:$AUDIO"
fi

if [ -n "$AUDIO_FILE" ]; then
  NEW_AUDIO="$TEMP/.cut.mka"
  /usr/bin/ffmpeg -i "$AUDIO_FILE" $SET_SS -c:a $CA -b:a $BA -ac 2 $SET_T -hide_banner -y "$NEW_AUDIO"
  ADD_AUDIO="-i $NEW_AUDIO"
  MAP+=" -map 1:0"
fi

case $CONT in
  webm) CS="webvtt";;
  mkv)  CS="ass";;
  mp4)  CS="mov_text";;
esac

if [ -n "$SUBS" ]; then
  if [ "$HARDSUB" = true ]; then
    NEW_SUBS="$TEMP/.cut.ass"
    /usr/bin/ffmpeg $SET_SS -i "$FILE" -map 0:$SUBS -c ass $SET_T -hide_banner -y "$NEW_SUBS"
    joinVF $(filterSubs "$NEW_SUBS")
  else
    SUBS_OPTION="-c:s $CS"
    MAP+=" -map 0:$SUBS"
  fi
fi

if [ -n "$SUBS_FILE" ]; then
  SUBS_CONT="${SUBS_FILE##*.}"
  NEW_SUBS="$TEMP/.cut.$SUBS_CONT"
  /usr/bin/ffmpeg $SET_SS -i "$SUBS_FILE" -c $SUBS_CONT $SET_T -hide_banner -y "$NEW_SUBS"
  if [ "$HARDSUB" = true ]; then
    joinVF $(filterSubs "$NEW_SUBS")
  else
    SUBS_OPTION="-c:s $CS"
    ADD_SUBS="-i $NEW_SUBS"
    if [ -n "$AUDIO_FILE" ]; then MAP+=" -map 2:0"; else MAP+=" -map 1:0"; fi
  fi
fi

SECONDS=0

if [ -n "$VIDEO" ] && [ "$CV" = "vp9" ]; then
  #ENCODE_SPEED_1=5
  ENCODE_SPEED_1=$(($ENCODE_SPEED/2+4))
  /usr/bin/ffmpeg \
    -analyzeduration 2147483647 -probesize 2147483647 \
     $SET_SS \
    -i "$FILE" \
    -map 0:0 \
    -pass 1 $VIDEO_OPTION -cpu-used $ENCODE_SPEED_1 \
    -max_muxing_queue_size 1024 \
     $SET_T \
    -threads 4 -hide_banner -f webm -y /dev/null
  VIDEO_OPTION="-pass 2 $VIDEO_OPTION -cpu-used $ENCODE_SPEED"
fi

/usr/bin/ffmpeg \
  -analyzeduration 2147483647 -probesize 2147483647 \
   $SET_SS \
  -i "$FILE" \
   $ADD_AUDIO \
   $ADD_SUBS \
   $MAP \
   $VIDEO_OPTION \
   $VF \
   $AUDIO_OPTION \
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

SIZE=$(/bin/wc -c <"$NEW_FILE")
echo "$(($SIZE / 1024 ** 2)).$((($SIZE % (1024 ** 2)) / 100000)) MiB"

duration=$SECONDS
echo "$(($duration / 60)) min $(($duration % 60)) sec"

if [ -n "$NEW_AUDIO" ]; then /bin/rm "$NEW_AUDIO"; fi
if [ -n "$NEW_SUBS" ]; then /bin/rm "$NEW_SUBS"; fi
