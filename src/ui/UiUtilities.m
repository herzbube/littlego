// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "UiUtilities.h"
#import "UiElementMetrics.h"
#import "../utility/UIColorAdditions.h"
#import "../utility/UIImageAdditions.h"

// System includes
#import <QuartzCore/QuartzCore.h>


@implementation UiUtilities

// -----------------------------------------------------------------------------
/// @brief Converts @a degrees into the corresponding radians value.
///
/// Radians are often used by Core Graphics operations, such as drawing arcs
/// or performing CTM rotations.
// -----------------------------------------------------------------------------
+ (double) radians:(double)degrees
{
  return degrees * M_PI / 180;
}

// -----------------------------------------------------------------------------
/// @brief Calculates the row height for a table view cell of type @a type
/// whose label is about to be displayed containing @a text.
///
/// Supported cell types currently are #DefaultCellType and #SwitchCellType.
///
/// @a hasDisclosureIndicator is true if the cell displays a standard disclosure
/// indicator.
///
/// Assumptions that this method makes:
/// - The cell is not indented, i.e. the cell has the full width of the screen
/// - The label inside the cell uses the default label font and label font size
/// - The label uses NSLineBreakByWordWrapping.
///
/// @note This method is intended to be called from inside a table view
/// delegate's tableView:heightForRowAtIndexPath:().
// -----------------------------------------------------------------------------
+ (CGFloat) tableView:(UITableView*)tableView heightForCellOfType:(enum TableViewCellType)type withText:(NSString*)text hasDisclosureIndicator:(bool)hasDisclosureIndicator
{
  // Calculating the cell height for an empty text results in a value much too
  // small. We therefore return table view's default height for rows
  if (0 == text.length)
    return tableView.rowHeight;

  CGFloat labelWidth;
  switch (type)
  {
    case DefaultCellType:
    {
      // The label has the entire cell width
      labelWidth = [UiElementMetrics tableViewCellContentViewAvailableWidth];
      break;
    }
    case SwitchCellType:
    {
      // The label shares the cell with a UISwitch
      labelWidth = ([UiElementMetrics tableViewCellContentViewAvailableWidth]
                    - [UiElementMetrics switchWidth]
                    - [UiElementMetrics spacingHorizontal]);
      break;
    }
    default:
    {
      DDLogError(@"%@: Unexpected cell type %d", self, type);
      assert(0);
      return tableView.rowHeight;
    }
  }
  if (hasDisclosureIndicator)
    labelWidth -= [UiElementMetrics tableViewCellDisclosureIndicatorWidth];

  UIFont* labelFont = [UIFont systemFontOfSize:[UIFont labelFontSize]];
  CGSize constraintSize = CGSizeMake(labelWidth, MAXFLOAT);
  CGSize labelSize = [text sizeWithFont:labelFont
                      constrainedToSize:constraintSize
                          lineBreakMode:NSLineBreakByWordWrapping];

  return labelSize.height + 2 * [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical];
}

// -----------------------------------------------------------------------------
/// @brief Returns YES for portrait orientations on iPhone, and for all
/// orientations on iPad. Returns NO for all other situations.
///
/// This method implements application-wide orientation support. It can be
/// invoked by all view controllers' implementation of
/// shouldAutorotateToInterfaceOrientation:().
///
/// @note shouldAutorotateToInterfaceOrientation:() is relevant for iOS 5 and
/// earlier.
// -----------------------------------------------------------------------------
+ (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  bool isLandscapeOrientation = UIInterfaceOrientationIsLandscape(interfaceOrientation);
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return isLandscapeOrientation ? NO : YES;
  else
    return YES;
}

// -----------------------------------------------------------------------------
/// @brief Returns the bitmasked value for portrait orientations on iPhone, and
/// for all orientations on iPad.
///
/// This method implements application-wide orientation support. It can be
/// invoked by all view controllers' implementation of
/// supportedInterfaceOrientations().
///
/// @note supportedInterfaceOrientations:() is relevant for iOS 6 and later.
// -----------------------------------------------------------------------------
+ (NSUInteger) supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    return (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown);
  else
    return UIInterfaceOrientationMaskAll;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new UITableView with style @a tableViewStyle, configures
/// @a viewController with the newly created table view, and configures the
/// table view to use the controller as delegate and data source (if the
/// controller adopts the appropriate protocols).
///
/// This method is useful for controllers that do not want to load their view
/// from a .nib file. It is intended to be called from a controller's
/// loadView().
///
/// This method does not invoke reloadData() on the newly created table view.
/// If this method is invoked from the controller's loadView(), and the
/// controller is a UITableViewController, the UITableViewController
/// implementation will automatically trigger data loading. In all other cases,
/// it is the controller's responsibility to trigger data loading at the
/// appropriate time.
// -----------------------------------------------------------------------------
+ (void) createTableViewWithStyle:(UITableViewStyle)tableViewStyle forController:(UIViewController*)viewController
{
  // TODO xxx replace by createTableViewWithStyle:withDelegateAndDataSource
  // the new method uses auto layout and does not set a VC's view property

  UITableView* tableView = [[UITableView alloc] initWithFrame:[UiElementMetrics applicationFrame]
                                                        style:tableViewStyle];

  // Connect controller with view
  // Note: If viewController is a UITableViewController, setting this property
  // automatically sets the controller's tableView property
  viewController.view = tableView;
  [tableView release];

  // Connect view with controller
  if ([viewController conformsToProtocol:@protocol(UITableViewDelegate)])
    tableView.delegate = (id<UITableViewDelegate>)viewController;
  if ([viewController conformsToProtocol:@protocol(UITableViewDataSource)])
    tableView.dataSource = (id<UITableViewDataSource>)viewController;
}

// -----------------------------------------------------------------------------
/// @brief Creates a new UITableView with style @a tableViewStyle, and
/// configures the table view to use the supplied object both as delegate and
/// data source.
// -----------------------------------------------------------------------------
+ (UITableView*) createTableViewWithStyle:(UITableViewStyle)tableViewStyle withDelegateAndDataSource:(id)anObject
{
  UITableView* tableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                         style:tableViewStyle] autorelease];
  tableView.delegate = (id<UITableViewDelegate>)anObject;
  tableView.dataSource = (id<UITableViewDataSource>)anObject;
  return tableView;
}

// -----------------------------------------------------------------------------
/// @brief Adds the same background to @a view that is used by the default
/// group UITableView.
///
/// Since iOS 6 the recommended way how to do this is to add an empty
/// UITableView behind the view's content. This is exactly what this method
/// does (adds an empty table view as subview to @a view and sends the table
/// view to the back). The nice thing is that this works equally well for all
/// devices, and also for older versions of iOS.
// -----------------------------------------------------------------------------
+ (void) addGroupTableViewBackgroundToView:(UIView*)view
{
  UIView* backgroundView = [[[UITableView alloc] initWithFrame:view.bounds style:UITableViewStyleGrouped] autorelease];
  backgroundView.autoresizingMask = (UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
  [view addSubview:backgroundView];
  [view sendSubviewToBack:backgroundView];
}

// -----------------------------------------------------------------------------
/// @brief Setup @a cell, which must be of type #DefaultCellType, to look like
/// a UITextField.
///
/// If @a text is not empty, it is used in the cell's text label. The text label
/// uses the system font for UILabel's, but with bold'ness removed. The text
/// is displayed using the "slate blue" color.
///
/// If @a text is empty, the @a placeholder is used instead to fake the look of
/// a UITextField's placeholder (i.e. non-bold font, light gray text color).
// -----------------------------------------------------------------------------
+ (void) setupDefaultTypeCell:(UITableViewCell*)cell withText:(NSString*)text placeHolder:(NSString*)placeholder
{
  if (text.length > 0)
  {
    cell.textLabel.text = text;
    cell.textLabel.textColor = [UIColor slateBlueColor];
  }
  else
  {
    cell.textLabel.text = placeholder;
    cell.textLabel.textColor = [UIColor lightGrayColor];
  }
  cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
  cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
  cell.textLabel.numberOfLines = 0;
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

// -----------------------------------------------------------------------------
/// @brief Returns an image view that, if applied as the background to a table
/// view cell, makes the cell look like the red delete button in Apple's
/// address book.
///
/// If @a selected is true, the image view represents the button in its selected
/// state, otherwise the image view represents the button in its normal state.
///
/// The concrete colors have been experimentally determined. For details see
/// UiColorAdditions.
// -----------------------------------------------------------------------------
+ (UIImageView*) redButtonTableViewCellBackground:(bool)selected
{
  CGSize backgroundPatternSize = CGSizeMake([UiElementMetrics tableViewCellContentViewWidth],
                                            [UiElementMetrics tableViewCellContentViewHeight]);
  NSArray* colors;
  if (selected)
    colors = [UIColor redButtonTableViewCellSelectedBackgroundGradientColors];
  else
    colors = [UIColor redButtonTableViewCellBackgroundGradientColors];
  UIImage* backgroundPattern = [UIImage gradientImageWithSize:backgroundPatternSize
                                                  startColor1:[colors objectAtIndex:0]
                                                    endColor1:[colors objectAtIndex:1]
                                                  startColor2:[colors objectAtIndex:2]
                                                    endColor2:[colors objectAtIndex:3]];
  UIImageView* imageView = [[UIImageView alloc] initWithImage:backgroundPattern];
  [[imageView layer] setCornerRadius:8.0f];
  [[imageView layer] setMasksToBounds:YES];
  [[imageView layer] setBorderWidth:1.0f];
  [[imageView layer] setBorderColor: [[UIColor grayColor] CGColor]];
  return [imageView autorelease];
}

// -----------------------------------------------------------------------------
/// @brief Draws a linear gradient along the axis that runs from the top-middle
/// to the bottom-middle point of @a rect.
///
/// The code for this method is based on
/// http://www.raywenderlich.com/2033/core-graphics-101-lines-rectangles-and-gradients
// -----------------------------------------------------------------------------
+ (void) drawLinearGradientWithContext:(CGContextRef)context rect:(CGRect)rect startColor:(CGColorRef)startColor endColor:(CGColorRef)endColor
{
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

  CGFloat locations[] = { 0.0, 1.0 };
  NSArray* colors = [NSArray arrayWithObjects:(id)startColor, (id)endColor, nil];
  // NSArray is toll-free bridged, so we can simply cast to CGArrayRef
  CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                      (CFArrayRef)colors,
                                                      locations);

  // Draw the gradient from top-middle to bottom-middle
  CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
  CGPoint endPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

  // Remember context so that later on we can undo the clipping we are going to
  // add to the Core Graphics state machine
  CGContextSaveGState(context);
  // Add clipping with the specified rect so that we can simply draw into the
  // specified context without changing anything outside of the rect. With this
  // approach, the caller can give us a context that already has other stuff
  // in it
  CGContextAddRect(context, rect);
  CGContextClip(context);
  // Finally draw the gradient
  CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
  // Undo clipping
  CGContextRestoreGState(context);

  // Cleanup memory allocated by CGContextDrawLinearGradient()
  CGGradientRelease(gradient);
  // Cleanup memory allocated by CGColorSpaceCreateDeviceRGB()
  CGColorSpaceRelease(colorSpace);
}

// -----------------------------------------------------------------------------
/// @brief Captures the content currently drawn by @a view into an image, then
/// returns that image.
///
/// The code for this method is based on
/// http://stackoverflow.com/questions/2200736/how-to-take-a-screenshot-programmatically
///
/// Keyword for search: screenshot
// -----------------------------------------------------------------------------
+ (UIImage*) captureView:(UIView*)view
{
  UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO, [UIScreen mainScreen].scale);
  [view.layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage* imageCapture = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return imageCapture;
}

// -----------------------------------------------------------------------------
/// @brief Draws a rectangle that fully fits into the box @a rect.
///
/// If @a fill is true the rectangle is filled, otherwise it is stroked using a
/// solid line and line width 1.
///
/// @a color is used as fill or stroke color.
///
/// @note It is the responsibility of the caller to provide half-pixel
/// translation to prevent anti-aliasing (should be necessary only if @a fill
/// is false).
// -----------------------------------------------------------------------------
+ (void) drawRectWithContext:(CGContextRef)context rect:(CGRect)rect fill:(bool)fill color:(UIColor*)color
{
  if (! fill)
  {
    // Adjust rectangle size so that all lines are drawn fully inside the
    // rectangle. If this adjustment is not done, the stroke of the upper/right
    // edge will be 1 pixel outside the rectangle's bounds. The reason is that
    // CGContextAddRect() uses CGRectMaxX() and CGRectMaxY() to determine the
    // upper/right edge, which will result in points being added to the path
    // that are outside the rectangle's bounds.
    rect.size.width -= 1;
    rect.size.height -= 1;
  }
  else
  {
    // No adjustment necessary for filling, which IMHO is *really* confusing.
    // Let's look at an example: A rectangle of (0,0,10,10) results in a path
    // that contains the points (0,0), (0,11), (11,11) and (11,0). Filling this
    // path results in an area of 10x10 pixels being filled, which is what we
    // want, BUT...
    // - The docs for CGContextFillPath() state that the area *WITHIN* the path
    //   is filled
    // - So why are the pixels at x/y coordinate 0 being filled, but the pixels
    //   at x/y coordinate 11 are not?
    // IMHO either the docs are wrong, or the implementation.
  }

  CGContextBeginPath(context);
  CGContextAddRect(context, rect);

  if (fill)
  {
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
  }
  else
  {
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextStrokePath(context);
  }
}

// -----------------------------------------------------------------------------
/// @brief Draws an arc that is a full circle with its center at @a center and
/// a radius @a radius.
///
/// If @a fill is true the circle is filled, otherwise it is stroked using a
/// solid line and line width 1.
///
/// @a color is used as fill or stroke color.
///
/// The circle that is drawn fits into a rectangle whose width and height are
/// equal to "2 * radius + 1" (the +1 is for the center pixel).
///
/// @note It is the responsibility of the caller to provide half-pixel
/// translation to prevent anti-aliasing.
// -----------------------------------------------------------------------------
+ (void) drawCircleWithContext:(CGContextRef)context center:(CGPoint)center radius:(CGFloat)radius fill:(bool)fill color:(UIColor*)color
{
  const int startRadius = [UiUtilities radians:0];
  const int endRadius = [UiUtilities radians:360];
  const int clockwise = 0;

  CGContextAddArc(context,
                  center.x,
                  center.y,
                  radius,
                  startRadius,
                  endRadius,
                  clockwise);
  if (fill)
  {
    CGContextSetFillColorWithColor(context, color.CGColor);
    CGContextFillPath(context);
  }
  else
  {
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, 1);
    CGContextStrokePath(context);
  }
}

@end
