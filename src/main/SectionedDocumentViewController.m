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
#import "SectionedDocumentViewController.h"
#import "ApplicationDelegate.h"
#import "DocumentViewController.h"
#import "MainTabBarController.h"
#import "../utility/DocumentGenerator.h"
#import "../utility/UIColorAdditions.h"
#import "../ui/TableViewCellFactory.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// SectionedDocumentViewController.
// -----------------------------------------------------------------------------
@interface SectionedDocumentViewController()
@property(nonatomic, retain) DocumentGenerator* documentGenerator;
@end


@implementation SectionedDocumentViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this SectionedDocumentViewController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.documentGenerator = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  self.documentGenerator = nil;
}

#pragma mark - Property accessors

// -----------------------------------------------------------------------------
/// @brief Property accessor with lazy initialization.
// -----------------------------------------------------------------------------
- (DocumentGenerator*) documentGenerator
{
  if (_documentGenerator)
    return _documentGenerator;
  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  // Cast is required because NSInteger and int (the underlying type for
  // enums) differ in size in 64-bit. Cast is safe because the tab bar items
  // are designed to match the enumeration.
  enum TabType tabType = (enum TabType)self.contextTabBarItem.tag;
  NSString* resourceName = [appDelegate.tabBarController resourceNameForTabType:tabType];
  NSString* resourceContent = [appDelegate contentOfTextResource:resourceName];
  switch (tabType)
  {
    case TabTypeHelp:
      self.documentGenerator = [[[DocumentGenerator alloc] initWithFileContent:resourceContent] autorelease];
      break;
    default:
      DDLogError(@"%@: Unexpected tab type %d", self, tabType);
      assert(0);
      self.documentGenerator = nil;
  }
  return _documentGenerator;
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return [self.documentGenerator numberOfGroups];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this controller was not made to handle more than pow(2, 31)
  // sections.
  return [self.documentGenerator numberOfSectionsInGroup:(int)section];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this controller was not made to handle more than pow(2, 31)
  // groups.
  return [self.documentGenerator titleForGroup:(int)section];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  UITableViewCell* cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this controller was not made to handle more than pow(2, 31)
  // sections and groups.
  cell.textLabel.text = [self.documentGenerator titleForSection:(int)indexPath.row inGroup:(int)indexPath.section];
  cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
  [self viewSectionAtIndexPath:indexPath];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView willDisplayHeaderView:(UIView*)view forSection:(NSInteger)section
{
  if ([view isKindOfClass:[UITableViewHeaderFooterView class]])
  {
    UITableViewHeaderFooterView* headerFooterView = (UITableViewHeaderFooterView*)view;
    headerFooterView.contentView.backgroundColor = [UIColor blackColor];
    headerFooterView.textLabel.textColor = [UIColor whiteColor];
  }
  else
  {
    DDLogError(@"%@: Header view object %@ has unexpected type %@", self, view, [view class]);
    assert(0);
  }
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Displays DocumentViewController with the content of the section at
/// index position @a sectionIndex.
// -----------------------------------------------------------------------------
- (void) viewSectionAtIndexPath:(NSIndexPath*)indexPath
{
  // Cast is required because NSInteger and int differ in size in 64-bit. Cast
  // is safe because this controller was not made to handle more than pow(2, 31)
  // sections and groups.
  NSString* sectionTitle = [self.documentGenerator titleForSection:(int)indexPath.row inGroup:(int)indexPath.section];
  NSString* sectionContent = [self.documentGenerator contentForSection:(int)indexPath.row inGroup:(int)indexPath.section];
  DocumentViewController* controller = [DocumentViewController controllerWithTitle:sectionTitle htmlString:sectionContent];
  [self.navigationController pushViewController:controller animated:YES];
}

@end
