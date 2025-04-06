#!/bin/bash

FFMPEG="/usr/bin/ffmpeg"

variables=(FILE AUDIO_FILE SUBS_FILE VIDEO_STREAM AUDIO_STREAM SUBS_STREAM SS TO CONT CV CRF ENCODING_SPEED PIX_FMT SCALE SPEED CA BA HARDSUB TITLE VIDEO_LANG AUDIO_LANG SUBS_LANG SUFFIX TEMP)
i=0
for arg; do
  declare "${variables[i++]}"="$arg"
done

NAME="${FILE##*/}" # remove all from beginning to last /
NAME=${NAME%.*}    # remove all from end to first  .
if [[ -n "$SS" ]]; then
  HOUR=${SS%%:*}
  if [[ "$HOUR" -eq 0 ]]; then START_TIME=${SS#*:}; else START_TIME="$SS"; fi
  NAME+=" [${START_TIME%.*}]"
fi
if [[ -n "$SUFFIX" ]]; then NAME+=" $SUFFIX"; fi
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
  date --utc --date "$1" +%s
}

dateDiff () {
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

if [[ -n "$SS" ]]; then SET_SS="-ss $SS"; else SS="00:00:00.000"; fi

if [[ -n "$TO" ]]; then
  TIMING="$(dateDiff)";
  #if [[ -n "$SPEED" ]]; then TIMING="$( scale=3 ; $TIMING / $SPEED | bc )"; fi
  if [[ -n "$SPEED" ]]; then TIMING="$( awk -v var1=$TIMING -v var2=$SPEED 'BEGIN { print  ( var1 / var2 ) }' )"; fi
  SET_T="-t $TIMING";
fi

joinVF () {
  if [[ -n "$VF" ]]; then VF+=","; else VF="-vf "; fi
  VF="${VF}$1"
}

burnSubs () {
  # To force font size of burned subtitles prepend :force_style='Fontsize=24'
  echo "subtitles='$1':stream_index=0"
}

if [[ -n "$VIDEO_STREAM" ]]; then
  MAP="-map 0:$VIDEO_STREAM";
  VIDEO_PARAMS="-c:v $CV "
  case $CV in
    libvpx-vp9)
      VIDEO_PARAMS+="-crf $CRF -b:v 0 -tile-columns 4 -row-mt 1 -frame-parallel 0 -auto-alt-ref 1 -lag-in-frames 25";;
    libx264)
      VIDEO_PARAMS+="-crf $CRF -preset $ENCODING_SPEED";;
    libx265)
      VIDEO_PARAMS+="-crf $CRF -preset $ENCODING_SPEED";;  # -x265-params qp=22:aq-mode=2
    h264_nvenc)
      VIDEO_PARAMS+="-cq $CRF -preset $ENCODING_SPEED";;
    hevc_nvenc)
      # https://github.com/HandBrake/HandBrake/issues/2231#issuecomment-520108626
      VIDEO_PARAMS+="-rc vbr -cq $CRF -qmin $CRF -qmax $CRF -b:v 0 -preset $ENCODING_SPEED";;
  esac
  if [[ -n "$SCALE" ]]; then joinVF "scale=$SCALE:flags=lanczos"; fi
  if [[ -n "$PIX_FMT" ]]; then joinVF "format=$PIX_FMT"; fi
  if [[ -n "$SPEED" ]]; then joinVF "setpts=PTS/$SPEED"; fi
fi

if [[ -n "$SPEED" ]] && { [[ -n "$AUDIO_STREAM" ]] || [[ -n "$AUDIO_FILE" ]]; }; then
  AF="-filter:a atempo=$SPEED"
fi

if [[ -n "$AUDIO_STREAM" ]]; then
  MAP+=" -map 0:$AUDIO_STREAM"
  AUDIO_PARAMS="-c:a $CA -b:a $BA -ac 2 $AF"
fi

if [[ -n "$AUDIO_FILE" ]]; then
  NEW_AUDIO="$TEMP/.cut.mka"
  $FFMPEG -i "$AUDIO_FILE" $SET_SS -c:a $CA -b:a $BA $AF -ac 2 $SET_T -hide_banner -y "$NEW_AUDIO"
  ADD_AUDIO="-i $NEW_AUDIO"
  MAP+=" -map 1:0"
  AUDIO_PARAMS="-c:a copy"
fi

case $CONT in
  webm) CS="webvtt";;
  mkv)  CS="ass";;
  mp4)  CS="mov_text";;
esac

if [[ -n "$SUBS_STREAM" ]]; then
  if [[ "$HARDSUB" = true ]]; then
    NEW_SUBS="$TEMP/.cut.ass"
    #$FFMPEG $SET_SS -i "$FILE" -map 0:$SUBS_STREAM -c ass $SET_T -hide_banner -y "$NEW_SUBS"
    joinVF $(burnSubs "$NEW_SUBS")
  else
    MAP+=" -map 0:$SUBS_STREAM"
    SUBS_PARAMS="-c:s $CS"
  fi
fi

if [[ -n "$SUBS_FILE" ]]; then
  NEW_SUBS="$TEMP/.cut.ass"
  $FFMPEG $SET_SS -i "$SUBS_FILE" -c ass $SET_T -hide_banner -y "$NEW_SUBS"
  if [[ "$HARDSUB" = true ]]; then
    joinVF $(burnSubs "$NEW_SUBS")
  else
    ADD_SUBS="-i $NEW_SUBS"
    if [[ -n "$AUDIO_FILE" ]]; then MAP+=" -map 2:0"; else MAP+=" -map 1:0"; fi
    SUBS_PARAMS="-c:s $CS"
  fi
fi

SECONDS=0

if [[ -n "$VIDEO_STREAM" ]] && [[ "$CV" = "libvpx-vp9" ]]; then
  $FFMPEG \
    -analyzeduration 2147483647 -probesize 2147483647 \
     $SET_SS \
    -i "$FILE" \
    -map 0:$VIDEO_STREAM \
    -pass 1 $VIDEO_PARAMS \
    -max_muxing_queue_size 1024 \
     $SET_T \
    -threads 12 -hide_banner -f webm -y /dev/null
  VIDEO_PARAMS="-pass 2 $VIDEO_PARAMS -cpu-used $ENCODING_SPEED"
fi

$FFMPEG \
  -analyzeduration 2147483647 -probesize 2147483647 \
   $SET_SS \
  -i "$FILE" \
   $ADD_AUDIO \
   $ADD_SUBS \
   $MAP \
   $VIDEO_PARAMS $VF \
   $AUDIO_PARAMS \
   $SUBS_PARAMS \
  -max_muxing_queue_size 1024 \
   $SET_T \
  -metadata title="$TITLE" \
  -metadata:s:v:0 language="$VIDEO_LANG" \
  -metadata:s:a:0 language="$AUDIO_LANG" \
  -metadata:s:s:0 language="$SUBS_LANG" \
  -map_metadata -1 -empty_hdlr_name 1 \
  -fflags +bitexact -flags:v +bitexact -flags:a +bitexact -flags:s +bitexact \
  -movflags +faststart \
  -threads 12 -hide_banner -y "$NEW_FILE"

SIZE=$(wc -c <"$NEW_FILE")
echo "$(($SIZE / 1024 ** 2)).$((($SIZE % (1024 ** 2)) / 100000)) MiB"

DURATION=$SECONDS
echo "$(($DURATION / 60)) min $(($DURATION % 60)) sec"

if [[ -n "$NEW_AUDIO" ]]; then rm "$NEW_AUDIO"; fi
#if [[ -n "$NEW_SUBS" ]]; then rm "$NEW_SUBS"; fi
