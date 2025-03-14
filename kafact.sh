#!/bin/bash

# KAFACT: Kick Ass Free Audio Cleanup Tool

# A local solution to process videos with audio enhancements
# Similar to cloud-based services like Auphonic but with offline processing
# Created by: Animal Taggart
# License: GPLv3

# Default locations
INPUT_DIR="$HOME/Videos/raw"
OUTPUT_DIR="$HOME/Videos/processed"
PRESET_FILE="$HOME/Videos/youtube_preset.conf"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input)
      INPUT_DIR="$2"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -p|--preset)
      PRESET_FILE="$2"
      shift 2
      ;;
    -h|--help)
      echo "Usage: $0 [options]"
      echo "Options:"
      echo "  -i, --input DIR    Input directory (default: ~/Videos/raw)"
      echo "  -o, --output DIR   Output directory (default: ~/Videos/processed)"
      echo "  -p, --preset FILE  Preset configuration file (default: ~/Videos/youtube_preset.conf)"
      echo "  -h, --help         Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Load preset file
if [[ ! -f "$PRESET_FILE" ]]; then
  echo "Error: Preset file not found: $PRESET_FILE"
  exit 1
fi

source "$PRESET_FILE"

# Get current date in YYYY-MM-DD format
current_date=$(date +"%Y-%m-%d")

# Process each video file
for video in "$INPUT_DIR"/*.mp4; do
  # Check if there are actually any files
  if [[ ! -f "$video" ]]; then
    echo "No MP4 files found in $INPUT_DIR"
    exit 1
  fi
  
  base_filename=$(basename "$video" .mp4)
  output_filename="${OUTPUT_BASENAME}_${current_date}.mp4"
  
  echo "Processing $video to $OUTPUT_DIR/$output_filename..."

  # Build the audio filter chain
  AUDIO_FILTERS=""
  
  # Add noise reduction if enabled
  if [[ -n "$NOISE_REDUCTION" && "$NOISE_REDUCTION" -gt 0 ]]; then
    AUDIO_FILTERS="afftdn=nr=$NOISE_REDUCTION:nf=$NOISE_FLOOR"
  fi
  
  # Add frequency filters
  if [[ -n "$HIGH_PASS" ]]; then
    if [[ -n "$AUDIO_FILTERS" ]]; then AUDIO_FILTERS="$AUDIO_FILTERS,"; fi
    AUDIO_FILTERS="${AUDIO_FILTERS}highpass=f=$HIGH_PASS"
  fi
  
  if [[ -n "$LOW_PASS" ]]; then
    if [[ -n "$AUDIO_FILTERS" ]]; then AUDIO_FILTERS="$AUDIO_FILTERS,"; fi
    AUDIO_FILTERS="${AUDIO_FILTERS}lowpass=f=$LOW_PASS"
  fi
  
  # Add compressor
  if [[ -n "$COMPRESSOR_ATTACK" ]]; then
    if [[ -n "$AUDIO_FILTERS" ]]; then AUDIO_FILTERS="$AUDIO_FILTERS,"; fi
    AUDIO_FILTERS="${AUDIO_FILTERS}compand=attacks=$COMPRESSOR_ATTACK:decays=$COMPRESSOR_DECAY:points=$COMPRESSOR_POINTS:gain=$COMPRESSOR_GAIN"
  fi
  
  # Add silence removal if enabled
  if [[ "$SILENCE_REMOVE" == "true" ]]; then
    if [[ -n "$AUDIO_FILTERS" ]]; then AUDIO_FILTERS="$AUDIO_FILTERS,"; fi
    AUDIO_FILTERS="${AUDIO_FILTERS}silenceremove=start_periods=1:start_silence=$SILENCE_DURATION:start_threshold=${SILENCE_THRESHOLD}dB:detection=peak"
  fi
  
  # Add loudness normalization
  if [[ -n "$LOUDNESS_TARGET" ]]; then
    if [[ -n "$AUDIO_FILTERS" ]]; then AUDIO_FILTERS="$AUDIO_FILTERS,"; fi
    AUDIO_FILTERS="${AUDIO_FILTERS}loudnorm=I=$LOUDNESS_TARGET:TP=$LOUDNESS_TP:LRA=$LOUDNESS_LRA"
  fi
  
  # Build the video filter
  VIDEO_FILTERS=""
  if [[ "$RESIZE_VIDEO" == "true" ]]; then
    VIDEO_FILTERS="scale=-1:$TARGET_RESOLUTION"
  fi
  
  # Build the ffmpeg command
  FFMPEG_CMD="ffmpeg -i \"$video\""
  
  # Add video filter if any
  if [[ -n "$VIDEO_FILTERS" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -vf \"$VIDEO_FILTERS\""
  fi
  
  # Add audio filter if any
  if [[ -n "$AUDIO_FILTERS" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -af \"$AUDIO_FILTERS\""
  fi
  
  # Add metadata
  if [[ -n "$META_TITLE" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -metadata title=\"$META_TITLE\""
  fi
  
  if [[ -n "$META_ARTIST" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -metadata artist=\"$META_ARTIST\""
  fi
  
  if [[ -n "$META_ALBUM" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -metadata album=\"$META_ALBUM\""
  fi
  
  if [[ -n "$META_DESCRIPTION" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -metadata description=\"$META_DESCRIPTION\""
  fi
  
  if [[ -n "$META_COMMENT" ]]; then
    FFMPEG_CMD="$FFMPEG_CMD -metadata comment=\"$META_COMMENT\""
  fi
  
  # Add video codec settings
  FFMPEG_CMD="$FFMPEG_CMD -c:v libx264 -crf $VIDEO_QUALITY -preset $VIDEO_PRESET"
  
  # Add audio codec settings
  FFMPEG_CMD="$FFMPEG_CMD -c:a aac -b:a ${AUDIO_BITRATE}k"
  
  # Add output file
  FFMPEG_CMD="$FFMPEG_CMD \"$OUTPUT_DIR/$output_filename\""
  
  # Execute the command
  eval $FFMPEG_CMD
done

echo "Processing complete!"
