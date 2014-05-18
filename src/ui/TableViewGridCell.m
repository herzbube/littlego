// -----------------------------------------------------------------------------
// Copyright 2011-2014 Patrick Näf (herzbube@herzbube.ch)
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
#import "AutoLayoutUtility.h"

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


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// TableViewGridCell.
// -----------------------------------------------------------------------------
@interface TableViewGridCell()
@property(nonatomic, retain) NSArray* constraintsXXX;
@end


@implementation TableViewGridCell

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
///
/// TODO: Reused cells should have the same layout. Invoke
/// numberOfColumnsInGridCell:() only for cells with different reuse
/// identifiers.
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
  // a) self.indentationWidth * self.indentationLevel
  // b) [AutoLayoutUtility horizontalSpacingTableViewCell]
  // c) columnWidth
  // d) [AutoLayoutUtility horizontalSpacingSiblings] / 2

  // Remove the old content view and constraints
  UIView* oldGridCellContentView = [self.contentView viewWithTag:GridCellContentViewTag];
  if (oldGridCellContentView)
    [oldGridCellContentView removeFromSuperview];
  for (id constraint in self.contentView.constraints)
    [self.contentView removeConstraint:constraint];

  GridCellContentView* gridCellContentView = [self gridCellContentView];
  [self.contentView addSubview:gridCellContentView];
  gridCellContentView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.contentView withSubview:gridCellContentView];

  int numberOfColumns = [self.delegate numberOfColumnsInGridCell:self];
  gridCellContentView.numberOfColumns = numberOfColumns;

  NSMutableDictionary* viewsDictionary = [NSMutableDictionary dictionaryWithCapacity:0];
  NSMutableArray* visualFormats = [NSMutableArray arrayWithCapacity:0];

  // The final horizontal visual format line looks like this:
  //   H:|-%f-[label0]-%f-[label1(==label0)]-%f-[label2(==label)]-%f-|
  // The vertical visual format line for all labels looks like this:
  //   V:|-%f-[label<column>]-%f-|"
  const CGFloat indentation = self.indentationWidth * self.indentationLevel;
  const CGFloat cellPadding = indentation + [AutoLayoutUtility horizontalSpacingTableViewCell];  // padding on the left and on the right of a grid line

  NSString* visualFormatHorizontalPrefix = [NSString stringWithFormat:@"H:|-%f-", cellPadding];
  NSString* visualFormatHorizontalSuffix = [NSString stringWithFormat:@"-%f-|", cellPadding];
  NSString* visualFormatHorizontal = visualFormatHorizontalPrefix;
  NSString* visualFormatVerticalTemplate = [NSString stringWithFormat:@"V:|-%f-[%%@]-%f-|", [AutoLayoutUtility verticalSpacingTableViewCell], [AutoLayoutUtility verticalSpacingTableViewCell]];

  NSString* visualFormatReferenceLabelName;
  for (int column = 0; column < numberOfColumns; ++column)
  {
    UILabel* label = nil;
    enum GridCellColumnStyle columnStyle = [self.delegate gridCell:self styleInColumn:column];
    switch (columnStyle)
    {
      case ValueGridCellColumnStyle:
      {
        label = [TableViewGridCell valueLabel];
        break;
      }
      case TitleGridCellColumnStyle:
      {
        label = [TableViewGridCell titleLabel];
        break;
      }
      default:
      {
        DDLogError(@"%@: Unexpected column style %d", self, columnStyle);
        assert(0);
        continue;
      }
    }
    label.tag = GridCellContentViewTag + column + 1;
    label.text = [self.delegate gridCell:self textForColumn:column];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    [gridCellContentView addSubview:label];

    NSString* visualFormatLabelName = [NSString stringWithFormat:@"label%d", column];
    NSString* visualFormatLabelHorizontal;
    if (0 == column)
    {
      visualFormatLabelHorizontal = [NSString stringWithFormat:@"[%@]", visualFormatLabelName];
      visualFormatReferenceLabelName = visualFormatLabelName;
    }
    else
    {
      visualFormatLabelHorizontal = [NSString stringWithFormat:@"-%f-[%@(==%@)]", [AutoLayoutUtility horizontalSpacingSiblings], visualFormatLabelName, visualFormatReferenceLabelName];
    }
    visualFormatHorizontal = [visualFormatHorizontal stringByAppendingString:visualFormatLabelHorizontal];
    [viewsDictionary setObject:label forKey:visualFormatLabelName];
    [visualFormats addObject:[NSString stringWithFormat:visualFormatVerticalTemplate, visualFormatLabelName]];
  }
  visualFormatHorizontal = [visualFormatHorizontal stringByAppendingString:visualFormatHorizontalSuffix];
  [visualFormats addObject:visualFormatHorizontal];

  [AutoLayoutUtility installVisualFormats:visualFormats withViews:viewsDictionary inView:gridCellContentView];
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns an instance of GridCellContentView.
// -----------------------------------------------------------------------------
- (GridCellContentView*) gridCellContentView
{
  CGRect gridCellContentViewFrameRect = self.contentView.bounds;
  GridCellContentView* gridCellContentView = [[[GridCellContentView alloc] initWithFrame:gridCellContentViewFrameRect] autorelease];
  gridCellContentView.tag = GridCellContentViewTag;
  return gridCellContentView;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a value label with initial frame of size zero.
// -----------------------------------------------------------------------------
+ (UILabel*) valueLabel
{
	UILabel* label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
  label.textColor = [UIColor tableViewCellDetailTextLabelColor];
	label.textAlignment = NSTextAlignmentCenter;
	return label;
}

// -----------------------------------------------------------------------------
/// @brief Creates and returns a title label with initial frame of size zero.
// -----------------------------------------------------------------------------
+ (UILabel*) titleLabel
{
	UILabel* label = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	label.textAlignment = NSTextAlignmentCenter;
	label.font = [UIFont boldSystemFontOfSize:[UIFont labelFontSize]];
	return label;
}

@end


@implementation GridCellContentView

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
  for (int column = 0; column < self.numberOfColumns; ++column)
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

