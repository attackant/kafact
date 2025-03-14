#!/bin/bash

# KAFACT: Kick Ass Free Audio Cleanup Tool
# Version 1.1
# A local solution to process videos with audio enhancements
# Similar to cloud-based services like Auphonic but with offline processing
# Created by: Animal Taggart
# License: GPLv3

# Default locations
INPUT_DIR="$HOME/Videos/raw"
OUTPUT_DIR="$HOME/Videos/processed"
PRESET_FILE="$HOME/Videos/kafact/youtube_preset.conf"
SINGLE_FILE=""
LOG_FILE="$HOME/Videos/kafact_log.txt"
DRY_RUN=false

# Create a cleanup function for graceful exit
cleanup() {
    echo "Script interrupted. Cleaning up..."
    exit 1
}

# Set trap for graceful termination
trap cleanup SIGINT SIGTERM

# Function to display help
show_help() {
    echo "KAFACT: Kick Ass Free Audio Cleanup Tool (v1.1)"
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -i, --input DIR      Input directory (default: ~/Videos/raw)"
    echo "  -o, --output DIR     Output directory (default: ~/Videos/processed)"
    echo "  -p, --preset FILE    Preset configuration file (default: ~/Videos/youtube_preset.conf)"
    echo "  -s, --single FILE    Process a single file instead of a directory"
    echo "  -d, --dry-run        Show commands without executing them"
    echo "  -l, --log FILE       Log file location (default: ~/Videos/kafact_log.txt)"
    echo "  -v, --verbose        Show detailed processing information"
    echo "  -f, --force          Force overwrite of existing files"
    echo "  -h, --help           Show this help message"
    exit 0
}

# Function to log messages
log() {
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    local message="$timestamp - $1"
    echo "$message"
    echo "$message" >> "$LOG_FILE"
}

# Function to check if FFmpeg is installed
check_ffmpeg() {
    if ! command -v ffmpeg > /dev/null 2>&1; then
        echo "Error: FFmpeg is not installed. Please install FFmpeg before running KAFACT."
        echo "  macOS: brew install ffmpeg"
        echo "  Ubuntu/Debian: sudo apt-get install ffmpeg"
        exit 1
    fi
}

# Function to process a single video
process_video() {
    local video="$1"
    local base_filename=$(basename "$video" .mp4)
    local output_filename="${OUTPUT_BASENAME}_${current_date}.mp4"
    local output_path="$OUTPUT_DIR/$output_filename"
    
    if [[ -f "$output_path" && "$FORCE_OVERWRITE" != "true" ]]; then
        log "Skipping $video (output file already exists)"
        return 0
    fi
    
    log "Processing $video to $output_path..."

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
    FFMPEG_CMD="ffmpeg -y -i \"$video\""
    
    # Add quieter output unless verbose
    if [[ "$VERBOSE" != "true" ]]; then
        FFMPEG_CMD="$FFMPEG_CMD -hide_banner -loglevel warning"
    fi
    
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
    FFMPEG_CMD="$FFMPEG_CMD \"$output_path\""
    
    # Execute the command or show dry run
    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: $FFMPEG_CMD"
    else
        log "Executing ffmpeg command..."
        eval $FFMPEG_CMD
        log "Completed processing: $video"
    fi
}

# Initialize variables
VERBOSE=false
FORCE_OVERWRITE=false

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
    -s|--single)
      SINGLE_FILE="$2"
      shift 2
      ;;
    -d|--dry-run)
      DRY_RUN=true
      shift
      ;;
    -l|--log)
      LOG_FILE="$2"
      shift 2
      ;;
    -v|--verbose)
      VERBOSE=true
      shift
      ;;
    -f|--force)
      FORCE_OVERWRITE=true
      shift
      ;;
    -h|--help)
      show_help
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use -h or --help for usage information"
      exit 1
      ;;
  esac
done

# Check dependencies
check_ffmpeg

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"
touch "$LOG_FILE"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Load preset file
if [[ ! -f "$PRESET_FILE" ]]; then
  log "Error: Preset file not found: $PRESET_FILE"
  exit 1
fi

source "$PRESET_FILE"

# Get current date in YYYY-MM-DD format
current_date=$(date +"%Y-%m-%d")

# Log the start time
log "Starting KAFACT processing job with preset: $PRESET_FILE"

# Process single file or directory
if [[ -n "$SINGLE_FILE" ]]; then
    if [[ ! -f "$SINGLE_FILE" ]]; then
        log "Error: File not found: $SINGLE_FILE"
        exit 1
    fi
    process_video "$SINGLE_FILE"
else
    # Process all MP4 files in the input directory
    file_count=0
    for video in "$INPUT_DIR"/*.mp4; do
        # Check if the file exists and is not a wildcard
        if [[ ! -f "$video" ]]; then
            log "No MP4 files found in $INPUT_DIR"
            exit 0
        fi
        
        file_count=$((file_count + 1))
        process_video "$video"
    done
    
    log "Processed $file_count MP4 files"
fi

# Log the end time
log "Processing complete! All tasks finished successfully."
