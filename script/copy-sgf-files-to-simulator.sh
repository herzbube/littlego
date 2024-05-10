#!/usr/bin/env bash

# =========================================================================
# Copies predefined sets of SGF files to a given simulator folder.
# =========================================================================

# Basic information about this script
SCRIPT_NAME="$(basename $0)"
SCRIPT_DIR="$(pwd)/$(dirname $0)"
SGF_DIR="$SCRIPT_DIR/../sgf"
USAGE_LINE="$SCRIPT_NAME -h | -app-store-files | --dev-testing-files <path>"

if test $# -eq 0; then
  echo "Insufficient number of arguments"
  echo "$USAGE_LINE"
  exit 1
fi
if test $# -eq 1; then
  if test "$1" = "-h" -o "$1" = "--help"; then
    echo "$USAGE_LINE"
    exit 0
  else
    echo "Insufficient number of arguments"
    echo "$USAGE_LINE"
    exit 1
  fi
fi
if test $# -gt 2; then
  echo "Too many arguments"
  echo "$USAGE_LINE"
  exit 1
fi

unset SGF_FILES
case "$1" in
  --app-store-files)
    SGF_FILES=("9x9/9x9_1.sgf" "9x9/9x9_2.sgf" "9x9/Anonymous vs. Fuego 1.sgf" "9x9/game_050.sgf" "Famous games/Blood-vomiting game.sgf" "Famous games/Ear-reddening game.sgf" "Famous games/Lee's Broken Ladder Game.sgf" "19x19/Fuego vs. Fuego.sgf")
    ;;
  --dev-testing-files)
    SGF_FILES=("7x7/play-b-b7-for-superko.sgf" "9x9/annotations.sgf" "9x9/gameinfo.sgf" "9x9/illegal-board-setup-test.sgf" "9x9/node-tree-view.sgf" "9x9/non-alternating-play.sgf" "9x9/setup-variations.sgf" "19x19/markup.sgf" "19x19/maximum-number-of-moves.sgf" "Famous games/Blood-vomiting game.sgf" "Famous games/Ear-reddening game.sgf" "Famous games/Lee's Broken Ladder Game.sgf" "19x19/Fuego vs. Fuego.sgf" "Illegal games/encoding-detection-fails.sgf" "Illegal games/encoding-multiple.sgf" "Illegal games/encoding-unsupported.sgf" "Illegal games/illegal-move.sgf" "Illegal games/illegal-setup.sgf" "Illegal games/not-an-sgf-file.sgf" "Illegal games/not-enough-handicap-stones.sgf" "Illegal games/positional-superko.sgf" "Illegal games/setup-after-first-move.sgf" "Illegal games/setup-before-handicap-setup.sgf" "Illegal games/setup-player-after-first-move.sgf" "Illegal games/situational-superko.sgf" "Illegal games/suicide.sgf" "Illegal games/too-many-moves.sgf")
    ;;
  *)
    echo "Unknown argument"
    echo "$USAGE_LINE"
    exit 1
esac
DESTINATION_PATH="$2"

if test ! -d "$DESTINATION_PATH"; then
  echo "Destination path does not exist: $DESTINATION_PATH"
  exit 1
fi


for SGF_FILE in "${SGF_FILES[@]}"; do
  if test ! -f "$SGF_DIR/$SGF_FILE"; then
    echo "Source file not found, skipping: $SGF_FILE"
    continue
  fi

  echo "Copying $SGF_FILE"
  cp "$SGF_DIR/$SGF_FILE" "$DESTINATION_PATH"
done
