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
#import "TableViewGridCell.h"
#import "UIColorAdditions.h"

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
@property(retain) NSArray* gridLines;
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
  // b) cellContentDistanceFromEdgeHorizontal
  // c) columnWidth
  // d) cellContentSpacingHorizontal

  UIView* oldGridCellContentView = [self.contentView viewWithTag:GridCellContentViewTag];
  if (oldGridCellContentView)
    [oldGridCellContentView removeFromSuperview];
  GridCellContentView* gridCellContentView = [self gridCellContentView];

  int numberOfColumns = [delegate numberOfColumnsInGridCell:self];
  const int cellEdgePadding = 2 * cellContentDistanceFromEdgeHorizontal;  // padding at the left and at the right edge of the cell
  int numberOfGridLines = numberOfColumns - 1;
  const int gridLinePadding = 2 * cellContentSpacingHorizontal;  // padding on the left and on the right of a grid line
  int totalWidthAvailableForAllColumns = cellContentViewWidth - cellEdgePadding - (numberOfGridLines * gridLinePadding);
  int columnWidth = totalWidthAvailableForAllColumns / numberOfColumns;

  NSMutableArray* gridLines = [NSMutableArray arrayWithCapacity:numberOfGridLines];
  for (int column = 0; column < numberOfColumns; ++column)
  {
    int labelX = cellContentDistanceFromEdgeHorizontal + column * (columnWidth + gridLinePadding);
    int labelY = cellContentDistanceFromEdgeVertical;
    int labelWidth = columnWidth;
    CGRect labelRect = CGRectMake(labelX, labelY, labelWidth, cellContentLabelHeight);
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
    label.text = [delegate gridCell:self textForColumn:column];
    [gridCellContentView addSubview:label];

    // Generate a grid line for all but the first column
    if (column > 0)
    {
      float gridLineX = labelX - cellContentSpacingHorizontal;
      [gridLines addObject:[NSNumber numberWithFloat:gridLineX]];
    }
  }
  gridCellContentView.gridLines = gridLines;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a fully configured instance of
/// GridCellContentView. Configuration includes adding the view as a subview to
/// self.contentView.
// -----------------------------------------------------------------------------
- (GridCellContentView*) gridCellContentView
{
  int cellContentViewHeight = self.contentView.bounds.size.height;
  CGRect gridCellContentViewFrameRect = CGRectMake(0, 0, cellContentViewWidth, cellContentViewHeight);
  GridCellContentView* gridCellContentView = [[GridCellContentView alloc] initWithFrame:gridCellContentViewFrameRect];
  [self.contentView addSubview:gridCellContentView];
  [gridCellContentView release];
  gridCellContentView.tag = GridCellContentViewTag;
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
	return label;
}

@end


@implementation GridCellContentView

@synthesize gridLines;

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
  self.gridLines = nil;
  self.backgroundColor = [UIColor clearColor];
  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GridCellContentView object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gridLines = nil;
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

  for (NSNumber* gridLine in self.gridLines)
  {
    CGFloat gridLineX = [gridLine floatValue];
    CGContextMoveToPoint(context, gridLineX + gHalfPixel, 0);
    CGContextAddLineToPoint(context, gridLineX + gHalfPixel, rect.size.height);
  }

	CGContextStrokePath(context);
}

@end

