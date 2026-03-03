// -----------------------------------------------------------------------------
// Copyright 2011-2024 Patrick Näf (herzbube@herzbube.ch)
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
#import "GameInfoViewController.h"
#import "delegate/GameInfoViewBoardTabDelegate.h"
#import "delegate/GameInfoViewGameTabDelegate.h"
#import "delegate/GameInfoViewScoreTabDelegate.h"
#import "../model/BoardViewModel.h"
#import "../../main/ModelProvider.h"
#import "../../main/Registry.h"
#import "../../ui/AutoLayoutUtility.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties and properties for
/// GameInfoViewController.
// -----------------------------------------------------------------------------
@interface GameInfoViewController()
@property(nonatomic, assign) UITableView* tableView;
@property(nonatomic, assign) BoardViewModel* boardViewModel;
@property(nonatomic, retain) NSObject* gameInfoViewTableViewDelegate;
@end


@implementation GameInfoViewController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a GameInfoViewController object.
///
/// @note This is the designated initializer of GameInfoViewController.
// -----------------------------------------------------------------------------
- (id) init
{
  // Call designated initializer of superclass (UIViewController)
  self = [super initWithNibName:nil bundle:nil];
  if (! self)
    return nil;

  [GameInfoViewController postNotificationOnMainThread:gameInfoScreenWillAppear];

  self.gameInfoViewControllerCreator = nil;
  self.tableView = nil;
  self.boardViewModel = [Registry sharedRegistry].modelProvider.boardViewModel;
  self.gameInfoViewTableViewDelegate = nil;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoViewController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  [GameInfoViewController postNotificationOnMainThread:gameInfoScreenDidDisappear];

  self.tableView = nil;
  self.boardViewModel = nil;
  self.gameInfoViewTableViewDelegate = nil;

  [self.gameInfoViewControllerCreator gameInfoViewControllerWillDeallocate:self];
  self.gameInfoViewControllerCreator = nil;

  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) loadView
{
  [super loadView];

  [self setupNavigationBar];
  [self setupTableView];
  [self setupAutoLayoutConstraints];
  [self configureViews];
}

#pragma mark - Private helpers for view setup

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupNavigationBar
{
  UISegmentedControl* segmentedControl = [[[UISegmentedControl alloc] initWithItems:@[@"Score", @"Game", @"Board"]] autorelease];
  segmentedControl.selectedSegmentIndex = self.boardViewModel.infoTypeLastSelected;
  [segmentedControl addTarget:self action:@selector(infoTypeChanged:) forControlEvents:UIControlEventValueChanged];
  self.navigationItem.titleView = segmentedControl;
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupTableView
{
  self.tableView = [[[UITableView alloc] initWithFrame:CGRectZero
                                                 style:UITableViewStyleGrouped] autorelease];
  [self.view addSubview:self.tableView];

  [self updateGameInfoViewTableViewDelegate];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) setupAutoLayoutConstraints
{
  self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
  [AutoLayoutUtility fillSuperview:self.view withSubview:self.tableView];
}

// -----------------------------------------------------------------------------
/// @brief Private helper for loadView.
// -----------------------------------------------------------------------------
- (void) configureViews
{
  self.title = @"Game Info";
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Info Type" segmented control. Updates
/// the main table view to display information for the selected type.
// -----------------------------------------------------------------------------
- (void) infoTypeChanged:(id)sender
{
  UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
  // Cast is required because NSInteger and int (the type underlying enums)
  // differ in size in 64-bit. Cast is safe because the segments are designed
  // to match the enumeration.
  self.boardViewModel.infoTypeLastSelected = (enum InfoType)segmentedControl.selectedSegmentIndex;

  [self updateGameInfoViewTableViewDelegate];
  [self.tableView reloadData];
}

// -----------------------------------------------------------------------------
/// @brief Posts the notification with the specified name to the global
/// notification center. This method makes sure that the notification is posted
/// synchronously and on the main thread.
// -----------------------------------------------------------------------------
+ (void) postNotificationOnMainThread:(NSString*)notificationName
{
  if ([NSThread currentThread] != [NSThread mainThread])
  {
    [self performSelectorOnMainThread:@selector(postNotificationOnMainThread:)
                           withObject:notificationName
                        waitUntilDone:YES];
    return;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil];
}

// -----------------------------------------------------------------------------
/// @brief Updates the delegate and data source of the table view, based on
/// the last selected info type.
// -----------------------------------------------------------------------------
- (void) updateGameInfoViewTableViewDelegate
{
  switch (self.boardViewModel.infoTypeLastSelected)
  {
    case ScoreInfoType:
    {
      GameInfoViewScoreTabDelegate* delegate = [[[GameInfoViewScoreTabDelegate alloc] initWithPresentingViewController:self
                                                                                                             tableView:self.tableView] autorelease];
      self.tableView.delegate = delegate;
      self.tableView.dataSource = delegate;
      self.gameInfoViewTableViewDelegate = delegate;
      break;
    }
    case GameInfoType:
    {
      GameInfoViewGameTabDelegate* delegate = [[[GameInfoViewGameTabDelegate alloc] initWithPresentingViewController:self
                                                                                                           tableView:self.tableView] autorelease];
      self.tableView.delegate = delegate;
      self.tableView.dataSource = delegate;
      self.gameInfoViewTableViewDelegate = delegate;
      break;
    }
    case BoardInfoType:
    {
      GameInfoViewBoardTabDelegate* delegate = [[[GameInfoViewBoardTabDelegate alloc] init] autorelease];
      self.tableView.delegate = delegate;
      self.tableView.dataSource = delegate;
      self.gameInfoViewTableViewDelegate = delegate;
      break;
    }
    default:
    {
      assert(0);
      self.tableView.delegate = nil;
      self.tableView.dataSource = nil;
      self.gameInfoViewTableViewDelegate = nil;
      break;
    }
  }
}

@end
