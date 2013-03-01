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
#import "TableViewCellFactory.h"
#import "TableViewSegmentedCell.h"
#import "TableViewSliderCell.h"
#import "TableViewGridCell.h"
#import "TableViewTextCell.h"
#import "UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"


@implementation TableViewCellFactory


// -----------------------------------------------------------------------------
/// @brief Factory method that returns an autoreleased UITableViewCell object
/// for @a tableView, with a style that is appropriate for the requested
/// @a type.
// -----------------------------------------------------------------------------
+ (UITableViewCell*) cellWithType:(enum TableViewCellType)type tableView:(UITableView*)tableView
{
  // Check whether we can reuse an existing cell object
  NSString* cellID;
  switch (type)
  {
    case DefaultCellType:
      cellID = @"DefaultCellType";
      break;
    case Value1CellType:
      cellID = @"Value1CellType";
      break;
    case Value2CellType:
      cellID = @"Value2CellType";
      break;
    case SubtitleCellType:
      cellID = @"SubtitleCellType";
      break;
    case SwitchCellType:
      cellID = @"SwitchCellType";
      break;
    case TextFieldCellType:
      cellID = @"TextFieldCellType";
      break;
    case SliderCellType:
      cellID = @"SliderCellType";
      break;
    case GridCellType:
      cellID = @"Grid1CellType";
      break;
    case ActivityIndicatorCellType:
      cellID = @"ActivityIndicatorCellType";
      break;
    case RedButtonCellType:
      cellID = @"RedButtonCellType";
      break;
    case SegmentedCellType:
      cellID = @"SegmentedCellType";
      break;
    default:
      DDLogError(@"%@: Unexpected cell type %d", self, type);
      assert(0);
      return nil;
  }
  // UITableView does the caching for us
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:cellID];
  if (cell != nil)
    return cell;

  // Create the (autoreleased) cell object
  switch (type)
  {
    case SliderCellType:
    {
      cell = [TableViewSliderCell cellWithReuseIdentifier:cellID];
      break;
    }
    case GridCellType:
    {
      cell = [TableViewGridCell cellWithReuseIdentifier:cellID];
      break;
    }
    case TextFieldCellType:
    {
      cell = [TableViewTextCell cellWithReuseIdentifier:cellID];
      break;
    }
    case SegmentedCellType:
    {
      cell = [TableViewSegmentedCell cellWithReuseIdentifier:cellID];
      break;
    }
    default:
    {
      UITableViewCellStyle cellStyle;
      switch (type)
      {
        case Value1CellType:
          cellStyle = UITableViewCellStyleValue1;
          break;
        case Value2CellType:
          cellStyle = UITableViewCellStyleValue2;
          break;
        case SubtitleCellType:
          cellStyle = UITableViewCellStyleSubtitle;
          break;
        default:
          cellStyle = UITableViewCellStyleDefault;
          break;
      }
      cell = [[[UITableViewCell alloc] initWithStyle:cellStyle
                                     reuseIdentifier:cellID] autorelease];
      break;
    }
  }

  // Additional customization
  switch (type)
  {
    case SwitchCellType:
    {
      // UISwitch ignores the frame, so we can conveniently use CGRectZero here
      UISwitch* accessoryViewSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
      cell.accessoryView = accessoryViewSwitch;
      [accessoryViewSwitch release];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      break;
    }
    case ActivityIndicatorCellType:
    {
      UIActivityIndicatorView* accessoryViewActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
      cell.accessoryView = accessoryViewActivityIndicator;
      [accessoryViewActivityIndicator release];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      break;
    }
    case RedButtonCellType:
    {
      // Source for the stuff we are doing here:
      // http://stackoverflow.com/questions/1076785/uibutton-in-uitableview-cell-like-delete-event
      cell.backgroundView = [UiUtilities redButtonTableViewCellBackground:false];
      cell.selectedBackgroundView = [UiUtilities redButtonTableViewCellBackground:true];
      // Make background views visible
      cell.textLabel.backgroundColor = [UIColor clearColor];
      // It's a button, so we want centered text
      cell.textLabel.textAlignment = UITextAlignmentCenter;
      // Contrast against the red background
      cell.textLabel.textColor = [UIColor whiteColor];
      // Gives the text a slightly embossed effect so it looks more like the
      // native button
      cell.textLabel.shadowColor = [UIColor blackColor];
      cell.textLabel.shadowOffset = CGSizeMake(0, -1);
      break;
    }
    default:
    {
      cell.accessoryType = UITableViewCellAccessoryNone;
      break;
    }
  }

  // Return the finished product
  return cell;
}

@end
