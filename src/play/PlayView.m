// -----------------------------------------------------------------------------
// Copyright 2011 Patrick Näf (herzbube@herzbube.ch)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
// -----------------------------------------------------------------------------


// Project includes
#import "PlayView.h"
#import "PlayViewModel.h"
#import "../ApplicationDelegate.h"
#import "../go/GoGame.h"
#import "../go/GoBoard.h"
#import "../go/GoMove.h"
#import "../go/GoPlayer.h"
#import "../go/GoPoint.h"
#import "../go/GoScore.h"
#import "../go/GoVertex.h"
#import "../player/Player.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for PlayView.
// -----------------------------------------------------------------------------
@interface PlayView()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UINibLoadingAdditions category
//@{
- (void) awakeFromNib;
//@}
/// @name UIView methods
//@{
- (void) drawRect:(CGRect)rect;
//@}
/// @name Layer drawing and other GUI updating
//@{
- (void) drawBackground:(CGRect)rect;
- (void) drawBoard;
- (void) drawGrid;
- (void) drawStarPoints;
- (void) drawStones;
- (void) drawStone:(UIColor*)color point:(GoPoint*)point;
- (void) drawStone:(UIColor*)color vertex:(GoVertex*)vertex;
- (void) drawStone:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY;
- (void) drawStone:(UIColor*)color coordinates:(CGPoint)coordinates;
- (void) drawEmpty:(GoPoint*)point;
- (void) drawSymbols;
- (void) drawLabels;
- (void) drawTerritory;
- (void) drawDeadStones;
- (void) updateStatusLine;
- (void) updateActivityIndicator;
//@}
/// @name Calculators
//@{
- (CGPoint) coordinatesFromPoint:(GoPoint*)point;
- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex;
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY;
- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates;
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates;
//@}
/// @name Notification responders
//@{
- (void) goGameNewCreated:(NSNotification*)notification;
- (void) goGameStateChanged:(NSNotification*)notification;
- (void) goGameFirstMoveChanged:(NSNotification*)notification;
- (void) goGameLastMoveChanged:(NSNotification*)notification;
- (void) computerPlayerThinkingChanged:(NSNotification*)notification;
- (void) goScoreScoringModeDisabled:(NSNotification*)notification;
- (void) goScoreCalculationStarts:(NSNotification*)notification;
- (void) goScoreCalculationEnds:(NSNotification*)notification;
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context;
//@}
/// @name Private helpers
//@{
- (void) updateDrawParametersForRect:(CGRect)rect;
- (void) delayedUpdate;
//@}
@end


@implementation PlayView

@synthesize statusLine;
@synthesize activityIndicator;

@synthesize model;

@synthesize previousDrawRect;
@synthesize previousBoardDimension;
@synthesize portrait;
@synthesize boardSize;
@synthesize boardOuterMargin;
@synthesize boardInnerMargin;
@synthesize topLeftBoardCornerX;
@synthesize topLeftBoardCornerY;
@synthesize topLeftPointX;
@synthesize topLeftPointY;
@synthesize pointDistance;
@synthesize lineLength;
@synthesize stoneRadius;

@synthesize crossHairPoint;
@synthesize crossHairPointIsLegalMove;

@synthesize actionsInProgress;
@synthesize updatesWereDelayed;


// -----------------------------------------------------------------------------
/// @brief Shared instance of PlayView.
// -----------------------------------------------------------------------------
static PlayView* sharedPlayView = nil;

// -----------------------------------------------------------------------------
/// @brief Returns the shared PlayView object.
// -----------------------------------------------------------------------------
+ (PlayView*) sharedView
{
  @synchronized(self)
  {
    assert(sharedPlayView != nil);
    return sharedPlayView;
  }
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this PlayView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [[NSNotificationCenter defaultCenter] removeObserver:self];
  [self.model removeObserver:self forKeyPath:@"markLastMove"];
  [self.model removeObserver:self forKeyPath:@"displayCoordinates;"];
  [self.model removeObserver:self forKeyPath:@"displayMoveNumbers"];
  self.statusLine = nil;
  self.activityIndicator = nil;
  self.model = nil;
  self.crossHairPoint = nil;
  if (self == sharedPlayView)
    sharedPlayView = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is called after an PlayView object has been allocated and initialized
/// from PlayView.xib
///
/// @note This is a method from the UINibLoadingAdditions category (an addition
/// to NSObject, defined in UINibLoading.h). Although it has the same purpose,
/// the implementation via category is different from the NSNibAwaking informal
/// protocol on the Mac OS X platform.
// -----------------------------------------------------------------------------
- (void) awakeFromNib
{
  [super awakeFromNib];

  sharedPlayView = self;
  self.model = [ApplicationDelegate sharedDelegate].playViewModel;

  self.previousDrawRect = CGRectNull;
  self.previousBoardDimension = 0;
  self.portrait = true;
  self.boardSize = 0;
  self.boardOuterMargin = 0;
  self.boardInnerMargin = 0;
  self.topLeftBoardCornerX = 0;
  self.topLeftBoardCornerY = 0;
  self.topLeftPointX = 0;
  self.topLeftPointY = 0;
  self.pointDistance = 0;
  self.lineLength = 0;

  self.crossHairPoint = nil;
  self.crossHairPointIsLegalMove = true;

  self.actionsInProgress = 0;
  self.updatesWereDelayed = false;

  NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
  [center addObserver:self selector:@selector(goGameNewCreated:) name:goGameNewCreated object:nil];
  [center addObserver:self selector:@selector(goGameStateChanged:) name:goGameStateChanged object:nil];
  [center addObserver:self selector:@selector(goGameFirstMoveChanged:) name:goGameFirstMoveChanged object:nil];
  [center addObserver:self selector:@selector(goGameLastMoveChanged:) name:goGameLastMoveChanged object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStarts object:nil];
  [center addObserver:self selector:@selector(computerPlayerThinkingChanged:) name:computerPlayerThinkingStops object:nil];
  [center addObserver:self selector:@selector(goScoreScoringModeDisabled:) name:goScoreScoringModeDisabled object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationStarts:) name:goScoreCalculationStarts object:nil];
  [center addObserver:self selector:@selector(goScoreCalculationEnds:) name:goScoreCalculationEnds object:nil];
  // KVO observing
  [self.model addObserver:self forKeyPath:@"markLastMove" options:0 context:NULL];
  [self.model addObserver:self forKeyPath:@"displayCoordinates;" options:0 context:NULL];
  [self.model addObserver:self forKeyPath:@"displayMoveNumbers" options:0 context:NULL];
}

// -----------------------------------------------------------------------------
/// @brief Increases @e actionsInProgress by 1.
// -----------------------------------------------------------------------------
- (void) actionStarts
{
  self.actionsInProgress++;
}

// -----------------------------------------------------------------------------
/// @brief Decreases @e actionsInProgress by 1. Triggers a view update if
/// @e actionsInProgress becomes 0 and @e updatesWereDelayed is true.
// -----------------------------------------------------------------------------
- (void) actionEnds
{
  self.actionsInProgress--;
  if (0 == self.actionsInProgress)
  {
    if (self.updatesWereDelayed)
      [self setNeedsDisplay];
  }
}

// -----------------------------------------------------------------------------
/// @brief Internal helper that correctly handles delayed updates. PlayView
/// methods that need a view update should invoke this helper instead of
/// setNeedsDisplay().
///
/// If @e actionsInProgress is 0, this helper invokes setNeedsDisplay(), thus
/// triggering the update in UIKit.
///
/// If @e actionsInProgress is >0, this helper sets @e updatesWereDelayed to
/// true.
// -----------------------------------------------------------------------------
- (void) delayedUpdate
{
  if (self.actionsInProgress > 0)
    self.updatesWereDelayed = true;
  else
    [self setNeedsDisplay];
}

// -----------------------------------------------------------------------------
/// @brief Is invoked by UIKit when the view needs updating.
// -----------------------------------------------------------------------------
- (void) drawRect:(CGRect)rect
{
  // Guard against
  // - updates triggered by UIKit
  // - updates that were triggered by delayedUpdate() before actionsInProgress
  //   was increased
  if (self.actionsInProgress > 0)
  {
    self.updatesWereDelayed = true;
    return;
  }
  // No game -> no board -> no drawing. This situation exists right after the
  // application has lanuched and the initial game is created only after a
  // small delay.
  if (! [GoGame sharedGame])
    return;

//  DDLogInfo(@"PlayView::drawRect:() starts");
  [self updateDrawParametersForRect:rect];
  // The order in which draw methods are invoked is important, as each method
  // draws its objects as a new layer on top of the previous layers.
  [self drawBackground:rect];
  [self drawBoard];
  [self drawGrid];
  [self drawStarPoints];
  [self drawStones];
  [self drawSymbols];
  [self drawLabels];
  if (self.model.scoringMode)
  {
    [self drawTerritory];
    [self drawDeadStones];
  }

  // TODO Strictly speaking this updater should not be invoked as part of
  // drawRect:(), afer all the status line is located outside of the game board
  // rectangle. If the updater is removed here, fix the status line update for
  // when the computer player has passed.
  [self updateStatusLine];
//  DDLogInfo(@"PlayView::drawRect:() ends");
}

// -----------------------------------------------------------------------------
/// @brief Updates properties that can be dynamically calculated. @a rect is
/// assumed to refer to the entire view rectangle.
// -----------------------------------------------------------------------------
- (void) updateDrawParametersForRect:(CGRect)rect
{
  // No need to update if the new rect is the same as the one we did our
  // previous calculations with *AND* the board dimensions did not change
  int currentBoardDimension = [GoGame sharedGame].board.dimensions;
  if (CGRectEqualToRect(self.previousDrawRect, rect) && self.previousBoardDimension == currentBoardDimension)
    return;
  self.previousDrawRect = rect;
  self.previousBoardDimension = currentBoardDimension;

  // The view rect is rectangular, but the Go board is square. Examine the view
  // rect orientation and use the smaller dimension of the rect as the base for
  // the Go board's dimension.
  self.portrait = rect.size.height >= rect.size.width;
  int boardSizeBase = 0;
  if (self.portrait)
    boardSizeBase = rect.size.width;
  else
    boardSizeBase = rect.size.height;
  self.boardOuterMargin = floor(boardSizeBase * self.model.boardOuterMarginPercentage);
  self.boardSize = boardSizeBase - (self.boardOuterMargin * 2);
  self.boardInnerMargin = floor(self.boardSize * self.model.boardInnerMarginPercentage);
  // Don't use border here - rounding errors might cause improper centering
  self.topLeftBoardCornerX = floor((rect.size.width - self.boardSize) / 2);
  self.topLeftBoardCornerY = floor((rect.size.height - self.boardSize) / 2);
  // This is only an approximation - because fractions are lost by the
  // subsequent point distance calculation, the final line length calculation
  // must be based on the point distance
  int lineLengthApproximation = self.boardSize - (self.boardInnerMargin * 2);
  self.pointDistance = floor(lineLengthApproximation / ([GoGame sharedGame].board.dimensions - 1));
  self.lineLength = self.pointDistance * (currentBoardDimension - 1);
  // Don't use padding here, rounding errors mighth cause improper positioning
  self.topLeftPointX = self.topLeftBoardCornerX + (self.boardSize - self.lineLength) / 2;
  self.topLeftPointY = self.topLeftBoardCornerY + (self.boardSize - self.lineLength) / 2;

  self.stoneRadius = floor(self.pointDistance / 2 * self.model.stoneRadiusPercentage);
}

// -----------------------------------------------------------------------------
/// @brief Draws the view background layer.
// -----------------------------------------------------------------------------
- (void) drawBackground:(CGRect)rect
{
  // Currently we don't draw the background, the table view background set in
  // the .xib looks nice enough. If this should ever become configurable, note
  // that the table view background is a pattern and not an RGB color, i.e. it
  // can't be converted to a hex string for storage in the user defaults.
  // Convenience constructor: [UIColor groupTableViewBackgroundColor].

//  CGContextRef context = UIGraphicsGetCurrentContext();
//  CGContextSetFillColorWithColor(context, self.model.backgroundColor.CGColor);
//  CGContextFillRect(context, rect);
}

// -----------------------------------------------------------------------------
/// @brief Draws the Go board background layer.
// -----------------------------------------------------------------------------
- (void) drawBoard
{
  CGContextRef context = UIGraphicsGetCurrentContext();
  CGContextSetFillColorWithColor(context, self.model.boardColor.CGColor);
  CGContextFillRect(context, CGRectMake(self.topLeftBoardCornerX + gHalfPixel,
                                        self.topLeftBoardCornerY + gHalfPixel,
                                        self.boardSize, self.boardSize));
}

// -----------------------------------------------------------------------------
/// @brief Draws the grid layer.
// -----------------------------------------------------------------------------
- (void) drawGrid
{
  CGContextRef context = UIGraphicsGetCurrentContext();

  CGPoint crossHairCenter = CGPointZero;
  if (self.crossHairPoint)
    crossHairCenter = [self coordinatesFromPoint:self.crossHairPoint];


  // Two iterations for the two directions horizontal and vertical
  for (int lineDirection = 0; lineDirection < 2; ++lineDirection)
  {
    int lineStartPointX = self.topLeftPointX;
    int lineStartPointY = self.topLeftPointY;
    bool drawHorizontalLine = (0 == lineDirection) ? true : false;
    for (int lineCounter = 0; lineCounter < [GoGame sharedGame].board.dimensions; ++lineCounter)
    {
      CGContextBeginPath(context);
      CGContextMoveToPoint(context, lineStartPointX + gHalfPixel, lineStartPointY + gHalfPixel);
      if (drawHorizontalLine)
      {
        CGContextAddLineToPoint(context, lineStartPointX + lineLength + gHalfPixel, lineStartPointY + gHalfPixel);
        if (lineStartPointY == crossHairCenter.y)
          CGContextSetStrokeColorWithColor(context, self.model.crossHairColor.CGColor);
        else
          CGContextSetStrokeColorWithColor(context, self.model.lineColor.CGColor);
        lineStartPointY += self.pointDistance;  // calculate for next iteration
      }
      else
      {
        CGContextAddLineToPoint(context, lineStartPointX + gHalfPixel, lineStartPointY + lineLength + gHalfPixel);
        if (lineStartPointX == crossHairCenter.x)
          CGContextSetStrokeColorWithColor(context, self.model.crossHairColor.CGColor);
        else
          CGContextSetStrokeColorWithColor(context, self.model.lineColor.CGColor);
        lineStartPointX += self.pointDistance;  // calculate for next iteration
      }
      if (0 == lineCounter || ([GoGame sharedGame].board.dimensions - 1) == lineCounter)
        CGContextSetLineWidth(context, self.model.boundingLineWidth);
      else
        CGContextSetLineWidth(context, self.model.normalLineWidth);

      CGContextStrokePath(context);
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws the star points layer.
// -----------------------------------------------------------------------------
- (void) drawStarPoints
{
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, self.model.starPointColor.CGColor);

  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  for (GoPoint* starPoint in [GoGame sharedGame].board.starPoints)
  {
    struct GoVertexNumeric numericVertex = starPoint.vertex.numeric;
    int starPointCenterPointX = self.topLeftPointX + (self.pointDistance * (numericVertex.x - 1));
    int starPointCenterPointY = self.topLeftPointY + (self.pointDistance * (numericVertex.y - 1));
    CGContextAddArc(context, starPointCenterPointX + gHalfPixel, starPointCenterPointY + gHalfPixel, self.model.starPointRadius, startRadius, endRadius, clockwise);
    CGContextFillPath(context);
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws the Go stones layer.
// -----------------------------------------------------------------------------
- (void) drawStones
{
  bool crossHairStoneDrawn = false;
  GoGame* game = [GoGame sharedGame];
  NSEnumerator* enumerator = [game.board pointEnumerator];
  GoPoint* point;
  while (point = [enumerator nextObject])
  {
    if (point.hasStone)
    {
      UIColor* color;
      // TODO create an isEqualToPoint:(GoPoint*)point in GoPoint
      if (self.crossHairPoint && [self.crossHairPoint.vertex isEqualToVertex:point.vertex])
      {
        color = self.model.crossHairColor;
        crossHairStoneDrawn = true;
      }
      else if (point.blackStone)
        color = [UIColor blackColor];
      else
        color = [UIColor whiteColor];
      [self drawStone:color vertex:point.vertex];
    }
    else
    {
      // TODO remove this or make it into something that can be turned on
      // at runtime for debugging
//      [self drawEmpty:point];
    }
  }

  // Draw after regular stones to paint the cross-hair stone over any regular
  // stone that might be present
  if (self.crossHairPoint && ! crossHairStoneDrawn)
  {
    // TODO move color handling to a helper function; there is similar code
    // floating around somewhere else (GoGame?)
    UIColor* color = nil;
    if (game.currentPlayer.isBlack)
      color = [UIColor blackColor];
    else
      color = [UIColor whiteColor];
    if (color)
      [self drawStone:color point:self.crossHairPoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at intersection @a point, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(UIColor*)color point:(GoPoint*)point
{
  [self drawStone:color vertex:point.vertex];
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at intersection @a vertex, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(UIColor*)color vertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  [self drawStone:color vertexX:numericVertex.x vertexY:numericVertex.y];
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone at the intersection identified by @a vertexX
/// and @a vertexY, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(UIColor*)color vertexX:(int)vertexX vertexY:(int)vertexY
{
  [self drawStone:color coordinates:[self coordinatesFromVertexX:vertexX vertexY:vertexY]];
}

// -----------------------------------------------------------------------------
/// @brief Draws a single stone with its center at the view coordinates
/// @a coordinaes, using color @a color.
// -----------------------------------------------------------------------------
- (void) drawStone:(UIColor*)color coordinates:(CGPoint)coordinates
{
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, color.CGColor);

  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, self.stoneRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

// -----------------------------------------------------------------------------
/// @brief Draws the symbols layer.
// -----------------------------------------------------------------------------
- (void) drawSymbols
{
  if (self.model.markLastMove)
  {
    GoMove* lastMove = [GoGame sharedGame].lastMove;
    if (lastMove && PlayMove == lastMove.type)
    {
      CGPoint lastMoveCoordinates = [self coordinatesFromVertex:lastMove.point.vertex];
      // The symbol for marking the last move is a box inside the circle that
      // represents the Go stone. Geometry tells us that in this scenario
      //   a = r * sqrt(2)
      // We subtract another 2 points because we don't want to touch the circle.
      int lastMoveBoxSide = floor(self.stoneRadius * sqrt(2) - 2);
      // The origin for Core Graphics is in the bottom-left corner!
      CGRect lastMoveBox;
      lastMoveBox.origin.x = floor((lastMoveCoordinates.x - (lastMoveBoxSide / 2))) + gHalfPixel;
      lastMoveBox.origin.y = floor((lastMoveCoordinates.y - (lastMoveBoxSide / 2))) + gHalfPixel;
      lastMoveBox.size.width = lastMoveBoxSide;
      lastMoveBox.size.height = lastMoveBoxSide;
      // TODO move color handling to a helper function; there is similar code
      // floating around somewhere else in this class
      UIColor* lastMoveBoxColor;
      if (lastMove.player.isBlack)
        lastMoveBoxColor = [UIColor whiteColor];
      else
        lastMoveBoxColor = [UIColor blackColor];
      // Now render the box
      CGContextRef context = UIGraphicsGetCurrentContext();
      CGContextBeginPath(context);
      CGContextAddRect(context, lastMoveBox);
      CGContextSetStrokeColorWithColor(context, lastMoveBoxColor.CGColor);
      CGContextSetLineWidth(context, self.model.normalLineWidth);
      CGContextStrokePath(context);
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws the coordinate labels layer.
// -----------------------------------------------------------------------------
- (void) drawLabels
{
  // TODO not yet implemented
}

// -----------------------------------------------------------------------------
/// @brief Draws the territory layer in scoring mode.
// -----------------------------------------------------------------------------
- (void) drawTerritory
{
}

// -----------------------------------------------------------------------------
/// @brief Draws the dead stones layer in scoring mode.
// -----------------------------------------------------------------------------
- (void) drawDeadStones
{
}

// -----------------------------------------------------------------------------
/// @brief Updates the status line with text that provides feedback to the user
/// about what's going on.
// -----------------------------------------------------------------------------
- (void) updateStatusLine
{
  GoGame* game = [GoGame sharedGame];
  NSString* statusText = @"";
  if (self.crossHairPoint)
  {
    statusText = self.crossHairPoint.vertex.string;
    if (! self.crossHairPointIsLegalMove)
      statusText = [statusText stringByAppendingString:@" - You can't play there"];
  }
  else
  {
    if (game.isComputerThinking)
    {
      switch (game.state)
      {
        case GameHasNotYetStarted:  // game state is set to started only after the GTP response is received
        case GameHasStarted:
          statusText = [game.currentPlayer.player.name stringByAppendingString:@" is thinking..."];
          break;
        default:
          break;
      }
    }
    else
    {
      if (self.model.scoringMode)
      {
        if (self.model.score.scoringInProgress)
          statusText = @"Scoring in progress...";
        else
          statusText = [NSString stringWithFormat:@"%@. Tap to mark dead stones.", [self.model.score resultString]];
      }
      else
      {
        switch (game.state)
        {
          case GameHasNotYetStarted:  // game state is set to started only after the GTP response is received
          case GameHasStarted:
          {
            GoMove* lastMove = game.lastMove;
            if (PassMove == lastMove.type && lastMove.computerGenerated)
            {
              // TODO fix when GoColor class is added
              NSString* color;
              if (lastMove.player.black)
                color = @"Black";
              else
                color = @"White";
              statusText = [NSString stringWithFormat:@"%@ has passed", color];
            }
            break;
          }
          case GameHasEnded:
          {
            switch (game.reasonForGameHasEnded)
            {
              case GoGameHasEndedReasonTwoPasses:
              {
                statusText = @"Game has ended by two consecutive pass moves";
                break;
              }
              case GoGameHasEndedReasonResigned:
              {
                NSString* color;
                // TODO fix when GoColor class is added
                if (game.currentPlayer.black)
                  color = @"Black";
                else
                  color = @"White";
                statusText = [NSString stringWithFormat:@"Game has ended by resigning, %@ resigned", color];
                break;
              }
              default:
                break;
            }
            break;
          }
          default:
            break;
        }
      }
    }
  }
  self.statusLine.text = statusText;
}

// -----------------------------------------------------------------------------
/// @brief Starts/stops animation of the activity indicator, to provide feedback
/// to the user about operations that take a long time.
// -----------------------------------------------------------------------------
- (void) updateActivityIndicator
{
  if (self.model.scoringMode)
  {
    if (self.model.score.scoringInProgress)
      [self.activityIndicator startAnimating];
    else
      [self.activityIndicator stopAnimating];
  }
  else
  {
    if ([[GoGame sharedGame] isComputerThinking])
      [self.activityIndicator startAnimating];
    else
      [self.activityIndicator stopAnimating];
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws a small circle at intersection @a point, when @a point does
/// not have a stone on it. The color of the circle is different for different
/// regions.
///
/// This method is a debugging aid to see how GoBoardRegions are calculated.
// -----------------------------------------------------------------------------
- (void) drawEmpty:(GoPoint*)point
{
  struct GoVertexNumeric numericVertex = point.vertex.numeric;
  CGPoint coordinates = [self coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
  CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetFillColorWithColor(context, [[point.region color] CGColor]);

  const int startRadius = 0;
  const int endRadius = 2 * M_PI;
  const int clockwise = 0;
  int circleRadius = floor(self.stoneRadius / 2);
  CGContextAddArc(context, coordinates.x + gHalfPixel, coordinates.y + gHalfPixel, circleRadius, startRadius, endRadius, clockwise);
  CGContextFillPath(context);
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a point.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromPoint:(GoPoint*)point
{
  return [self coordinatesFromVertex:point.vertex];
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// @a vertex.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromVertex:(GoVertex*)vertex
{
  struct GoVertexNumeric numericVertex = vertex.numeric;
  return [self coordinatesFromVertexX:numericVertex.x vertexY:numericVertex.y];
}

// -----------------------------------------------------------------------------
/// @brief Returns view coordinates that correspond to the intersection
/// identified by @a vertexX and @a vertexY.
// -----------------------------------------------------------------------------
- (CGPoint) coordinatesFromVertexX:(int)vertexX vertexY:(int)vertexY
{
  // The origin for Core Graphics is in the bottom-left corner!
  return CGPointMake(self.topLeftPointX + (self.pointDistance * (vertexX - 1)),
                     self.topLeftPointY + self.lineLength - (self.pointDistance * (vertexY - 1)));
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoVertex object for the intersection identified by the view
/// coordinates @a coordinates.
///
/// Returns nil if @a coordinates do not refer to a valid intersection (e.g.
/// because @a coordinates are outside the board's edges).
// -----------------------------------------------------------------------------
- (GoVertex*) vertexFromCoordinates:(CGPoint)coordinates
{
  struct GoVertexNumeric numericVertex;
  numericVertex.x = 1 + (coordinates.x - self.topLeftPointX) / self.pointDistance;
  numericVertex.y = 1 + (self.topLeftPointY + self.lineLength - coordinates.y) / self.pointDistance;
  GoVertex* vertex;
  @try
  {
    vertex = [GoVertex vertexFromNumeric:numericVertex];
  }
  @catch (NSException* exception)
  {
    vertex = nil;
  }
  return vertex;
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection identified by the view
/// coordinates @a coordinates.
///
/// Returns nil if @a coordinates do not refer to a valid intersection (e.g.
/// because @a coordinates are outside the board's edges).
// -----------------------------------------------------------------------------
- (GoPoint*) pointFromCoordinates:(CGPoint)coordinates
{
  GoVertex* vertex = [self vertexFromCoordinates:coordinates];
  if (vertex)
    return [[GoGame sharedGame].board pointAtVertex:vertex.string];
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameNewCreated notification.
// -----------------------------------------------------------------------------
- (void) goGameNewCreated:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameStateChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameStateChanged:(NSNotification*)notification
{
  [self updateStatusLine];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameFirstMoveChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameFirstMoveChanged:(NSNotification*)notification
{
  // TODO check if it's possible to update only a rectangle
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goGameLastMoveChanged notification.
// -----------------------------------------------------------------------------
- (void) goGameLastMoveChanged:(NSNotification*)notification
{
  // TODO check if it's possible to update only a rectangle
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #computerPlayerThinkingStarts and
/// #computerPlayerThinkingStops notifications.
// -----------------------------------------------------------------------------
- (void) computerPlayerThinkingChanged:(NSNotification*)notification
{
  [self updateStatusLine];
  [self updateActivityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreScoringModeDisabled notification.
// -----------------------------------------------------------------------------
- (void) goScoreScoringModeDisabled:(NSNotification*)notification
{
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationStarts notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationStarts:(NSNotification*)notification
{
  [self updateStatusLine];
  [self updateActivityIndicator];
}

// -----------------------------------------------------------------------------
/// @brief Responds to the #goScoreCalculationEnds notifications.
// -----------------------------------------------------------------------------
- (void) goScoreCalculationEnds:(NSNotification*)notification
{
  [self updateStatusLine];
  [self updateActivityIndicator];
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Responds to KVO notifications.
// -----------------------------------------------------------------------------
- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object change:(NSDictionary*)change context:(void*)context
{
  // TODO check if it's possible to update only specific parts of the view
  [self delayedUpdate];
}

// -----------------------------------------------------------------------------
/// @brief Returns a GoPoint object for the intersection that is closest to the
/// view coordinates @a coordinates. Returns nil if there is no "closest"
/// intersection.
///
/// Determining "closest" works like this:
/// - @a coordinates are slightly adjusted so that the intersection is not
///   directly under the user's fingertip
/// - The closest intersection is the one whose distance to @a coordinates is
///   less than half the distance between two adjacent intersections. This
///   creates a "snap-to" effect when the user's panning fingertip crosses half
///   the distance between two adjacent intersections.
/// - If @a coordinates are a sufficient distance away from the Go board edges,
///   there is no "closest" intersection
// -----------------------------------------------------------------------------
- (GoPoint*) crossHairPointAt:(CGPoint)coordinates
{
  // Adjust so that the cross-hair is not directly under the user's fingertip,
  // but one or more point distances above
  coordinates.y -= self.model.crossHairPointDistanceFromFinger * self.pointDistance;

  // Check if cross-hair is outside the grid and should not be displayed. To
  // make the edge lines accessible in the same way as the inner lines,
  // a padding of half a point distance must be added.
  int halfPointDistance = floor(self.pointDistance / 2);
  if (coordinates.x < self.topLeftPointX)
  {
    if (coordinates.x < self.topLeftPointX - halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.x = self.topLeftPointX;
  }
  else if (coordinates.x > self.topLeftPointX + self.lineLength)
  {
    if (coordinates.x > self.topLeftPointX + self.lineLength + halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.x = self.topLeftPointX + self.lineLength;
  }
  else if (coordinates.y < self.topLeftPointY)
  {
    if (coordinates.y < self.topLeftPointY - halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.y = self.topLeftPointY;
  }
  else if (coordinates.y > self.topLeftPointY + self.lineLength)
  {
    if (coordinates.y > self.topLeftPointY + self.lineLength + halfPointDistance)
      coordinates = CGPointZero;
    else
      coordinates.y = self.topLeftPointY + self.lineLength;
  }
  else
  {
    // Adjust so that the snap-to calculation below switches to the next vertex
    // when the cross-hair has moved half-way through the distance to that vertex
    coordinates.x += halfPointDistance;
    coordinates.y += halfPointDistance;
  }

  // Snap to the nearest vertex if the coordinates were valid
  if (0 == coordinates.x && 0 == coordinates.y)
    return nil;
  else
  {
    coordinates.x = self.topLeftPointX + self.pointDistance * floor((coordinates.x - self.topLeftPointX) / self.pointDistance);
    coordinates.y = self.topLeftPointY + self.pointDistance * floor((coordinates.y - self.topLeftPointY) / self.pointDistance);
    return [self pointFromCoordinates:coordinates];
  }
}

// -----------------------------------------------------------------------------
/// @brief Moves the cross-hair to the intersection identified by @a point,
/// specifying whether an actual play move at the intersection would be legal.
// -----------------------------------------------------------------------------
- (void) moveCrossHairTo:(GoPoint*)point isLegalMove:(bool)isLegalMove
{
  if (crossHairPoint == point && crossHairPointIsLegalMove == isLegalMove)
    return;

  // TODO check if it's possible to update only a few rectangles
  self.crossHairPoint = point;
  self.crossHairPointIsLegalMove = isLegalMove;
  [self delayedUpdate];
}

@end
