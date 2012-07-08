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
#import "DiagnosticsViewController.h"
#import "GtpLogViewController.h"
#import "GtpLogSettingsController.h"
#import "GtpCommandViewController.h"
#import "SendBugReportController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Diagnostics" table view.
// -----------------------------------------------------------------------------
enum DiagnosticsTableViewSection
{
  GtpSection,
  BugReportSection,
//  ApplicationLogSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the GtpSection.
// -----------------------------------------------------------------------------
enum GtpSectionItem
{
  GtpLogItem,
  GtpCommandsItem,
  GtpSettingsItem,
  MaxGtpSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the BugReportSection.
// -----------------------------------------------------------------------------
enum BugReportSectionItem
{
  SendBugReportItem,
  GenerateDiagnosticsInformationFileItem,
  MaxBugReportSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ApplicationLogSection.
// -----------------------------------------------------------------------------
enum ApplicationLogSectionItem
{
  ApplicationLogItem,
  ApplicationLogSettingsItem,
  MaxApplicationLogSectionItem
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for DiagnosticsViewController.
// -----------------------------------------------------------------------------
@interface DiagnosticsViewController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) loadView;
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section;
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name Action methods
//@{
- (void) viewGtpLog;
- (void) viewCannedGtpCommands;
- (void) viewGtpSettings;
- (void) sendBugReport;
- (void) generateDiagnosticsInformationFile;
//@}
/// @name Helpers
//@{
//@}
@end


@implementation DiagnosticsViewController


// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this DiagnosticsViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Creates the view that this controller manages.
///
/// This implementation exists because this controller needs a grouped style
/// table view, and there is no simpler way to specify the table view style.
/// - This controller does not load its table view from a .nib file, so the
///   style can't be specified there
/// - This controller is itself loaded from a .nib file, so the style can't be
///   specified in initWithStyle:()
// -----------------------------------------------------------------------------
- (void) loadView
{
  [UiUtilities createTableViewWithStyle:UITableViewStyleGrouped forController:self];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
}

// -----------------------------------------------------------------------------
/// @brief Called when the controller’s view is released from memory, e.g.
/// during low-memory conditions.
///
/// Releases additional objects (e.g. by resetting references to retained
/// objects) that can be easily recreated when viewDidLoad() is invoked again
/// later.
// -----------------------------------------------------------------------------
- (void) viewDidUnload
{
  [super viewDidUnload];
}

// -----------------------------------------------------------------------------
/// @brief Called by UIKit at various times to determine whether this controller
/// supports the given orientation @a interfaceOrientation.
// -----------------------------------------------------------------------------
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
  return [UiUtilities shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

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
    case GtpSection:
      return MaxGtpSectionItem;
    case BugReportSection:
      return MaxBugReportSectionItem;
//    case ApplicationLogSection:
//      return MaxApplicationLogSectionItem;
    default:
      assert(0);
      break;
  }
  return 0;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  switch (section)
  {
    case GtpSection:
      return @"GTP (Go Text Protocol)";
    case BugReportSection:
      return @"Bug Report";
//    case ApplicationLogSection:
//      return @"Application Log";
    default:
      break;
  }
  return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForFooterInSection:(NSInteger)section
{
  if (GtpSection == section)
    return @"Observe the flow of communication between Little Go (GTP client) and Fuego (GTP engine), or inject your own GTP commands (dangerous!).";
  else if (BugReportSection == section)
    return @"Sending a bug report creates an email with an attached diagnostics information file. You can edit the email before you send it. If you want to send the report from your computer, generate just the file and transfer it to your computer via iTunes file sharing.";
  else
    return nil;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  switch (indexPath.section)
  {
    case GtpSection:
    {
      cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
      switch (indexPath.row)
      {
        case GtpLogItem:
          cell.textLabel.text = @"GTP log";
          break;
        case GtpCommandsItem:
          cell.textLabel.text = @"GTP commands";
          break;
        case GtpSettingsItem:
          cell.textLabel.text = @"Settings";
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case BugReportSection:
    {
      switch (indexPath.row)
      {
        case SendBugReportItem:
          cell.textLabel.text = @"Send a bug report";
          cell.accessoryType = UITableViewCellAccessoryNone;
          break;
        case GenerateDiagnosticsInformationFileItem:
          cell.textLabel.text = @"Generate diagnostics information";
          cell.accessoryType = UITableViewCellAccessoryNone;
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
//    case ApplicationLogSection:
//    {
//      switch (indexPath.row)
//      {
//        case ApplicationLogItem:
//          cell.textLabel.text = @"View application log";
//          break;
//        case ApplicationLogSettingsItem:
//          cell.textLabel.text = @"Settings";
//          break;
//        default:
//          assert(0);
//          break;
//      }
//      break;
//    }
    default:
      assert(0);
      break;
  }
  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  switch (indexPath.section)
  {
    case GtpSection:
    {
      switch (indexPath.row)
      {
        case GtpLogItem:
          [self viewGtpLog];
          break;
        case GtpCommandsItem:
          [self viewCannedGtpCommands];
          break;
        case GtpSettingsItem:
          [self viewGtpSettings];
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
    case BugReportSection:
    {
      switch (indexPath.row)
      {
        case SendBugReportItem:
          [self sendBugReport];
          break;
        case GenerateDiagnosticsInformationFileItem:
          [self generateDiagnosticsInformationFile];
          break;
        default:
          assert(0);
          break;
      }
      break;
    }
//    case ApplicationLogSection:
//      break;
    default:
      return;
  }
}

// -----------------------------------------------------------------------------
/// @brief Displays GtpLogViewController to allow the user to view the GTP
/// command/response log.
// -----------------------------------------------------------------------------
- (void) viewGtpLog
{
  GtpLogViewController* controller = [GtpLogViewController controller];
  [self.navigationController pushViewController:controller animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Displays GtpCommandViewController to allow the user to manage canned
/// GTP commands.
// -----------------------------------------------------------------------------
- (void) viewCannedGtpCommands
{
  GtpCommandViewController* controller = [GtpCommandViewController controller];
  [self.navigationController pushViewController:controller animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Displays GtpLogSettingsController to allow the user to view and
/// modify settings related to the GTP command/response log.
// -----------------------------------------------------------------------------
- (void) viewGtpSettings
{
  GtpLogSettingsController* controller = [GtpLogSettingsController controller];
  [self.navigationController pushViewController:controller animated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Triggers the workflow that allows the user to send a bug report email
/// directly from the device.
// -----------------------------------------------------------------------------
- (void) sendBugReport
{
  SendBugReportController* controller = [SendBugReportController controller];
  [controller sendBugReport:self];
  [controller retain];
}

// -----------------------------------------------------------------------------
/// @brief Generates the file with diagnostics information for transfer with
/// iTunes file sharing.
// -----------------------------------------------------------------------------
- (void) generateDiagnosticsInformationFile
{
  SendBugReportController* controller = [SendBugReportController controller];
  [controller generateDiagnosticsInformationFile];
}

@end
