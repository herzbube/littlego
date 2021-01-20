// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
#import "ViewLoadResultMessageController.h"
#import "../sgf/SgfUtilities.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "View load result message"
/// table view.
// -----------------------------------------------------------------------------
enum ViewLoadResultMessageTableViewSection
{
  IdentificationSection,
  TextSection,
  ClassificationSection,
  LineAndColumnNumberSection,
  LibraryErrorNumberSection,
  FormattedTextSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the IdentificationSection.
// -----------------------------------------------------------------------------
enum IdentificationSectionItem
{
  MessageIDItem,
  MaxIdentificationSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the TextSection.
// -----------------------------------------------------------------------------
enum TextSectionItem
{
  MessageTextItem,
  MaxTextSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ClassificationSection.
// -----------------------------------------------------------------------------
enum ClassificationSectionItem
{
  MessageTypeItem,
  IsCriticalMessageItem,
  ColorCodeItem,
  MaxClassificationSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LineAndColumnNumberSection.
// -----------------------------------------------------------------------------
enum LineAndColumnNumberSectionItem
{
  LineNumberItem,
  ColumnNumberItem,
  MaxLineAndColumnNumberSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the LibraryErrorNumberSection.
// -----------------------------------------------------------------------------
enum LibraryErrorNumberSectionItem
{
  LibraryErrorNumberItem,
  MaxLibraryErrorNumberSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the FormattedTextSection.
// -----------------------------------------------------------------------------
enum FormattedTextSectionItem
{
  FormattedMessageTextItem,
  MaxFormattedTextSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// ViewLoadResultMessageController.
// -----------------------------------------------------------------------------
@interface ViewLoadResultMessageController()
@property(nonatomic, retain) SGFCMessage* message;
@end


@implementation ViewLoadResultMessageController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a ViewLoadResultMessageController
/// instance of grouped style that is used to view the details of the SGFC
/// message @a message.
// -----------------------------------------------------------------------------
+ (ViewLoadResultMessageController*) controllerWithMessage:(SGFCMessage*)message;
{
  ViewLoadResultMessageController* controller = [[ViewLoadResultMessageController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.message = message;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// ViewLoadResultMessageController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.message = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Message details";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return MaxSection;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  switch (section)
  {
    case IdentificationSection:
      return MaxIdentificationSectionItem;
    case TextSection:
      return MaxTextSectionItem;
    case ClassificationSection:
      return MaxClassificationSectionItem;
    case LineAndColumnNumberSection:
      return MaxLineAndColumnNumberSectionItem;
    case LibraryErrorNumberSection:
      return MaxLibraryErrorNumberSectionItem;
    case FormattedTextSection:
      return MaxFormattedTextSectionItem;
    default:
      assert(0);
      return 0;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  switch (section)
  {
    case IdentificationSection:
      return @"If you no longer want this kind of message to be generated you can disable the message ID in the Smart Game Format preferences. Note: Fatal errors cannot be disabled.";
    case TextSection:
      return @"The message text that describes the problem.";
    case ClassificationSection:
      return @"Message types in ascending order of severity are: Warning, Error, Fatal Error. A critical warning is more severe than a non-critical error. A critical message indicates that the SGF data may be severely damaged.";
    case LineAndColumnNumberSection:
      return @"The number of the line and column in the parsed SGF data that caused the message.";
    case LibraryErrorNumberSection:
      return @"An error number that indicates what went wrong when a standard C library function was invoked. The value 0 (zero) indicates \"no error\", a non-zero value indicates an error. It is VERY unlikely that this can become non-zero.";
    case FormattedTextSection:
      return @"The formatted message text that includes all the information above. If the library error number is non-zero this text should contain a matching error description.";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = nil;

  switch (indexPath.section)
  {
    case IdentificationSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Message ID";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.message.messageID];
      break;
    }
    case TextSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.textLabel.text = self.message.messageText;
      cell.textLabel.numberOfLines = 0;
      break;
    }
    case ClassificationSection:
    {
      switch (indexPath.row)
      {
        case MessageTypeItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Message type";
          switch (self.message.messageType)
          {
            case SGFCMessageTypeFatalError:
            {
              cell.detailTextLabel.text = @"Fatal error";
              break;
            }
            case SGFCMessageTypeError:
            {
              cell.detailTextLabel.text = @"Error";
              break;
            }
            case SGFCMessageTypeWarning:
            {
              cell.detailTextLabel.text = @"Warning";
              break;
            }
            default:
            {
              cell.detailTextLabel.text = @"Unknown";
              break;
            }
          }
          break;
        }
        case IsCriticalMessageItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Is critical message";
          if (self.message.isCriticalMessage)
            cell.detailTextLabel.text = @"Yes";
          else
            cell.detailTextLabel.text = @"No";
          break;
        }
        case ColorCodeItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Color code";
          UIImage* image = [SgfUtilities coloredIndicatorForMessage:self.message];
          UIImageView* accImageView = [[UIImageView alloc] initWithImage:image];
          cell.accessoryView = accImageView;
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case LineAndColumnNumberSection:
    {
      switch (indexPath.row)
      {
        case LineNumberItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Line number";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.message.lineNumber];
          break;
        }
        case ColumnNumberItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Column number";
          cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.message.columnNumber];
          break;
        }
        default:
        {
          assert(0);
          break;
        }
      }
      break;
    }
    case LibraryErrorNumberSection:
    {
      cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
      cell.textLabel.text = @"Library error number";
      cell.detailTextLabel.text = [NSString stringWithFormat:@"%ld", (long)self.message.libraryErrorNumber];
      break;
    }
    case FormattedTextSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
      cell.textLabel.text = self.message.formattedMessageText;
      cell.textLabel.numberOfLines = 0;
      break;
    }
    default:
    {
      assert(0);
      break;
    }
  }

  cell.accessoryType = UITableViewCellAccessoryNone;
  cell.selectionStyle = UITableViewCellSelectionStyleNone;

  return cell;
}

@end
