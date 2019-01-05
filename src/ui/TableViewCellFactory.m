// -----------------------------------------------------------------------------
// Copyright 2011-2016 Patrick Näf (herzbube@herzbube.ch)
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
#import "TableViewSliderCell.h"
#import "TableViewGridCell.h"
#import "TableViewVariableHeightCell.h"


@implementation TableViewCellFactory

// -----------------------------------------------------------------------------
/// @brief Factory method that returns an autoreleased UITableViewCell object
/// for @a tableView, with a style that is appropriate for the requested
/// @a type.
///
/// Invoke this overload if you are satisfied with the default identifier for
/// cell reuse. The default identifier is the string equivalent of the named
/// enumeration value @a type. For instance, the default identifier for
/// #DefaultCellType is "DefaultCellType".
// -----------------------------------------------------------------------------
+ (UITableViewCell*) cellWithType:(enum TableViewCellType)type
                        tableView:(UITableView*)tableView
{
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
    case SliderWithValueLabelCellType:
      cellID = @"SliderWithValueLabelCellType";
      break;
    case SliderWithoutValueLabelCellType:
      cellID = @"SliderWithoutValueLabelCellType";
      break;
    case GridCellType:
      cellID = @"GridCellType";
      break;
    case ActivityIndicatorCellType:
      cellID = @"ActivityIndicatorCellType";
      break;
    case DeleteTextCellType:
      cellID = @"DeleteTextCellType";
      break;
    case VariableHeightCellType:
      cellID = @"VariableHeightCellType";
      break;
    default:
      DDLogError(@"%@: Unexpected cell type %d", self, type);
      assert(0);
      return nil;
  }
  return [TableViewCellFactory cellWithType:type
                                  tableView:tableView
                     reusableCellIdentifier:cellID];
}

// -----------------------------------------------------------------------------
/// @brief Factory method that returns an autoreleased UITableViewCell object
/// for @a tableView, with a style that is appropriate for the requested
/// @a type.
///
/// Invoke this overload if you want to specify a custom @a identifier for
/// cell reuse.
// -----------------------------------------------------------------------------
+ (UITableViewCell*) cellWithType:(enum TableViewCellType)type
                        tableView:(UITableView*)tableView
           reusableCellIdentifier:(NSString*)identifier;

{
  // UITableView does the caching for us
  UITableViewCell* cell = [tableView dequeueReusableCellWithIdentifier:identifier];
  if (cell != nil)
    return cell;

  // Create the (autoreleased) cell object
  switch (type)
  {
    case SliderWithValueLabelCellType:
    {
      cell = [TableViewSliderCell cellWithReuseIdentifier:identifier valueLabelHidden:false];
      break;
    }
    case SliderWithoutValueLabelCellType:
    {
      cell = [TableViewSliderCell cellWithReuseIdentifier:identifier valueLabelHidden:true];
      break;
    }
    case GridCellType:
    {
      cell = [TableViewGridCell cellWithReuseIdentifier:identifier];
      break;
    }
    case VariableHeightCellType:
    {
      cell = [TableViewVariableHeightCell cellWithReuseIdentifier:identifier];
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
                                     reuseIdentifier:identifier] autorelease];
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
    case DeleteTextCellType:
    {
      cell.textLabel.textColor = [UIColor redColor];
      cell.textLabel.textAlignment = NSTextAlignmentCenter;
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
