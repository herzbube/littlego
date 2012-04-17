// -----------------------------------------------------------------------------
// Copyright 2011-2012 Patrick Näf (herzbube@herzbube.ch)
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
#import "TableViewGridCell.h"
#import "UIColorAdditions.h"
#import "UiElementMetrics.h"

// Forward declarations
@class GridCellContentView;


// -----------------------------------------------------------------------------
/// @brief Enumerates tags of subviews of TableViewGridCell.
// -----------------------------------------------------------------------------
enum GridCellSubViewTag
{
  GridCellContentViewTag = 1  ///< @brief Tag 0 must not be used, it is the default tag used for all framework-created views (e.g. the cell's content view)
};


// A very light gray which is supposed to match the color of separators that
// UITableView draws between rows.
static NSString* gridLineColor = @"A9ABAD";


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for TableViewGridCell.
// -----------------------------------------------------------------------------
@interface TableViewGridCell()
/// @name Initialization and deallocation
//@{
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier;
- (void) dealloc;
//@}
/// @name Private helpers
//@{
- (GridCellContentView*) gridCellContentView;
+ (UILabel*) valueLabelWithFrame:(CGRect)frame;
+ (UILabel*) titleLabelWithFrame:(CGRect)frame;
//@}
//@}
@end


// -----------------------------------------------------------------------------
/// @brief Helper view used to draw vertical grid lines.
// -----------------------------------------------------------------------------
@interface GridCellContentView : UIView
{
}
- (id) initWithFrame:(CGRect)frame;
- (void) dealloc;
- (void) drawRect:(CGRect)rect;
@property(nonatomic, assign) int numberOfColumns;
@end


@implementation TableViewGridCell

@synthesize delegate;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a TableViewGridCell instance
/// with reuse identifier @a reuseIdentifier.
// -----------------------------------------------------------------------------
+ (TableViewGridCell*) cellWithReuseIdentifier:(NSString*)reuseIdentifier
{
  TableViewGridCell* cell = [[TableViewGridCell alloc] initWithReuseIdentifier:reuseIdentifier];
  if (cell)
    [cell autorelease];
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewGridCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewGridCell.
// -----------------------------------------------------------------------------
- (id) initWithReuseIdentifier:(NSString*)reuseIdentifier
{
  // Call designated initializer of superclass (UITableViewCell)
  self = [super initWithStyle:UITableViewCellStyleDefault
              reuseIdentifier:reuseIdentifier];
  if (! self)
    return nil;
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this TableViewGridCell object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Sets up the content of this TableViewGridCell by querying the
/// delegate.
///
/// This method may be invoked repeatedly, e.g. for a cell that is being reused.
// -----------------------------------------------------------------------------
- (void) setupCellContent
{
  //  1     2                       3                       3                       2     1
  //  |<--->|<---><-----------><--->|<---><-----------><--->|<---><-----------><--->|<--->|
  //    (a)   (b)      (c)      (d)   (d)      (c)      (d)   (d)      (c)      (b)   (a)
  //
  // 1) Screen edge / table view border
  // 2) Cell border
  // 3) Grid line
  //
  // a) self.indentationWidth
  // b) [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal]
  // c) columnWidth
  // d) [UiElementMetrics spacingHorizontal]

  // Remove the old content view, 
  UIView* oldGridCellContentView = [self.contentView viewWithTag:GridCellContentViewTag];
  if (oldGridCellContentView)
    [oldGridCellContentView removeFromSuperview];
  GridCellContentView* gridCellContentView = [self gridCellContentView];

  int numberOfColumns = [delegate numberOfColumnsInGridCell:self];
  int numberOfGridLines = numberOfColumns - 1;
  const int gridLinePadding = 2 * [UiElementMetrics spacingHorizontal];  // padding on the left and on the right of a grid line
  int totalWidthAvailableForAllColumns = (gridCellContentView.bounds.size.width
                                          - 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal]
                                          - (numberOfGridLines * gridLinePadding));
  int columnWidth = totalWidthAvailableForAllColumns / numberOfColumns;

  gridCellContentView.numberOfColumns = numberOfColumns;

  for (int column = 0; column < numberOfColumns; ++column)
  {
    int labelX = [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal] + column * (columnWidth + gridLinePadding);
    int labelY = [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
    int labelWidth = columnWidth;
    CGRect labelRect = CGRectMake(labelX, labelY, labelWidth, [UiElementMetrics labelHeight]);
    UILabel* label = nil;
    enum GridCellColumnStyle columnStyle = [delegate gridCell:self styleInColumn:column];
    switch (columnStyle)
    {
      case ValueGridCellColumnStyle:
      {
        label = [TableViewGridCell valueLabelWithFrame:labelRect];
        break;
      }
      case TitleGridCellColumnStyle:
      {
        label = [TableViewGridCell titleLabelWithFrame:labelRect];
        break;
      }
      default:
      {
        assert(0);
        continue;
      }
    }

    label.tag = GridCellContentViewTag + column + 1;
    if (0 == column)
    {
      // Left label
      label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleRightMargin);
    }
    else if (numberOfColumns == (column + 1))
    {
      // Right label
      label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin);
    }
    else
    {
      // In-between labels
      label.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin);
    }

    label.text = [delegate gridCell:self textForColumn:column];
    [gridCellContentView addSubview:label];
  }
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a fully configured instance of
/// GridCellContentView. Configuration includes adding the view as a subview to
/// self.contentView.
// -----------------------------------------------------------------------------
- (GridCellContentView*) gridCellContentView
{
  CGRect gridCellContentViewFrameRect = self.contentView.bounds;
  GridCellContentView* gridCellContentView = [[GridCellContentView alloc] initWithFrame:gridCellContentViewFrameRect];
  [self.contentView addSubview:gridCellContentView];
  [gridCellContentView release];
  gridCellContentView.tag = GridCellContentViewTag;
  gridCellContentView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
  return gridCellContentView;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a value label with initial frame @a frame.
// -----------------------------------------------------------------------------
+ (UILabel*) valueLabelWithFrame:(CGRect)frame
{
	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.textColor = [UIColor slateBlueColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];
	label.backgroundColor = [UIColor clearColor];
	return label;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a title label with initial frame @a frame.
// -----------------------------------------------------------------------------
+ (UILabel*) titleLabelWithFrame:(CGRect)frame
{
	UILabel* label = [[[UILabel alloc] initWithFrame:frame] autorelease];
	label.textColor = [UIColor blackColor];
	label.textAlignment = UITextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	label.backgroundColor = [UIColor clearColor];
  label.autoresizingMask = UIViewAutoresizingFlexibleWidth;
	return label;
}

@end


@implementation GridCellContentView

@synthesize numberOfColumns;


// -----------------------------------------------------------------------------
/// @brief Initializes a TableViewGridCell object with reuse identifier
/// @a reuseIdentifier.
///
/// @note This is the designated initializer of TableViewGridCell.
// -----------------------------------------------------------------------------
- (id) initWithFrame:(CGRect)frame
{
  // Call designated initializer of superclass (UIView)
  self = [super initWithFrame:frame];
  if (! self)
    return nil;
  self.numberOfColumns = 0;
  self.backgroundColor = [UIColor clearColor];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridCellContentView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Is invoked by UIKit when the view needs updating.
// -----------------------------------------------------------------------------
- (void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGContextSetLineWidth(context, 1.0);
	CGContextSetStrokeColorWithColor(context, [UIColor colorFromHexString:gridLineColor].CGColor);

  // The following iteration must take into account that the original label
  // frames have changed due to resizing, so it can't use the same fixed
  // width calculations as in TableViewGridCell::setupCellContent()
  CGFloat rightEdgeOfPreviousLabel = 0;
  for (int column = 0; column < numberOfColumns; ++column)
  {
    int labelTag = GridCellContentViewTag + column + 1;
    UIView* label = [self viewWithTag:labelTag];
    // Generate a grid line for all but the first column
    if (column > 0)
    {
      CGFloat leftEdgeOfCurrentLabel = label.frame.origin.x;
      CGFloat halfDistanceBetweenLabels = (leftEdgeOfCurrentLabel - rightEdgeOfPreviousLabel) / 2;
      int gridLineX = floor(rightEdgeOfPreviousLabel + halfDistanceBetweenLabels);
      CGContextMoveToPoint(context, gridLineX + gHalfPixel, 0);
      CGContextAddLineToPoint(context, gridLineX + gHalfPixel, rect.size.height);
    }
    rightEdgeOfPreviousLabel = label.frame.origin.x + label.frame.size.width;
  }

	CGContextStrokePath(context);
}

@end

