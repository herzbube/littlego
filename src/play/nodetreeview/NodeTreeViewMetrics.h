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


// Forward declarations
@class GoNode;
@class NodeTreeViewCanvas;
@class NodeTreeViewCellPosition;
@class NodeTreeViewModel;


// -----------------------------------------------------------------------------
/// @brief The NodeTreeViewMetrics class is a model class that provides
/// locations and sizes (i.e. "metrics") of node tree elements that can be used
/// to draw those elements. NodeTreeViewMetrics also provides the size of the
/// canvas on which to draw.
///
/// The size of the drawing canvas is determined by three things:
/// - The size of an abstract canvas, maintained by NodeTreeViewModel, which
///   contains the entire node tree. The abstract canvas can also be modeled as
///   a table having a number of columns and rows. The number of columns and
///   rows in the table is equal to the width and height, respectively, of the
///   abstract canvas.
/// - The static column width and row height defined by NodeTreeViewMetrics.
///   These static sizes, multiplied with the number of columns and rows,
///   results in the drawing canvas' base size.
/// - The drawing canvas base size is multiplied by a scale factor that is equal
///   to the zoom scale that is currently in effect on the scroll view that
///   displays the node tree.
///
/// Thus the drawing canvas is effectively equal to the content of the scroll
/// view that displays the node tree. If the size of the abstract canvas
/// changes someone must invoke updateWithAbstractCanvasSize:(). If the zoom
/// scale changes, someone must invoke updateWithRelativeZoomScale:().
///
/// If any of these 2 updaters is invoked, NodeTreeViewMetrics re-calculates
/// all of its properties. Clients are expected to use KVO to notice any changes
/// in self.canvasSize, and to respond to such changes by initiating the
/// re-drawing of the appropriate parts of the node tree.
///
///
/// @par Calculations
///
/// The following schematic illustrates the composition of the canvas for a
/// (theoretical) 3x2 tree with uncondensed move nodes, i.e. where all cells
/// are of equal size.
///
/// @verbatim
///                                                     paddingX
///    +------------ topLeftTreeCorner                  +---+
///    |         +-- Node number                        |   |
///    |         |                                      |   v
/// +- | ------- | ----------view/content-------------- | --+ <--+
/// |  |         |                                      v   |    | paddingY
/// |  |         |                                       <-------+
/// |  |  +------v--------node number strip-----------+ <--------+
/// |  |  |      0              1              2      |     |    | nodeNumberStripHeight
/// |  |  +-------------------------------------------+ <--------+
/// |  +->+-topLeftCell-++-------------++-------------+     |
/// |     |             ||             ||             |     |
/// |     |    +---+    ||    +---+    ||    +---+    |     |
/// |     |   /     \   ||   /     \   ||   /     \   |     |
/// |     |  +   o---+--||--+---o---+--||--+---o   +  |     |
/// |     |   \     /   ||   \  |  /   ||   \     /   |     |
/// |     |    +---+    ||    +-+-+    ||    +---+    |     |
/// |     |             ||      |      ||             |     |
/// |     +-------------++------+------++-------------+     |
/// |                    +------+------++-------------+ <--------+
/// |                    |      |      ||             |     |    |
/// |                 +---->  +-+-+    ||    +---+    |     |    |
/// | nodeSymbolSize. |  |   /  |  \   ||   /     \   |     |    |
/// |         height  |  |  +   o---+--||--+---o   +  |     |    | nodeTreeViewCellSize.height
/// |                 |  |   \     /   ||   \     /   |     |    |
/// |                 +---->  +---+    ||    +---+    |     |    |
/// |                    |  ^       ^  ||             |     |    |
/// |                    +--|-------|--++-------------+ <--------+
/// |                       |       |   ^             ^     |
/// +-----------------------|-------|---|-------------|-----+
///                         |       |   |             |
///                         |       |   +-------------+
///                         +-------+   nodeTreeViewCellSize.width
///                         nodeSymbolSize.width
/// @endverbatim
///
///
/// @par Anti-aliasing
///
/// See the documentation of BoardViewMetrics for details.
// -----------------------------------------------------------------------------
@interface NodeTreeViewMetrics : NSObject
{
}

- (id) initWithModel:(NodeTreeViewModel*)nodeTreeViewModel
              canvas:(NodeTreeViewCanvas*)nodeTreeViewCanvas
     traitCollection:(UITraitCollection*)traitCollection
      darkBackground:(bool)darkBackground;
- (void) removeNotificationResponders;

/// @name Updaters
//@{
- (void) updateWithAbstractCanvasSize:(CGSize)newAbstractCanvasSize;
- (void) updateWithCondenseMoveNodes:(bool)newCondenseMoveNodes;
- (void) updateWithRelativeZoomScale:(CGFloat)newRelativeZoomScale;
- (void) updateWithNodeNumberViewIsOverlay:(bool)newNodeNumberViewIsOverlay;
- (void) updateWithTraitCollection:(UITraitCollection*)traitCollection;
//@}

/// @name Calculators
//@{
- (CGPoint) cellRectOriginFromPosition:(NodeTreeViewCellPosition*)position;
- (NodeTreeViewCellPosition*) positionNear:(CGPoint)coordinates;
- (GoNode*) nodeNear:(CGPoint)coordinates;
- (CGPoint) nodeNumberCellRectOriginFromPosition:(NodeTreeViewCellPosition*)position;
//@}

// -----------------------------------------------------------------------------
/// @name Main properties
// -----------------------------------------------------------------------------
//@{
/// @brief The canvas size. This is a calculated property that depends on the
/// @e abstractCanvasSize, @e condenseMoveNodes and @e absoluteZoomScale
/// properties.
///
/// Clients that use KVO on this property will be triggered after
/// NodeTreeViewMetrics has updated its values to match the new size.
@property(nonatomic, assign) CGSize canvasSize;
/// @brief True if node number labels are displayed, false if not.
///
/// Clients that use KVO on this property will be triggered after
/// NodeTreeViewMetrics has updated its values to match the new display node
/// numbers value.
///
/// @note nodeTreeViewModel has a property of the same name, which is the master
/// property on which NodeTreeViewMetrics depends. For this reason, clients that
/// require correct values from NodeTreeViewMetrics must ***NOT*** use KVO on
/// the nodeTreeViewModel property.
@property(nonatomic, assign) bool displayNodeNumbers;
//@}

// -----------------------------------------------------------------------------
/// @name Properties that @e canvasSize depends on
// -----------------------------------------------------------------------------
//@{
@property(nonatomic, assign) CGSize abstractCanvasSize;
@property(nonatomic, assign) bool condenseMoveNodes;
@property(nonatomic, assign) CGFloat absoluteZoomScale;
@property(nonatomic, assign) bool nodeNumberViewIsOverlay;
//@}

// -----------------------------------------------------------------------------
/// @name Properties that depend on main properties
// -----------------------------------------------------------------------------
//@{
/// @brief The size of a single cell in the node tree view. Width and height are
/// different when the move nodes are displayed condensed. Width and height are
/// the same when move nodes are displayed uncondensed.
@property(nonatomic, assign) CGSize nodeTreeViewCellSize;
/// @brief The size of a multipart cell in the node tree view. Width and height
/// are always the same, regardless of whether move nodes are displayed
/// condensed or uncondensed.
///
/// When move nodes are displayed uncondensed this size is the same as
/// @e nodeTreeViewCellSize because in that scenario there are no multipart
/// cells.
///
/// When move nodes are displayed condensed the width is the width of
/// @e nodeTreeViewCellSize multiplied by @e numberOfCellsOfMultipartCell. The
/// height is the same as the height of @e nodeTreeViewCellSize.
@property(nonatomic, assign) CGSize nodeTreeViewMultipartCellSize;
@property(nonatomic, assign) int nodeNumberStripHeight;
@property(nonatomic, assign) int nodeNumberViewHeight;
/// @brief The size of a single cell in the node number view. The width is
/// equal to the width of @e nodeTreeViewCellSize, the height is equal to
/// @e nodeNumberStripHeight.
@property(nonatomic, assign) CGSize nodeNumberViewCellSize;
/// @brief The size of a multipart cell in the node number view. The width is
/// equal to the width of @e nodeTreeViewMultipartCellSize, the height is equal
/// to @e nodeNumberStripHeight.
@property(nonatomic, assign) CGSize nodeNumberViewMultipartCellSize;
/// @brief The font to use for drawing node number labels. Is @e nil if no
/// suitable font exists for the current metrics.
@property(nonatomic, retain) UIFont* nodeNumberLabelFont;
/// @brief The maximum size required for drawing the widest possible node number
/// label using the current @e nodeNumberLabelFont. Is CGSizeZero if no suitable
/// font exists.
@property(nonatomic, assign) CGSize nodeNumberLabelMaximumSize;
@property(nonatomic, assign) CGFloat topLeftTreeCornerX;
@property(nonatomic, assign) CGFloat topLeftTreeCornerY;
@property(nonatomic, assign) unsigned short topLeftCellX;
@property(nonatomic, assign) unsigned short topLeftCellY;
@property(nonatomic, assign) unsigned short bottomRightCellX;
@property(nonatomic, assign) unsigned short bottomRightCellY;
@property(nonatomic, assign) CGSize condensedNodeSymbolSize;
@property(nonatomic, assign) CGSize uncondensedNodeSymbolSize;
@property(nonatomic, retain) UIFont* singleCharacterNodeSymbolFont;
@property(nonatomic, retain) UIFont* threeCharactersNodeSymbolFont;
@property(nonatomic, retain) UIFont* twoLinesOfCharactersNodeSymbolFont;
//@}

// -----------------------------------------------------------------------------
/// @name Static properties whose values never change
// -----------------------------------------------------------------------------
//@{
/// @brief This is the scaling factor that must be taken into account by layers
/// and drawing methods in order to support Retina displays.
///
/// See the documentation of BoardViewMetrics::contentsScale for details.
@property(nonatomic, assign) CGFloat contentsScale;
@property(nonatomic, assign) CGSize tileSize;
@property(nonatomic, assign) CGFloat minimumAbsoluteZoomScale;
@property(nonatomic, assign) CGFloat maximumAbsoluteZoomScale;
@property(nonatomic, assign) int numberOfCellsOfMultipartCell;
@property(nonatomic, retain) UIColor* normalLineColor;
@property(nonatomic, assign) int normalLineWidth;
@property(nonatomic, retain) UIColor* selectedLineColor;
@property(nonatomic, assign) int selectedLineWidth;
@property(nonatomic, assign) int nodeTreeViewCellBaseSize;
@property(nonatomic, retain) UIColor* selectedNodeColor;
@property(nonatomic, retain) UIColor* nodeSymbolColor;
@property(nonatomic, retain) UIColor* nodeSymbolTextColor;
@property(nonatomic, retain) NSShadow* nodeSymbolTextShadow;
@property(nonatomic, retain) UIColor* nodeNumberTextColor;
@property(nonatomic, retain) NSShadow* nodeNumberTextShadow;
@property(nonatomic, assign) int paddingX;
@property(nonatomic, assign) int paddingY;
//@}

@end
