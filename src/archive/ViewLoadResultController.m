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
#import "ViewLoadResultController.h"
#import "ViewLoadResultMessageController.h"
#import "../sgf/SgfUtilities.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiUtilities.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "View load result" table
/// view.
// -----------------------------------------------------------------------------
enum ViewLoadResultTableViewSection
{
  FatalErrorsSection,
  CriticalWarningsAndErrorsSection,
  NonCriticalWarningsAndErrorsSection,
  MaxSection
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for ViewLoadResultController.
// -----------------------------------------------------------------------------
@interface ViewLoadResultController()
@property(nonatomic, retain) NSDictionary* sectionMappings;
@property(nonatomic, retain) NSArray* fatalErrors;
@property(nonatomic, retain) NSArray* criticalWarningsAndErrors;
@property(nonatomic, retain) NSArray* nonCriticalWarningsAndErrors;
@end


@implementation ViewLoadResultController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a ViewLoadResultController instance of
/// grouped style that is used to view information associated with
/// @a gameInfoItem.
// -----------------------------------------------------------------------------
+ (ViewLoadResultController*) controllerWithLoadResult:(SGFCDocumentReadResult*)loadResult
{
  ViewLoadResultController* controller = [[ViewLoadResultController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];

    NSMutableDictionary* sectionMappings = [NSMutableDictionary dictionary];
    NSMutableArray* fatalErrors = [NSMutableArray array];
    NSMutableArray* criticalWarningsAndErrors = [NSMutableArray array];
    NSMutableArray* nonCriticalWarningsAndErrors = [NSMutableArray array];

    for (SGFCMessage* message in loadResult.parseResult)
    {
      if (message.messageType == SGFCMessageTypeFatalError)
        [fatalErrors addObject:message];
      else if (message.isCriticalMessage)
        [criticalWarningsAndErrors addObject:message];
      else
        [nonCriticalWarningsAndErrors addObject:message];
    }

    NSUInteger section = 0;
    if (fatalErrors.count > 0)
      sectionMappings[@(section++)] = @(FatalErrorsSection);
    if (criticalWarningsAndErrors.count > 0)
      sectionMappings[@(section++)] = @(CriticalWarningsAndErrorsSection);
    if (nonCriticalWarningsAndErrors.count > 0)
      sectionMappings[@(section++)] = @(NonCriticalWarningsAndErrorsSection);

    controller.sectionMappings = sectionMappings;
    controller.fatalErrors = fatalErrors;
    controller.criticalWarningsAndErrors = criticalWarningsAndErrors;
    controller.nonCriticalWarningsAndErrors = nonCriticalWarningsAndErrors;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this ViewLoadResultController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.sectionMappings = nil;
  self.fatalErrors = nil;
  self.criticalWarningsAndErrors = nil;
  self.nonCriticalWarningsAndErrors = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Load result details";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return self.sectionMappings.count;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  section = [(NSNumber*)self.sectionMappings[@(section)] intValue];
  switch (section)
  {
    case FatalErrorsSection:
      return self.fatalErrors.count;
    case CriticalWarningsAndErrorsSection:
      return self.criticalWarningsAndErrors.count;
    case NonCriticalWarningsAndErrorsSection:
      return self.nonCriticalWarningsAndErrors.count;
    default:
      assert(0);
      return 0;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  section = [(NSNumber*)self.sectionMappings[@(section)] intValue];
  switch (section)
  {
    case FatalErrorsSection:
      return @"Fatal errors";
    case CriticalWarningsAndErrorsSection:
      return @"Critical warnings and errors";
    case NonCriticalWarningsAndErrorsSection:
      return @"Non-critical warnings and errors";
    default:
      assert(0);
      return nil;
  }
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  SGFCMessage* message = [self messageForIndexPath:indexPath];

  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  cell.textLabel.text = message.messageText;
  cell.textLabel.numberOfLines = 0;
  cell.imageView.image = [SgfUtilities coloredIndicatorForMessage:message];

  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  SGFCMessage* message = [self messageForIndexPath:indexPath];
  ViewLoadResultMessageController* viewLoadResultMessageController = [ViewLoadResultMessageController controllerWithMessage:message];
  [self.navigationController pushViewController:viewLoadResultMessageController animated:YES];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns the SGFCMessage object that is displayed at table view
/// position @a indexPath.
// -----------------------------------------------------------------------------
- (SGFCMessage*) messageForIndexPath:(NSIndexPath*)indexPath
{
  NSUInteger section = [(NSNumber*)self.sectionMappings[@(indexPath.section)] intValue];
  switch (section)
  {
    case FatalErrorsSection:
      return [self.fatalErrors objectAtIndex:indexPath.row];
    case CriticalWarningsAndErrorsSection:
      return [self.criticalWarningsAndErrors objectAtIndex:indexPath.row];
    case NonCriticalWarningsAndErrorsSection:
      return [self.nonCriticalWarningsAndErrors objectAtIndex:indexPath.row];
    default:
      assert(0);
      return nil;
  }
}

@end
