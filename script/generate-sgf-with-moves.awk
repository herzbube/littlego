# Usage:
#   echo "<board-size>;<number-of-moves-to-generate>" | awk -f <this-script>
#
# Generates an .sgf file that contains the specified number of moves, played
# on a board with the specified board size.
#
# The generated moves fill the board with black stones, starting in the
# top-right corner and going from left-to-right, top-to-bottom. The only
# exception is the bottom-right corner where a white stone is played that
# captures the black stones that have been used to fill the board. The
# cycle then repeats. The resulting game is valid with simple ko rules, but
# is illegal with positional or situational superko rules.

BEGIN {
  FS=";"
  STDERR="/dev/stderr"
  coordinateLookup = "abcdefghijklmnopqrs"
  # With board size 1 the current implementation of the endless-repetition
  # algorithm does not work because it expects to be able to play at least
  # one black stone in the last row. The implementation could be made to
  # work with board size 1 as well, but it's not worth the effort.
  minimumBoardSize = 2
  maximumBoardSize = length(coordinateLookup)
}
{
  if (NF != 2)
  {
    print "Illegal number of fields" >STDERR
    print "Usage:" >STDERR
    print "  echo \"<board-size>;<number-of-moves-to-generate>\" | awk -f <this-script>" >STDERR
    exit 1
  }

  boardSize = $1 + 0
  numberOfMovesToGenerate = $2 + 0

  if (boardSize < minimumBoardSize || boardSize > maximumBoardSize)
  {
    print "Illegal board size: Must be between " minimumBoardSize " and " maximumBoardSize >STDERR
    exit 1
  }

  if (numberOfMovesToGenerate < 0)
  {
    print "Illegal number of moves to generate: Must be >0" >STDERR
    exit 1
  }

  print "(;FF[4]CA[UTF-8]GM[1]SZ[" boardSize "]C[This game contains " numberOfMovesToGenerate " moves.]"

  numberOfMovesGenerated = 0
  while (numberOfMovesGenerated < numberOfMovesToGenerate)
  {
    for (row = 1; row <= boardSize && numberOfMovesGenerated < numberOfMovesToGenerate; row++)
    {
      rowIsLastRow = (row == boardSize) ? 1 : 0

      coordinateY = substr(coordinateLookup, row, 1)

      for (column = 1; column <= boardSize && numberOfMovesGenerated < numberOfMovesToGenerate; column++)
      {
        columnIsLastColumn = (column == boardSize) ? 1 : 0
        columnIsSecondToLastColumn = ((column + 1) == boardSize) ? 1 : 0

        coordinateX = substr(coordinateLookup, column, 1)
        coordinate = coordinateX "" coordinateY

        if (rowIsLastRow && columnIsLastColumn)
        {
          print " ;W[" coordinate "]"  # captures the entire board full of black stones
          numberOfMovesGenerated++
        }
        else
        {
          print " ;B[" coordinate "]"
          numberOfMovesGenerated++

          if (numberOfMovesGenerated == numberOfMovesToGenerate)
          {
            break;
          }

          # White always passes in response to black's move, unless black has
          # filled the entire board except the intersection in the bottom-right
          # corner - in that case White does not pass, but waits for the next
          # iteration, where it will then play a stone.
          if (rowIsLastRow && columnIsSecondToLastColumn)
          {
            continue
          }

          print " ;W[]"
          numberOfMovesGenerated++
        }
      }
    }
  }

  print ")"
}
