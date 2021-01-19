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
#import "GameInfoItemController.h"
#import "GameInfoItem.h"


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for GameInfoItemController.
// -----------------------------------------------------------------------------
@interface GameInfoItemController()
@property(nonatomic, retain) GameInfoItem* gameInfoItem;
@end


@implementation GameInfoItemController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a GameInfoItemController instance of
/// grouped style that is used to view information associated with
/// @a gameInfoItem.
// -----------------------------------------------------------------------------
+ (GameInfoItemController*) controllerWithGameInfoItem:(GameInfoItem*)gameInfoItem
{
  GameInfoItemController* controller = [[GameInfoItemController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.gameInfoItem = gameInfoItem;
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this GameInfoItemController object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.gameInfoItem = nil;
  [super dealloc];
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.navigationItem.title = @"Game info details";
}

#pragma mark - UITableViewDataSource overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView
{
  return [self.gameInfoItem numberOfSectionsInTableView:tableView detailLevel:GameInfoItemDetailLevelFull];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section
{
  return [self.gameInfoItem tableView:tableView numberOfRowsInSection:section detailLevel:GameInfoItemDetailLevelFull];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (NSString*) tableView:(UITableView*)tableView titleForHeaderInSection:(NSInteger)section
{
  return [self.gameInfoItem tableView:tableView titleForHeaderInSection:section detailLevel:GameInfoItemDetailLevelFull];
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDataSource protocol method.
// -----------------------------------------------------------------------------
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath
{
  return [self.gameInfoItem tableView:tableView cellForRowAtIndexPath:indexPath detailLevel:GameInfoItemDetailLevelFull];
}

@end
