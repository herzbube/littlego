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
#import "TableViewCellFactory.h"
#import "TableViewSliderCell.h"
#import "TableViewGridCell.h"
#import "UiElementMetrics.h"
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
    default:
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
    case TextFieldCellType:
    {
      // The content view at this time (i.e. after construction) is always
      // sized 320x44, even on iPad or iPhone/landscape. The "trick" for
      // proper size adjustment of subviews is to blithely use the content
      // view's size and let the autoresizingMask do the work for us. This
      // works even though the contentView currently has autoresizingMask == 0.
      // It's not clear who actually performs the size adjustment (we can
      // guess: the UITableView), but it works, even on orientation changes.
      // The "brute-force" or "do-it-yourself" alternative is to subclass
      // UITableViewCell and override layoutSubviews().
      CGRect textFieldFrame = cell.contentView.bounds;
      textFieldFrame = CGRectInset(textFieldFrame,
                                   [UiElementMetrics tableViewCellContentDistanceFromEdgeHorizontal],
                                   [UiElementMetrics tableViewCellContentDistanceFromEdgeVertical]);
      UITextField* textField = [[[UITextField alloc] initWithFrame:textFieldFrame] autorelease];
      [cell.contentView addSubview:textField];
      textField.textColor = [UIColor slateBlueColor];
      textField.autoresizingMask = UIViewAutoresizingFlexibleWidth;
      textField.clearButtonMode = UITextFieldViewModeWhileEditing;
      // Make the text field identifiable so that clients can get at it by
      // sending "viewWithTag:" to the cell
      textField.tag = TextFieldCellTextFieldTag;
      // Properties from the UITextInputTraits protocol
      textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
      textField.autocorrectionType = UITextAutocorrectionTypeNo;
      textField.enablesReturnKeyAutomatically = YES;
      // The cell should never appear selected, instead we want the text field
      // to become active when the cell is tapped
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
