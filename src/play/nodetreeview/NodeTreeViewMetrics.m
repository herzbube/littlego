// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "NodeTreeViewMetrics.h"
#import "canvas/NodeTreeViewCanvas.h"
#import "canvas/NodeTreeViewCellPosition.h"
#import "../model/NodeTreeViewModel.h"
#import "../../shared/LayoutManager.h"
#import "../../ui/UiElementMetrics.h"
#import "../../ui/UiUtilities.h"
#import "../../utility/FontRange.h"
#import "../../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetrics()
@property(nonatomic, assign) id<NodeTreeViewCanvasDataProvider> canvasDataProvider;
/// @brief Prevents double-unregistering of notification responders by
/// an external actor followed by dealloc. This is possible because
/// removeNotificationResponders() is in the public API of this class.
@property(nonatomic, assign) bool notificationRespondersAreSetup;
@property(nonatomic, retain) FontRange* nodeNumberLabelFontRange;
@property(nonatomic, retain) FontRange* singleCharacterNodeSymbolFontRange;
@property(nonatomic, retain) FontRange* threeCharactersNodeSymbolFontRange;
@property(nonatomic, retain) FontRange* twoLinesOfCharactersNodeSymbolFontRange;
@end


@implementation NodeTreeViewMetrics

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a NodeTreeViewMetrics object.
///
/// @note This is the designated initializer of NodeTreeViewMetrics.
// -----------------------------------------------------------------------------
- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
  canvasDataProvider:(id<NodeTreeViewCanvasDataProvider>)canvasDataProvider
     traitCollection:(UITraitCollection*)traitCollection
{
  // Call designated initializer of superclass (NSObject)
  self = [super init];
  if (! self)
    return nil;

  self.canvasDataProvider = canvasDataProvider;

  self.notificationRespondersAreSetup = false;

  [self setupStaticProperties];
  [self setupFontRanges];
  [self setupMainProperties:nodeTreeViewModel];
  [self updateWithTraitCollection:traitCollection];
  // Remaining properties are initialized by this updater
  [self updateWithAbstractCanvasSize:self.abstractCanvasSize
                   condenseMoveNodes:self.condenseMoveNodes
                   absoluteZoomScale:self.absoluteZoomScale
                  displayNodeNumbers:self.displayNodeNumbers
             nodeNumberViewIsOverlay:self.nodeNumberViewIsOverlay];

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NodeTreeViewMetrics object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.canvasDataProvider = nil;
  self.nodeNumberLabelFont = nil;
  self.nodeNumberLabelFontRange = nil;
  self.singleCharacterNodeSymbolFont = nil;
  self.singleCharacterNodeSymbolFontRange = nil;
  self.threeCharactersNodeSymbolFont = nil;
  self.threeCharactersNodeSymbolFontRange = nil;
  self.twoLinesOfCharactersNodeSymbolFont = nil;
  self.twoLinesOfCharactersNodeSymbolFontRange = nil;
  self.normalLineColor = nil;
  self.selectedLineColor = nil;
  self.selectedNodeColor = nil;
  self.nodeSymbolColor = nil;
  self.nodeSymbolTextColor = nil;
  self.nodeSymbolTextShadow = nil;
  self.nodeNumberTextColor = nil;
  self.nodeNumberTextShadow = nil;

  [super dealloc];
}

#pragma mark - Setup during initialization

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupStaticProperties
{
  self.contentsScale = [UIScreen mainScreen].scale;

  self.tileSize = CGSizeMake(128, 128);

  self.minimumAbsoluteZoomScale = 1.0f;
  if ([LayoutManager sharedManager].uiType != UITypePad)
    self.maximumAbsoluteZoomScale = iPhoneMaximumZoomScale;
  else
    self.maximumAbsoluteZoomScale = iPadMaximumZoomScale;

  // When the node tree view was originally designed, the line widths and cell
  // sizes assigned here were selected so that lines could be drawn in the
  // cell's horizontal and vertical center without anti-aliasing. Note that
  // widths and sizes we specify here are in point units, which means they are
  // multiplied by self.contentsScale to arrive at the effective number of
  // pixels to be drawn.
  //
  // In any case, this fine-tuning is most likely unnecessary, because when the
  // view is zoomed a factor is applied and the fine-tuning is lost. Also
  // self.numberOfCellsOfMultipartCell is applied as a factor for multipart
  // cell sizes. Should there be a need in the future to changes the values,
  // it should be fine to do so.
  if (fmod(self.contentsScale, 2.0f) == 0.0f)
  {
    // self.contentsScale is an even number => any number multiplied by
    // self.contentsScale will result in an even number of pixels => we
    // can use both even and uneven numbers for line widths and cell sizes.
    self.normalLineWidth = 1;
    self.selectedLineWidth = 2;
    self.nodeTreeViewCellBaseSize = 13;
  }
  else
  {
    // self.contentsScale is an uneven number => even numbers multiplied by
    // self.contentsScale will result in an even number of pixels, uneven
    // numbers multiplied by self.contentsScale will result in an uneven number
    // of pixels => numbers we use for line widths and cell sizes must be either
    // all even, or all uneven.
    self.normalLineWidth = 1;
    self.selectedLineWidth = 3;
    self.nodeTreeViewCellBaseSize = 13;
  }

  self.paddingX = [UiElementMetrics horizontalSpacingSiblings];
  // No need for an additional vertical padding - the cell height is sufficient
  // so that there is some vertical space that is unused for drawing, which
  // also serves as a minimal vertical padding
  self.paddingY = 0;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupFontRanges
{
  // The minimum should not be smaller: There is no point in displaying text
  // that is so small that nobody can read it
  int minimumFontSize = 8;
  // The maximum can be any size that still supports the largest texts drawn
  // in the tree view node. The largest texts currently known are textual node
  // symbols drawn in uncondensed cells, when the zoom scale is at its maximum.
  int maximumFontSize = 100;

  NSString* widestNodeNumber = @"8888";
  self.nodeNumberLabelFontRange = [[[FontRange alloc] initWithText:widestNodeNumber
                                                   minimumFontSize:minimumFontSize
                                                   maximumFontSize:maximumFontSize] autorelease];

  // Because we are using a mono-spaced font for the textual node symbols, it
  // doesn't really matter which characters we give to FontRange, as long as
  // it's the correct number
  NSString* widestSingleCharacterNodeSymbolText = @"i";
  self.singleCharacterNodeSymbolFontRange = [[[FontRange alloc] initWithMonospacedFontAndText:widestSingleCharacterNodeSymbolText
                                                                              minimumFontSize:minimumFontSize
                                                                              maximumFontSize:maximumFontSize] autorelease];
  NSString* widestThreeCharactersNodeSymbolText = @"</>";
  self.threeCharactersNodeSymbolFontRange = [[[FontRange alloc] initWithMonospacedFontAndText:widestThreeCharactersNodeSymbolText
                                                                              minimumFontSize:minimumFontSize
                                                                              maximumFontSize:maximumFontSize] autorelease];
  NSString* widestTwoLinesOfCharactersNodeSymbolText = @"</>";
  self.twoLinesOfCharactersNodeSymbolFontRange = [[[FontRange alloc] initWithMonospacedFontAndText:widestTwoLinesOfCharactersNodeSymbolText
                                                                                   minimumFontSize:minimumFontSize
                                                                                   maximumFontSize:maximumFontSize] autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for the initializer.
// -----------------------------------------------------------------------------
- (void) setupMainProperties:(NodeTreeViewModel*)nodeTreeViewModel
{
  self.abstractCanvasSize = self.canvasDataProvider.canvasSize;
  self.condenseMoveNodes = nodeTreeViewModel.condenseMoveNodes;
  self.absoluteZoomScale = 1.0f;
  self.nodeNumberViewIsOverlay = nodeTreeViewModel.nodeNumberViewIsOverlay;
  self.canvasSize = CGSizeZero;

  self.displayNodeNumbers = nodeTreeViewModel.displayNodeNumbers;
  self.numberOfCellsOfMultipartCell = nodeTreeViewModel.numberOfCellsOfMultipartCell;
}

#pragma mark - Public API - Updaters

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newAbstractCanvasSize.
///
/// The new canvas size will be @a newAbstractCanvasSize multiplied by the
/// current @e nodeTreeViewCellSize and the current absolute zoom scale.
// -----------------------------------------------------------------------------
- (void) updateWithAbstractCanvasSize:(CGSize)newAbstractCanvasSize
{
  if (CGSizeEqualToSize(newAbstractCanvasSize, self.abstractCanvasSize))
    return;
  [self updateWithAbstractCanvasSize:newAbstractCanvasSize
                   condenseMoveNodes:self.condenseMoveNodes
                   absoluteZoomScale:self.absoluteZoomScale
                  displayNodeNumbers:self.displayNodeNumbers
             nodeNumberViewIsOverlay:self.nodeNumberViewIsOverlay];
  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.abstractCanvasSize = newAbstractCanvasSize;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newCondenseMoveNodes.
///
/// The new canvas size will be the current @e abstractCanvasSize multiplied by
/// the new @e nodeTreeViewCellSize (which is based on @a newCondenseMoveNodes)
/// and the current absolute zoom scale.
// -----------------------------------------------------------------------------
- (void) updateWithCondenseMoveNodes:(bool)newCondenseMoveNodes
{
  if (newCondenseMoveNodes == self.condenseMoveNodes)
    return;
  [self updateWithAbstractCanvasSize:self.abstractCanvasSize
                   condenseMoveNodes:newCondenseMoveNodes
                   absoluteZoomScale:self.absoluteZoomScale
                  displayNodeNumbers:self.displayNodeNumbers
             nodeNumberViewIsOverlay:self.nodeNumberViewIsOverlay];
  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.condenseMoveNodes = newCondenseMoveNodes;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newRelativeZoomScale.
///
/// The new canvas size will be the current @e abstractCanvasSize multiplied by
/// the current @e nodeTreeViewCellSize and the new absolute zoom scale (which
/// is based on @a newRelativeZoomScale).
///
/// NodeTreeViewMetrics uses an absolute zoom scale for its calculations. This
/// zoom scale is also available as the public property @e absoluteZoomScale.
/// The zoom scale specified here is a @e relative zoom scale that is multiplied
/// with the current absolute zoom to get the new absolute zoom scale.
///
/// Example: The current absolute zoom scale is 2.0, i.e. the canvas size is
/// double the size of the base size. A new relative zoom scale of 1.5 results
/// in the new absolute zoom scale 2.0 * 1.5 = 3.0, i.e. the canvas size will
/// be triple the size of the base size.
///
/// @attention This method may make adjustments so that the final absolute
/// zoom scale can be different from the result of the multiplication described
/// above. For instance, if rounding errors would cause the absolute zoom scale
/// to fall outside of the minimum/maximum range, an adjustment is made so that
/// the absolute zoom scale hits the range boundary.
// -----------------------------------------------------------------------------
- (void) updateWithRelativeZoomScale:(CGFloat)newRelativeZoomScale
{
  if (1.0f == newRelativeZoomScale)
    return;
  CGFloat newAbsoluteZoomScale = self.absoluteZoomScale * newRelativeZoomScale;
  if (newAbsoluteZoomScale < self.minimumAbsoluteZoomScale)
    newAbsoluteZoomScale = self.minimumAbsoluteZoomScale;
  else if (newAbsoluteZoomScale > self.maximumAbsoluteZoomScale)
    newAbsoluteZoomScale = self.maximumAbsoluteZoomScale;
  [self updateWithAbstractCanvasSize:self.abstractCanvasSize
                   condenseMoveNodes:self.condenseMoveNodes
                   absoluteZoomScale:newAbsoluteZoomScale
                  displayNodeNumbers:self.displayNodeNumbers
             nodeNumberViewIsOverlay:self.nodeNumberViewIsOverlay];
  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.absoluteZoomScale = newAbsoluteZoomScale;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newNodeNumberViewIsOverlay.
///
/// The new canvas size will be the current @e abstractCanvasSize multiplied by
/// the new @e nodeTreeViewCellSize and the current absolute zoom scale. If
/// @a newNodeNumberViewIsOverlay is true the value of
/// @e self.nodeNumberStripHeight is added as a padding at the top.
// -----------------------------------------------------------------------------
- (void) updateWithNodeNumberViewIsOverlay:(bool)newNodeNumberViewIsOverlay
{
  if (newNodeNumberViewIsOverlay == self.nodeNumberViewIsOverlay)
    return;
  [self updateWithAbstractCanvasSize:self.abstractCanvasSize
                   condenseMoveNodes:self.condenseMoveNodes
                   absoluteZoomScale:self.absoluteZoomScale
                  displayNodeNumbers:self.displayNodeNumbers
             nodeNumberViewIsOverlay:newNodeNumberViewIsOverlay];
  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.nodeNumberViewIsOverlay = newNodeNumberViewIsOverlay;
}

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// @a newDisplayNodeNumbers.
///
/// Invoking this updater does not change the canvas size, but it changes the
/// locations of all node tree elements on the canvas.
// -----------------------------------------------------------------------------
- (void) updateWithDisplayNodeNumbers:(bool)newDisplayNodeNumbers
{
  if (self.displayNodeNumbers == newDisplayNodeNumbers)
    return;
  [self updateWithAbstractCanvasSize:self.abstractCanvasSize
                   condenseMoveNodes:self.condenseMoveNodes
                   absoluteZoomScale:self.absoluteZoomScale
                  displayNodeNumbers:newDisplayNodeNumbers
             nodeNumberViewIsOverlay:self.nodeNumberViewIsOverlay];
  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.displayNodeNumbers = newDisplayNodeNumbers;
}

// -----------------------------------------------------------------------------
/// @brief Updates the colors used for drawing the node tree view and the node
/// numbers view to match the UIUserInterfaceStyle (light/dark mode) found in
/// @a traitCollection. If @a traitCollection is @e nil the colors are updated
/// for light mode.
// -----------------------------------------------------------------------------
- (void) updateWithTraitCollection:(UITraitCollection*)traitCollection
{
  bool isLightUserInterfaceStyle = (traitCollection
                                    ? [UiUtilities isLightUserInterfaceStyle:traitCollection]
                                    : true);

  UIColor* textShadowColor;

  if (isLightUserInterfaceStyle)
  {
    self.normalLineColor = [UIColor blackColor];
    self.selectedLineColor = [UIColor redColor];
    self.selectedNodeColor = [UIColor redColor];
    self.nodeSymbolColor = [UIColor blackColor];
    self.nodeSymbolTextColor = [UIColor blackColor];
    self.nodeNumberTextColor = [UIColor blackColor];
    textShadowColor = [UIColor whiteColor];
  }
  else
  {
    self.normalLineColor = [UIColor whiteColor];
    self.selectedLineColor = [UIColor constructionOrangeColor];
    self.selectedNodeColor = [UIColor constructionOrangeColor];
    self.nodeSymbolColor = [UIColor whiteColor];
    self.nodeSymbolTextColor = [UIColor whiteColor];
    self.nodeNumberTextColor = [UIColor whiteColor];
    textShadowColor = [UIColor blackColor];
  }

  NSShadow* textShadow = [[[NSShadow alloc] init] autorelease];
  textShadow.shadowColor = textShadowColor;
  textShadow.shadowBlurRadius = 5.0;
  textShadow.shadowOffset = CGSizeMake(1.0, 1.0);
  self.nodeSymbolTextShadow = textShadow;
  self.nodeNumberTextShadow = textShadow;
}

#pragma mark - Private backend invoked from all public API updaters

// -----------------------------------------------------------------------------
/// @brief Updates the values stored by this NodeTreeViewMetrics object based on
/// the supplied argument values.
///
/// This is the internal backend for the various public updater methods.
// -----------------------------------------------------------------------------
- (void) updateWithAbstractCanvasSize:(CGSize)newAbstractCanvasSize
                    condenseMoveNodes:(bool)newCondenseMoveNodes
                    absoluteZoomScale:(CGFloat)newAbsoluteZoomScale
                   displayNodeNumbers:(bool)newDisplayNodeNumbers
              nodeNumberViewIsOverlay:(bool)newNodeNumberViewIsOverlay
{
  // ----------------------------------------------------------------------
  // All calculations in this method must use the new... parameters.
  // The corresponding properties must not be used because, due
  // to the way how this update method is invoked, at least one of these
  // properties is guaranteed to be not up-to-date.
  // ----------------------------------------------------------------------

  CGFloat nodeTreeViewCellCondensedWidth = floor(self.nodeTreeViewCellBaseSize * newAbsoluteZoomScale);
  CGFloat nodeTreeViewCellUncondensedWidth = nodeTreeViewCellCondensedWidth * self.numberOfCellsOfMultipartCell;

  CGSize nodeTreeViewCellCondensedSize = CGSizeMake(nodeTreeViewCellCondensedWidth,
                                                    nodeTreeViewCellUncondensedWidth);
  CGSize nodeTreeViewCellUncondensedSize = CGSizeMake(nodeTreeViewCellUncondensedWidth,
                                                      nodeTreeViewCellUncondensedWidth);

  if (newCondenseMoveNodes)
  {
    self.nodeTreeViewCellSize = nodeTreeViewCellCondensedSize;
    self.nodeTreeViewMultipartCellSize = nodeTreeViewCellUncondensedSize;
  }
  else
  {
    self.nodeTreeViewCellSize = nodeTreeViewCellUncondensedSize;
    self.nodeTreeViewMultipartCellSize = nodeTreeViewCellUncondensedSize;
  }

  if (newDisplayNodeNumbers)
  {
    // The node number label strip can be substantially less high than
    // self.nodeTreeViewCellSize.height, but it must still be fairly large so
    // that the node number label is not too small. 2/3 is an experimentally
    // determined factor.
    static const CGFloat coordinateLabelStripWidthFactor = 2.0f / 3.0f;
    int nodeNumberStripHeight = floor(self.nodeTreeViewCellSize.height * coordinateLabelStripWidthFactor);

    self.nodeNumberViewCellSize = CGSizeMake(self.nodeTreeViewCellSize.width, nodeNumberStripHeight);
    self.nodeNumberViewMultipartCellSize = CGSizeMake(self.nodeTreeViewMultipartCellSize.width, nodeNumberStripHeight);

    // A small padding on both sides is subtracted from the base width so
    // that adjacent node numbers have a small spacing between them.
    static const int nodeNumberLabelPaddingX = 1;
    int nodeNumberLabelAvailableWidth = (nodeTreeViewCellUncondensedWidth
                                         - 2 * nodeNumberLabelPaddingX);
    UIFont* nodeNumberLabelFont = nil;
    CGSize nodeNumberLabelMaximumSize = CGSizeZero;
    bool didFindNodeNumberLabelFont = [self.nodeNumberLabelFontRange queryForWidth:nodeNumberLabelAvailableWidth
                                                                              font:&nodeNumberLabelFont
                                                                          textSize:&nodeNumberLabelMaximumSize];
    if (didFindNodeNumberLabelFont)
    {
      self.nodeNumberStripHeight = nodeNumberStripHeight;
      self.nodeNumberViewHeight = self.paddingY + self.nodeNumberStripHeight;
      self.nodeNumberLabelFont = nodeNumberLabelFont;
      self.nodeNumberLabelMaximumSize = nodeNumberLabelMaximumSize;
    }
    else
    {
      self.nodeNumberStripHeight = 0;
      self.nodeNumberViewHeight = 0;
      self.nodeNumberViewCellSize = CGSizeZero;
      self.nodeNumberViewMultipartCellSize = CGSizeZero;
      self.nodeNumberLabelFont = nil;
      self.nodeNumberLabelMaximumSize = CGSizeZero;
    }
  }
  else
  {
    self.nodeNumberStripHeight = 0;
    self.nodeNumberViewHeight = 0;
    self.nodeNumberViewCellSize = CGSizeZero;
    self.nodeNumberViewMultipartCellSize = CGSizeZero;
    self.nodeNumberLabelFont = nil;
    self.nodeNumberLabelMaximumSize = CGSizeZero;
  }

  self.topLeftTreeCornerX = self.paddingX;
  self.topLeftTreeCornerY = newNodeNumberViewIsOverlay ? self.nodeNumberViewHeight : self.paddingY;

  self.topLeftCellX = 0;
  self.topLeftCellY = 0;
  self.bottomRightCellX = newAbstractCanvasSize.width - 1;
  self.bottomRightCellY = newAbstractCanvasSize.height - 1;

  // There must be some spacing between node symbols so they don't touch each
  // other. This means that node symbols don't get the full width of a cell.
  // How much they get is determined by the following factor. The factor must
  // be chosen so that connection lines (which are drawn in the spacing between
  // the node symbols) are still noticeable even when they connect node symbols
  // in condensed cells. The factor used here was experimentally determined to
  // look good.
  static const CGFloat nodeSymbolSizeFactor = 0.75f;
  CGFloat condensedNodeSymbolWidthAndHeight = ceilf(nodeTreeViewCellCondensedSize.width * nodeSymbolSizeFactor);
  self.condensedNodeSymbolSize = CGSizeMake(condensedNodeSymbolWidthAndHeight, condensedNodeSymbolWidthAndHeight);
  CGFloat uncondensedNodeSymbolWidthAndHeight = ceilf(nodeTreeViewCellUncondensedSize.width * nodeSymbolSizeFactor);
  self.uncondensedNodeSymbolSize = CGSizeMake(uncondensedNodeSymbolWidthAndHeight, uncondensedNodeSymbolWidthAndHeight);

  // Some symbols consist of text that needs to be drawn with a font of a
  // certain size. Here we determine these fonts and their sizes. Textual
  // symbols are always drawn in uncondensed cells. Textual symbols are always
  // surrounded with a bounding circle line. Here we say that by default a
  // textual symbol gets the full symbol size.
  CGFloat textualNodeSymbolBaseWidth = uncondensedNodeSymbolWidthAndHeight;
  // Some single-character textual symbols consist of a character that takes up
  // more space vertically than it does horizontally (e.g. "i", "k", "h"). For
  // this reason the symbol must not get the full node symbol width, otherwise
  // the character's upper/lower parts will be too close to the upper/lower
  // parts of the bounding circle line. The factor used here was determined
  // experimentally to still look good.
  static const CGFloat singleCharacterNodeSymbolFactor = 0.8;
  CGFloat singleCharacterNodeSymbolWidth = textualNodeSymbolBaseWidth * singleCharacterNodeSymbolFactor;
  self.singleCharacterNodeSymbolFont = [self.singleCharacterNodeSymbolFontRange queryForWidth:singleCharacterNodeSymbolWidth];
  // For some unknown reason, if a three-character textual symbol is rendered
  // with the font that is found for the regular node symbol width, the text
  // appears too small. Because of this, three-character textual symbols get
  // more width than they should. The factor used here was determined
  // experimentally to still look good.
  static const CGFloat threeCharactersNodeSymbolFactor = 1.3;
  CGFloat threeCharactersNodeSymbolWidth = textualNodeSymbolBaseWidth * threeCharactersNodeSymbolFactor;
  self.threeCharactersNodeSymbolFont = [self.threeCharactersNodeSymbolFontRange queryForWidth:threeCharactersNodeSymbolWidth];
  // A textual symbol consisting of two lines of characters that are vertically
  // stacked is surrounded with a bounding circle line, therefore both lines of
  // text don't get the same full width as a single line would (which would be
  // drawn in the vertical center of the circle). For the same unknown reason as
  // for threeCharactersNodeSymbolFactor (see above), the factor used here can
  // be larger than 1.0, but the factor must still be smaller than
  // threeCharactersNodeSymbolFactor because, as explained, two lines get less
  // width than a single line. The factor used here was determined
  // experimentally to still look good.
  static const CGFloat twoLinesOfCharactersNodeSymbolFactor = 1.2;
  CGFloat twoLinesOfCharactersNodeSymbolWidth = textualNodeSymbolBaseWidth * twoLinesOfCharactersNodeSymbolFactor;
  self.twoLinesOfCharactersNodeSymbolFont = [self.twoLinesOfCharactersNodeSymbolFontRange queryForWidth:twoLinesOfCharactersNodeSymbolWidth];

  // Update property only after everything has been re-calculated so that KVO
  // observers get the new values
  self.canvasSize = CGSizeMake(self.topLeftTreeCornerX + newAbstractCanvasSize.width * self.nodeTreeViewCellSize.width + self.paddingX,
                               self.topLeftTreeCornerY + newAbstractCanvasSize.height * self.nodeTreeViewCellSize.height + self.paddingY);
}

#pragma mark - Public API - Calculators

// -----------------------------------------------------------------------------
/// @brief Returns node tree view coordinates that correspond to the origin of
/// the rectangle occupied by the node tree view cell identified by @a position.
///
/// The origin of the coordinate system is assumed to be in the top-left corner.
// -----------------------------------------------------------------------------
- (CGPoint) cellRectOriginFromPosition:(NodeTreeViewCellPosition*)position
{
  return CGPointMake(self.topLeftTreeCornerX + (self.nodeTreeViewCellSize.width * position.x),
                     self.topLeftTreeCornerY + (self.nodeTreeViewCellSize.height * position.y));
}

// -----------------------------------------------------------------------------
/// @brief Returns a NodeTreeViewCellPosition object for the cell that is
/// closest to the view coordinates @a coordinates. Returns @e nil if there is
/// no "closest" cell.
///
/// Determining "closest" works like this:
/// - The closest cell is the one whose distance to @a coordinates is
///   less than half the distance between the centers of two adjacent cells
///   - During panning this creates a "snap-to" effect when the user's panning
///     fingertip crosses half the distance between two adjacent cells.
///   - For a tap this simply makes sure that the fingertip does not have to
///     hit the exact center of the cell.
/// - If @a coordinates are a sufficient distance away from the node tree edges,
///   there is no "closest" cell
// -----------------------------------------------------------------------------
- (NodeTreeViewCellPosition*) positionNear:(CGPoint)coordinates
{
  // Make sure we don't get negative x/y values (which would underflow because
  // cell positions use an unsigned type)
  if (coordinates.x < self.topLeftTreeCornerX || coordinates.y < self.topLeftTreeCornerY)
    return nil;

  unsigned short x = floorf((coordinates.x - self.topLeftTreeCornerX) / self.nodeTreeViewCellSize.width);
  if (x < self.topLeftCellX || x > self.bottomRightCellX)
    return nil;

  unsigned short y = floorf((coordinates.y - self.topLeftTreeCornerY) / self.nodeTreeViewCellSize.height);
  if (y < self.topLeftCellY || y > self.bottomRightCellY)
    return nil;

  return [NodeTreeViewCellPosition positionWithX:x y:y];
}

// -----------------------------------------------------------------------------
/// @brief Returns the GoNode object that is represented by the cell closest to
/// the view coordinates @a coordinates. Returns @e nil if there is no "closest"
/// cell, or if the closest cell does not represent a GoNode.
// -----------------------------------------------------------------------------
- (GoNode*) nodeNear:(CGPoint)coordinates
{
  NodeTreeViewCellPosition* position = [self positionNear:coordinates];
  if (! position)
    return nil;

  return [self.canvasDataProvider nodeAtPosition:position];
}

// -----------------------------------------------------------------------------
/// @brief Returns node number view coordinates that correspond to the origin
/// of the rectangle occupied by the node number view cell identified by
/// @a position.
///
/// The origin of the coordinate system is assumed to be in the top-left corner.
// -----------------------------------------------------------------------------
- (CGPoint) nodeNumberCellRectOriginFromPosition:(NodeTreeViewCellPosition*)position
{
  return CGPointMake(self.paddingX + (self.nodeNumberViewCellSize.width * position.x),
                     self.paddingY + (self.nodeNumberViewCellSize.height * position.y));
}

@end
