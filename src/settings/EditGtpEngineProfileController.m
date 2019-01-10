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
#import "EditGtpEngineProfileController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/Player.h"
#import "../player/PlayerModel.h"
#import "../shared/LayoutManager.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/UiElementMetrics.h"
#import "../ui/UiUtilities.h"
#import "../utility/UIColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Profile" table view.
// -----------------------------------------------------------------------------
enum EditGtpEngineProfileTableViewSection
{
  ProfileNameSection,
  PlayingStrengthSection,
  ResignBehaviourSection,
  ProfileNotesSection,
  PlayerListSection,
  MaxSection
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileNameSection.
// -----------------------------------------------------------------------------
enum ProfileNameSectionItem
{
  ProfileNameItem,
  MaxProfileNameSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayingStrengthSection.
// -----------------------------------------------------------------------------
enum PlayingStrengthSectionItem
{
  PlayingStrengthItem,
  PlayingStrengthAdvancedConfigurationItem,
  MaxPlayingStrengthSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ResignBehaviourSection.
// -----------------------------------------------------------------------------
enum ResignBehaviourSectionItem
{
  ResignBehaviourItem,
  ResignBehaviourAdvancedConfigurationItem,
  MaxResignBehaviourSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ProfileNotesSection.
// -----------------------------------------------------------------------------
enum ProfileNotesSectionItem
{
  ProfileNotesItem,
  MaxProfileNotesSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayerListSection.
// -----------------------------------------------------------------------------
enum PlayerListSectionItem
{
  MaxPlayerListSectionItem,
};


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController()
@property(nonatomic, retain) NSArray* playersUsingTheProfile;
@end


@implementation EditGtpEngineProfileController

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a EditGtpEngineProfileController
/// instance of grouped style that is used to edit @a profile.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerForProfile:(GtpEngineProfile*)profile withDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = profile;
    controller.profileExists = true;
    [controller setupPlayersUsingTheProfile];
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates an EditGtpEngineProfileController
/// instance of grouped style that is used to create a new GtpEngineProfile
/// object and edit its attributes.
// -----------------------------------------------------------------------------
+ (EditGtpEngineProfileController*) controllerWithDelegate:(id<EditGtpEngineProfileDelegate>)delegate
{
  EditGtpEngineProfileController* controller = [[EditGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = [[[GtpEngineProfile alloc] init] autorelease];
    controller.profile.playingStrength = defaultPlayingStrength;
    controller.profileExists = false;
    [controller setupPlayersUsingTheProfile];
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this EditGtpEngineProfileController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  self.playersUsingTheProfile = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Populates the private property @e playersUsingTheProfile. Is expected
/// to be invoked during initialization.
// -----------------------------------------------------------------------------
- (void) setupPlayersUsingTheProfile
{
  NSMutableArray* playersUsingTheProfile = [NSMutableArray array];
  if (self.profileExists)
  {
    PlayerModel* model = [ApplicationDelegate sharedDelegate].playerModel;
    for (Player* player in model.playerList)
    {
      if ([player gtpEngineProfile] == self.profile)
        [playersUsingTheProfile addObject:player.name];
    }
  }
  self.playersUsingTheProfile = playersUsingTheProfile;
}

#pragma mark - UIViewController overrides

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];
  self.tableView.estimatedRowHeight = [UiElementMetrics tableViewCellSizeForDefaultType].height;

  if (self.profileExists)
  {
    self.navigationItem.title = @"Edit Profile";
    if (self == [self.navigationController.viewControllers objectAtIndex:0])
    {
      // We are the root view controller of the navigation stack, so we are
      // presented modally and need to display a button that allows dismissing
      self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Done"
                                                                                 style:UIBarButtonItemStyleDone
                                                                                target:self
                                                                                action:@selector(done:)] autorelease];
      self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
    }
    else
    {
      self.navigationItem.leftBarButtonItem.enabled = [self isProfileValid];
    }
  }
  else
  {
    self.navigationItem.title = @"New Profile";
    self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                               style:UIBarButtonItemStyleDone
                                                                              target:self
                                                                              action:@selector(create:)] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
}

// -----------------------------------------------------------------------------
/// @brief UIViewController method.
// -----------------------------------------------------------------------------
- (void) viewWillDisappear:(BOOL)animated
{
  [super viewWillDisappear:animated];
  if (self.profile.isActiveProfile && self.profile.hasUnappliedChanges)
    [self.profile applyProfile];
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
    case ProfileNameSection:
      return MaxProfileNameSectionItem;
    case PlayingStrengthSection:
      return MaxPlayingStrengthSectionItem;
    case ResignBehaviourSection:
      return MaxResignBehaviourSectionItem;
    case ProfileNotesSection:
      return MaxProfileNotesSectionItem;
    case PlayerListSection:
      return self.playersUsingTheProfile.count;
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
    case ProfileNameSection:
      return @"Profile name";
    case PlayingStrengthSection:
      return @"Playing strength";
    case ResignBehaviourSection:
      return @"Resign behaviour";
    case ProfileNotesSection:
      return @"Profile notes";
    case PlayerListSection:
      return @"Players using this profile";
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
  switch (section)
  {
    case PlayerListSection:
      if (0 == self.playersUsingTheProfile.count)
        return @"No player uses this profile.";
      break;
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
    case ProfileNameSection:
    {
      switch (indexPath.row)
      {
        case ProfileNameItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.profile.name placeHolder:@"Profile name" textIsRequired:true];
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case PlayingStrengthSection:
    {
      switch (indexPath.row)
      {
        case PlayingStrengthItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Playing strength";
          if (customPlayingStrength == self.profile.playingStrength)
            cell.detailTextLabel.text = @"Custom";
          else
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%d", self.profile.playingStrength];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case PlayingStrengthAdvancedConfigurationItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Advanced configuration";
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case ResignBehaviourSection:
    {
      switch (indexPath.row)
      {
        case ResignBehaviourItem:
        {
          cell = [TableViewCellFactory cellWithType:Value1CellType tableView:tableView];
          cell.textLabel.text = @"Resign behaviour";
          if (customResignBehaviour == self.profile.resignBehaviour)
            cell.detailTextLabel.text = @"Custom";
          else
          {
            cell.detailTextLabel.text = [self resignBehaviourName:self.profile.resignBehaviour];
          }
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        case ResignBehaviourAdvancedConfigurationItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView];
          cell.textLabel.text = @"Advanced configuration";
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case ProfileNotesSection:
    {
      switch (indexPath.row)
      {
        case ProfileNotesItem:
        {
          cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"TextFieldCellType"];
          [UiUtilities setupDefaultTypeCell:cell withText:self.profile.profileDescription placeHolder:@"Profile notes" textIsRequired:false];
          break;
        }
        default:
        {
          assert(0);
          @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
          break;
        }
      }
      break;
    }
    case PlayerListSection:
    {
      cell = [TableViewCellFactory cellWithType:DefaultCellType tableView:tableView reusableCellIdentifier:@"NonSelectableCell"];
      cell.textLabel.text = [self.playersUsingTheProfile objectAtIndex:indexPath.row];
      cell.selectionStyle = UITableViewCellSelectionStyleNone;
      break;
    }
    default:
    {
      assert(0);
      @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"invalid index path %@", indexPath] userInfo:nil];
      break;
    }
  }

  return cell;
}

#pragma mark - UITableViewDelegate overrides

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (ProfileNameSection == indexPath.section)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.name
                                                                               style:EditTextControllerStyleTextField
                                                                            delegate:self] retain];
    editTextController.title = @"Edit name";
    editTextController.acceptEmptyText = false;
    editTextController.context = [NSNumber numberWithInteger:indexPath.section];
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navigationController.delegate = [LayoutManager sharedManager];
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
    [editTextController release];
  }
  else if (PlayingStrengthSection == indexPath.section)
  {
    switch (indexPath.row)
    {
      case PlayingStrengthItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int playingStrength = minimumPlayingStrength; playingStrength <= maximumPlayingStrength; ++playingStrength)
        {
          NSString* playingStrengthString = [NSString stringWithFormat:@"%d", playingStrength];
          [itemList addObject:playingStrengthString];
        }
        int indexOfDefaultPlayingStrength;
        if (customPlayingStrength == self.profile.playingStrength)
          indexOfDefaultPlayingStrength = -1;
        else
          indexOfDefaultPlayingStrength = self.profile.playingStrength - minimumPlayingStrength;
        ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 screenTitle:@"Playing strength"
                                                                          indexOfDefaultItem:indexOfDefaultPlayingStrength
                                                                                    delegate:self];
        modalController.context = [NSNumber numberWithInteger:indexPath.section];
        UINavigationController* navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:modalController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        navigationController.delegate = [LayoutManager sharedManager];
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
        break;
      }
      case PlayingStrengthAdvancedConfigurationItem:
      {
        EditPlayingStrengthSettingsController* editPlayingStrengthSettingsController = [[EditPlayingStrengthSettingsController controllerForProfile:self.profile withDelegate:self] retain];
        [self.navigationController pushViewController:editPlayingStrengthSettingsController animated:YES];
        [editPlayingStrengthSettingsController release];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (ResignBehaviourSection == indexPath.section)
  {
    switch (indexPath.row)
    {
      case ResignBehaviourItem:
      {
        NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
        for (int resignBehaviour = minimumResignBehaviour; resignBehaviour <= maximumResignBehaviour; ++resignBehaviour)
        {
          NSString* resignBehaviourString = [self resignBehaviourName:resignBehaviour];
          [itemList addObject:resignBehaviourString];
        }
        int indexOfDefaultResignBehaviour;
        if (customResignBehaviour == self.profile.resignBehaviour)
          indexOfDefaultResignBehaviour = -1;
        else
          indexOfDefaultResignBehaviour = self.profile.resignBehaviour - minimumResignBehaviour;
        ItemPickerController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 screenTitle:@"Resign behaviour"
                                                                          indexOfDefaultItem:indexOfDefaultResignBehaviour
                                                                                    delegate:self];
        modalController.context = [NSNumber numberWithInteger:indexPath.section];
        UINavigationController* navigationController = [[UINavigationController alloc]
                                                        initWithRootViewController:modalController];
        navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        navigationController.delegate = [LayoutManager sharedManager];
        [self presentViewController:navigationController animated:YES completion:nil];
        [navigationController release];
        break;
      }
      case ResignBehaviourAdvancedConfigurationItem:
      {
        EditResignBehaviourSettingsController* editResignBehaviourSettingsController = [[[EditResignBehaviourSettingsController alloc] init] autorelease];
        editResignBehaviourSettingsController.profile = self.profile;
        editResignBehaviourSettingsController.delegate = self;
        [self.navigationController pushViewController:editResignBehaviourSettingsController animated:YES];
        break;
      }
      default:
      {
        assert(0);
        break;
      }
    }
  }
  else if (ProfileNotesSection == indexPath.section)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.profileDescription
                                                                               style:EditTextControllerStyleTextView
                                                                            delegate:self] retain];
    editTextController.title = @"Edit notes";
    editTextController.acceptEmptyText = true;
    editTextController.context = [NSNumber numberWithInteger:indexPath.section];
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    navigationController.delegate = [LayoutManager sharedManager];
    [self presentViewController:navigationController animated:YES completion:nil];
    [navigationController release];
    [editTextController release];
  }
}

#pragma mark - EditTextDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text
{
  return true;
}

// -----------------------------------------------------------------------------
/// @brief EditTextDelegate protocol method
// -----------------------------------------------------------------------------
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
{
  if (! didCancel)
  {
    if (editTextController.textHasChanged)
    {
      NSNumber* context = editTextController.context;
      NSInteger sectionFromContext = [context integerValue];
      NSIndexPath* indexPathToReload = nil;
      switch (sectionFromContext)
      {
        case ProfileNameSection:
        {
          self.profile.name = editTextController.text;
          indexPathToReload = [NSIndexPath indexPathForRow:ProfileNameItem inSection:sectionFromContext];
          if (self.profileExists)
          {
            if ([self.delegate respondsToSelector:@selector(didChangeProfile:)])
              [self.delegate didChangeProfile:self];
          }
          else
          {
            self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
          }
          break;
        }
        case ProfileNotesSection:
        {
          self.profile.profileDescription = editTextController.text;
          indexPathToReload = [NSIndexPath indexPathForRow:ProfileNotesItem inSection:sectionFromContext];
          break;
        }
        default:
        {
          DDLogError(@"%@: Unexpected section %ld", self, (long)sectionFromContext);
          assert(0);
          break;
        }
      }
      if (indexPathToReload)
      {
        NSArray* indexPaths = [NSArray arrayWithObject:indexPathToReload];
        [self.tableView reloadRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationNone];
      }
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - ItemPickerDelegate overrides

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
    {
      NSNumber* context = controller.context;
      NSInteger sectionIndex = [context integerValue];
      NSInteger rowIndex;
      if (PlayingStrengthSection == sectionIndex)
      {
        self.profile.playingStrength = (minimumPlayingStrength + controller.indexOfSelectedItem);
        rowIndex = PlayingStrengthItem;
      }
      else
      {
        self.profile.resignBehaviour = (minimumResignBehaviour + controller.indexOfSelectedItem);
        rowIndex = ResignBehaviourItem;
      }
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - EditPlayingStrengthSettingsDelegate overrides

// -----------------------------------------------------------------------------
/// @brief EditPlayingStrengthSettingsDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeProfile:(EditPlayingStrengthSettingsController*)editPlayingStrengthSettingsController
{
  NSUInteger sectionIndex = PlayingStrengthSection;
  NSUInteger rowIndex = PlayingStrengthItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - EditResignBehaviourSettingsController overrides

// -----------------------------------------------------------------------------
/// @brief EditResignBehaviourSettingsController protocol method.
// -----------------------------------------------------------------------------
- (void) didChangeResignBehaviour:(EditResignBehaviourSettingsController*)editResignBehaviourSettingsController
{
  NSUInteger sectionIndex = ResignBehaviourSection;
  NSUInteger rowIndex = ResignBehaviourItem;
  NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
  NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
  [self.tableView reloadRowsAtIndexPaths:indexPaths
                        withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Action handlers

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new profile object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model add:self.profile];

  if ([self.delegate respondsToSelector:@selector(didCreateProfile:)])
    [self.delegate didCreateProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user taps "done" to dismiss this controller. The
/// "done" button is shown only if this controller is presented modally.
// -----------------------------------------------------------------------------
- (void) done:(id)sender
{
  if ([self.delegate respondsToSelector:@selector(didEditProfile:)])
    [self.delegate didEditProfile:self];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Returns true if the current profile object contains valid data so
/// that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  return (self.profile.name.length > 0);
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a resignBehaviour that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a resignBehaviour is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) resignBehaviourName:(int)resignBehaviour
{
  switch (resignBehaviour)
  {
    case 0:
      return @"Custom";
    case 1:
      return @"Pushover";
    case 2:
      return @"Resign quickly";
    case 3:
      return @"Normal";
    case 4:
      return @"Stubborn";
    case 5:
      return @"Never resign";
    default:
    {
      NSString* errorMessage = [NSString stringWithFormat:@"Invalid resign behaviour: %d", resignBehaviour];
      DDLogError(@"%@: %@", self, errorMessage);
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:errorMessage
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
