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
#import "EditGtpEngineProfileController.h"
#import "../main/ApplicationDelegate.h"
#import "../player/GtpEngineProfile.h"
#import "../player/GtpEngineProfileModel.h"
#import "../ui/TableViewCellFactory.h"
#import "../ui/TableViewSliderCell.h"
#import "../ui/UiUtilities.h"
#import "../ui/UiElementMetrics.h"
#import "../utility/UiColorAdditions.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "Edit Profile" table view.
// -----------------------------------------------------------------------------
enum EditGtpEngineProfileTableViewSection
{
  ProfileNameSection,
  ProfileDescriptionSection,
  MaxMemorySection,
  ThreadsSection,
  PonderingSection,
  ReuseSubtreeSection,
  PlayoutLimitsSection,
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
/// @brief Enumerates items in the ProfileDescriptionSection.
// -----------------------------------------------------------------------------
enum ProfileDescriptionSectionItem
{
  ProfileDescriptionItem,
  MaxProfileDescriptionSectionItem,
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the MaxMemorySection.
// -----------------------------------------------------------------------------
enum MaxMemorySectionItem
{
  FuegoMaxMemoryItem,
  MaxMaxMemorySectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ThreadsSection.
// -----------------------------------------------------------------------------
enum ThreadsSectionItem
{
  FuegoThreadCountItem,
  MaxThreadsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PonderingSection.
// -----------------------------------------------------------------------------
enum PonderingSectionItem
{
  FuegoPonderingItem,
  FuegoMaxPonderTimeItem,
  MaxPonderingSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the ReuseSubtreeSection.
// -----------------------------------------------------------------------------
enum ReuseSubtreeSectionItem
{
  FuegoReuseSubtreeItem,
  MaxReuseSubtreeSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates items in the PlayoutLimitsSection.
// -----------------------------------------------------------------------------
enum PlayoutLimitsSectionItem
{
  FuegoMaxThinkingTimeItem,
  FuegoMaxGamesItem,
  MaxPlayoutLimitsSectionItem
};

// -----------------------------------------------------------------------------
/// @brief Enumerates categories of "max. games" as they are displayed to the
/// user instead of meaningless raw numbers.
// -----------------------------------------------------------------------------
enum MaxGamesCategory
{
  Game1MaxGamesCategory,
  Game10MaxGamesCategory,
  Game100MaxGamesCategory,
  Game500MaxGamesCategory,
  Game1000MaxGamesCategory,
  Game2000MaxGamesCategory,
  Game5000MaxGamesCategory,
  Game10000MaxGamesCategory,
  Game15000MaxGamesCategory,
  Game20000MaxGamesCategory,
  Game50000MaxGamesCategory,
  UnlimitedMaxGamesCategory,
  MaxMaxGamesCategory
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private methods for
/// EditGtpEngineProfileController.
// -----------------------------------------------------------------------------
@interface EditGtpEngineProfileController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation;
//@}
/// @name Action methods
//@{
- (void) create:(id)sender;
- (void) togglePondering:(id)sender;
- (void) toggleReuseSubtree:(id)sender;
- (void) maxMemoryDidChange:(id)sender;
- (void) threadCountDidChange:(id)sender;
- (void) maxPonderTimeDidChange:(id)sender;
- (void) maxThinkingTimeDidChange:(id)sender;
- (void) maxGamesDidChange:(id)sender;
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
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath;
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name EditTextDelegate protocol
//@{
- (bool) controller:(EditTextController*)editTextController shouldEndEditingWithText:(NSString*)text;
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel;
//@}
/// @name ItemPickerDelegate protocol
//@{
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection;
//@}
/// @name Private helpers
//@{
- (bool) isProfileValid;
- (NSString*) maxGamesCategoryName:(enum MaxGamesCategory)maxGamesCategory;
- (unsigned long long) maxGames:(enum MaxGamesCategory)maxGamesCategory;
- (enum MaxGamesCategory) maxGamesCategory:(unsigned long long)maxGames;
//@}
/// @name Privately declared properties
//@{
@property(nonatomic, retain) UISwitch* reuseSubtreeSwitch;
//@}
@end


@implementation EditGtpEngineProfileController

@synthesize delegate;
@synthesize profile;
@synthesize profileExists;
@synthesize reuseSubtreeSwitch;


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
    controller.profileExists = false;
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
  self.reuseSubtreeSwitch = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  if (self.profileExists)
  {
    self.navigationItem.title = @"Edit Profile";
    self.navigationItem.leftBarButtonItem.enabled = [self isProfileValid];
  }
  else
  {
    self.navigationItem.title = @"New Profile";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(create:)];
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
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
    case ProfileNameSection:
      return MaxProfileNameSectionItem;
    case ProfileDescriptionSection:
      return MaxProfileDescriptionSectionItem;
    case MaxMemorySection:
      return MaxMaxMemorySectionItem;
    case ThreadsSection:
      return MaxThreadsSectionItem;
    case PonderingSection:
      return MaxPonderingSectionItem;
    case ReuseSubtreeSection:
      return MaxReuseSubtreeSectionItem;
    case PlayoutLimitsSection:
      return MaxPlayoutLimitsSectionItem;
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
      return @"Profile name & description";
    case MaxMemorySection:
      return @"GTP engine settings";
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
    case MaxMemorySection:
      return @"WARNING: Setting this value too high WILL crash the app! Read more about this under 'Help > Players & Profiles > Maximum memory'";
    case PlayoutLimitsSection:
      return @"Changed settings are applied only after a new game with a player who uses this profile is started.";
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
  UITableViewCell* cell;
  switch (indexPath.section)
  {
    case ProfileNameSection:
    {
      switch (indexPath.row)
      {
        case ProfileNameItem:
        {
          enum TableViewCellType cellType = TextFieldCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
          textField.delegate = self;
          textField.text = self.profile.name;
          textField.placeholder = @"Profile name";
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
    case ProfileDescriptionSection:
    {
      switch (indexPath.row)
      {
        case ProfileDescriptionItem:
        {
          enum TableViewCellType cellType = DefaultCellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          if (self.profile.profileDescription.length > 0)
          {
            cell.textLabel.text = self.profile.profileDescription;
            cell.textLabel.textColor = [UIColor slateBlueColor];
          }
          else
          {
            // Fake placeholder of UITextField
            cell.textLabel.text = @"Profile description";
            cell.textLabel.textColor = [UIColor lightGrayColor];
          }
          cell.textLabel.font = [UIFont systemFontOfSize:[UIFont labelFontSize]];  // remove bold'ness
          cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
          cell.textLabel.numberOfLines = 0;
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    case MaxMemorySection:
    {
      cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxMemoryDidChange:)];
      sliderCell.descriptionLabel.text = @"Max. memory (MB)";
      sliderCell.slider.minimumValue = fuegoMaxMemoryMinimum;
      sliderCell.slider.maximumValue = fuegoMaxMemoryMaximum;
      sliderCell.value = self.profile.fuegoMaxMemory;
      break;
    }
    case ThreadsSection:
    {
      cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
      TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
      [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(threadCountDidChange:)];
      sliderCell.descriptionLabel.text = @"Number of threads";
      sliderCell.slider.minimumValue = fuegoThreadCountMinimum;
      sliderCell.slider.maximumValue = fuegoThreadCountMaximum;
      sliderCell.value = self.profile.fuegoThreadCount;
      break;
    }
    case PonderingSection:
    {
      switch (indexPath.row)
      {
        case FuegoPonderingItem:
        {
          cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
          UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
          cell.textLabel.text = @"Pondering";
          accessoryView.on = self.profile.fuegoPondering;
          [accessoryView addTarget:self action:@selector(togglePondering:) forControlEvents:UIControlEventValueChanged];
          break;
        }
        case FuegoMaxPonderTimeItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxPonderTimeDidChange:)];
          sliderCell.descriptionLabel.text = @"Ponder time (minutes)";
          sliderCell.slider.minimumValue = fuegoMaxPonderTimeMinimum / 60;
          sliderCell.slider.maximumValue = fuegoMaxPonderTimeMaximum / 60;
          sliderCell.value = self.profile.fuegoMaxPonderTime / 60;
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
    case ReuseSubtreeSection:
    {
      cell = [TableViewCellFactory cellWithType:SwitchCellType tableView:tableView];
      UISwitch* accessoryView = (UISwitch*)cell.accessoryView;
      cell.textLabel.text = @"Reuse subtree";
      accessoryView.on = self.profile.fuegoReuseSubtree;
      [accessoryView addTarget:self action:@selector(toggleReuseSubtree:) forControlEvents:UIControlEventValueChanged];
      // If pondering is on, the default value of reuse subtree ("on") must
      // not be changed by the user
      accessoryView.enabled = ! self.profile.fuegoPondering;
      // Keep reference to control so that we can manipulate it when
      // pondering is changed later on
      self.reuseSubtreeSwitch = accessoryView;
      break;
    }
    case PlayoutLimitsSection:
    {
      switch (indexPath.row)
      {
        case FuegoMaxThinkingTimeItem:
        {
          cell = [TableViewCellFactory cellWithType:SliderCellType tableView:tableView];
          TableViewSliderCell* sliderCell = (TableViewSliderCell*)cell;
          [sliderCell setDelegate:self actionValueDidChange:nil actionSliderValueDidChange:@selector(maxThinkingTimeDidChange:)];
          sliderCell.descriptionLabel.text = @"Thinking time (seconds)";
          sliderCell.slider.minimumValue = fuegoMaxThinkingTimeMinimum;
          sliderCell.slider.maximumValue = fuegoMaxThinkingTimeMaximum;
          sliderCell.value = self.profile.fuegoMaxThinkingTime;
          break;
        }
        case FuegoMaxGamesItem:
        {
          enum TableViewCellType cellType = Value1CellType;
          cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
          cell.textLabel.text = @"Max. games";
          enum MaxGamesCategory maxGamesCategory = [self maxGamesCategory:self.profile.fuegoMaxGames];
          cell.detailTextLabel.text = [self maxGamesCategoryName:maxGamesCategory];
          cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
    default:
    {
      assert(0);
      break;
    }
  }

  return cell;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (CGFloat) tableView:(UITableView*)tableView heightForRowAtIndexPath:(NSIndexPath*)indexPath
{
  CGFloat height = tableView.rowHeight;
  switch (indexPath.section)
  {
    case ProfileDescriptionSection:
    {
      NSString* cellText;  // use the same strings as in tableView:cellForRowAtIndexPath:()
      if (ProfileNameSection == indexPath.section)
        cellText = self.profile.name;
      else
        cellText = self.profile.profileDescription;
      height = [UiUtilities tableView:tableView
                  heightForCellOfType:DefaultCellType
                             withText:cellText
               hasDisclosureIndicator:true];
      break;
    }
    case MaxMemorySection:
    {
      if (FuegoMaxMemoryItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case ThreadsSection:
    {
      if (FuegoThreadCountItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case PonderingSection:
    {
      if (FuegoMaxPonderTimeItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    case PlayoutLimitsSection:
    {
      if (FuegoMaxThinkingTimeItem == indexPath.row)
        height = [TableViewSliderCell rowHeightInTableView:tableView];
      break;
    }
    default:
    {
      break;
    }
  }
  return height;
}

// -----------------------------------------------------------------------------
/// @brief UITableViewDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];

  if (ProfileDescriptionSection == indexPath.section)
  {
    EditTextController* editTextController = [[EditTextController controllerWithText:self.profile.profileDescription
                                                                               style:EditTextControllerStyleTextView
                                                                            delegate:self] retain];
    editTextController.title = @"Edit description";
    UINavigationController* navigationController = [[UINavigationController alloc]
                                                    initWithRootViewController:editTextController];
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentModalViewController:navigationController animated:YES];
    [navigationController release];
    [editTextController release];
  }
  else if (PlayoutLimitsSection == indexPath.section)
  {
    if (FuegoMaxGamesItem == indexPath.row)
    {
      NSMutableArray* itemList = [NSMutableArray arrayWithCapacity:0];
      for (int maxGamesCategoryIndex = 0; maxGamesCategoryIndex < MaxMaxGamesCategory; ++maxGamesCategoryIndex)
      {
        NSString* maxGamesCategory = [self maxGamesCategoryName:maxGamesCategoryIndex];
        [itemList addObject:maxGamesCategory];
      }
      int indexOfDefaultMaxGamesCategory = [self maxGamesCategory:self.profile.fuegoMaxGames];
      UIViewController* modalController = [ItemPickerController controllerWithItemList:itemList
                                                                                 title:@"Max. games"
                                                                    indexOfDefaultItem:indexOfDefaultMaxGamesCategory
                                                                              delegate:self];
      UINavigationController* navigationController = [[UINavigationController alloc]
                                                      initWithRootViewController:modalController];
      navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
      [self presentModalViewController:navigationController animated:YES];
      [navigationController release];
    }
  }
}

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
      self.profile.profileDescription = editTextController.text;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:ProfileDescriptionItem inSection:ProfileDescriptionSection];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief UITextFieldDelegate protocol method.
///
/// An alternative to using the delegate protocol is to listen for notifications
/// sent by the text field.
// -----------------------------------------------------------------------------
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
  // Compose the string as it would look like if the proposed change had already
  // been made
  NSString* newText = [textField.text stringByReplacingCharactersInRange:range withString:string];
  self.profile.name = newText;
  if (self.profileExists)
  {
    // Make sure that the editing view cannot be left, unless the profile
    // is valid
    [self.navigationItem setHidesBackButton:! [self isProfileValid] animated:YES];
    // Notify delegate that something about the profile object has changed
    [self.delegate didChangeProfile:self];
  }
  else
  {
    // Make sure that the new profile cannot be added, unless it is valid
    self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  }
  // Accept all changes, even those that make the profile name invalid
  // -> the user must simply continue editing until the profile name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief ItemPickerDelegate protocol method.
// -----------------------------------------------------------------------------
- (void) itemPickerController:(ItemPickerController*)controller didMakeSelection:(bool)didMakeSelection
{
  if (didMakeSelection)
  {
    if (controller.indexOfDefaultItem != controller.indexOfSelectedItem)
    {
      self.profile.fuegoMaxGames = [self maxGames:controller.indexOfSelectedItem];

      NSUInteger sectionIndex = PlayoutLimitsSection;
      NSUInteger rowIndex = FuegoMaxGamesItem;
      NSIndexPath* indexPath = [NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex];
      NSArray* indexPaths = [NSArray arrayWithObject:indexPath];
      [self.tableView reloadRowsAtIndexPaths:indexPaths
                            withRowAnimation:UITableViewRowAnimationNone];
    }
  }
  [self dismissModalViewControllerAnimated:YES];
}

// -----------------------------------------------------------------------------
/// @brief Invoked when the user wants to create a new profile object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  [model add:self.profile];

  [self.delegate didCreateProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Ponder" switch. Updates the profile
/// object with the new value.
// -----------------------------------------------------------------------------
- (void) togglePondering:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoPondering = accessoryView.on;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];

  // Directly manipulating the switch control gives the best result,
  // graphics-wise. If we do the update via table view reload of a single cell,
  // there is a nasty little flicker when pondering is turned off and the
  // "reuse subtree" switch becomes enabled. I have not tracked down the source
  // of the flicker, but instead gone straight to directly manipulating the
  // switch control.
  if (self.profile.fuegoPondering)
  {
    self.profile.fuegoReuseSubtree = true;
    self.reuseSubtreeSwitch.on = true;
  }
  self.reuseSubtreeSwitch.enabled = ! self.profile.fuegoPondering;
}

// -----------------------------------------------------------------------------
/// @brief Reacts to a tap gesture on the "Reuse subtree" switch. Updates the
/// profile object with the new value.
// -----------------------------------------------------------------------------
- (void) toggleReuseSubtree:(id)sender
{
  UISwitch* accessoryView = (UISwitch*)sender;
  self.profile.fuegoReuseSubtree = accessoryView.on;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum amount of memory.
// -----------------------------------------------------------------------------
- (void) maxMemoryDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxMemory = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's number of threads.
// -----------------------------------------------------------------------------
- (void) threadCountDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoThreadCount = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum pondering time.
// -----------------------------------------------------------------------------
- (void) maxPonderTimeDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxPonderTime = sliderCell.value * 60;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum thinking time.
// -----------------------------------------------------------------------------
- (void) maxThinkingTimeDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxThinkingTime = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Reacts to the user changing Fuego's maximum number of games to play.
// -----------------------------------------------------------------------------
- (void) maxGamesDidChange:(id)sender
{
  TableViewSliderCell* sliderCell = (TableViewSliderCell*)sender;
  self.profile.fuegoMaxGames = sliderCell.value;

  if (self.profileExists)
    [self.delegate didChangeProfile:self];
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current profile object contains valid data so
/// that editing can safely be stopped.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  return (self.profile.name.length > 0);
}

// -----------------------------------------------------------------------------
/// @brief Returns a string representation of @a maxGamesCategory that is
/// suitable for displaying in the UI.
///
/// Raises an @e NSInvalidArgumentException if @a maxGamesCategory is not
/// recognized.
// -----------------------------------------------------------------------------
- (NSString*) maxGamesCategoryName:(enum MaxGamesCategory)maxGamesCategory
{
  switch (maxGamesCategory)
  {
    case Game1MaxGamesCategory:
      return @"1";
    case Game10MaxGamesCategory:
      return @"10";
    case Game100MaxGamesCategory:
      return @"100";
    case Game500MaxGamesCategory:
      return @"500";
    case Game1000MaxGamesCategory:
      return @"1000";
    case Game2000MaxGamesCategory:
      return @"2000";
    case Game5000MaxGamesCategory:
      return @"5000";
    case Game10000MaxGamesCategory:
      return @"10'000";
    case Game15000MaxGamesCategory:
      return @"15'000";
    case Game20000MaxGamesCategory:
      return @"20'000";
    case Game50000MaxGamesCategory:
      return @"50'000";
    case UnlimitedMaxGamesCategory:
      return @"Unlimited";
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid 'max. games' category: %d", maxGamesCategory]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a natural number corresponding to the enumeration value
/// @a maxGamesCategory.
///
/// Raises an @e NSInvalidArgumentException if @a maxGamesCategory is not
/// recognized.
// -----------------------------------------------------------------------------
- (unsigned long long) maxGames:(enum MaxGamesCategory)maxGamesCategory
{
  switch (maxGamesCategory)
  {
    case Game1MaxGamesCategory:
      return 1;
    case Game10MaxGamesCategory:
      return 10;
    case Game100MaxGamesCategory:
      return 100;
    case Game500MaxGamesCategory:
      return 500;
    case Game1000MaxGamesCategory:
      return 1000;
    case Game2000MaxGamesCategory:
      return 2000;
    case Game5000MaxGamesCategory:
      return 5000;
    case Game10000MaxGamesCategory:
      return 10000;
    case Game15000MaxGamesCategory:
      return 15000;
    case Game20000MaxGamesCategory:
      return 20000;
    case Game50000MaxGamesCategory:
      return 50000;
    case UnlimitedMaxGamesCategory:
      return fuegoMaxGamesMaximum;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid 'max. games' category: %d", maxGamesCategory]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

// -----------------------------------------------------------------------------
/// @brief Returns a category enumeration value that corresponds to the natural
/// number @a maxGames.
///
/// Raises an @e NSInvalidArgumentException if there is no correspondence for
/// @a maxGames.
// -----------------------------------------------------------------------------
- (enum MaxGamesCategory) maxGamesCategory:(unsigned long long)maxGames
{
  if (fuegoMaxGamesMaximum == maxGames)
    return UnlimitedMaxGamesCategory;
  switch (maxGames)
  {
    case 1:
      return Game1MaxGamesCategory;
    case 10:
      return Game10MaxGamesCategory;
    case 100:
      return Game100MaxGamesCategory;
    case 500:
      return Game500MaxGamesCategory;
    case 1000:
      return Game1000MaxGamesCategory;
    case 2000:
      return Game2000MaxGamesCategory;
    case 5000:
      return Game5000MaxGamesCategory;
    case 10000:
      return Game10000MaxGamesCategory;
    case 15000:
      return Game15000MaxGamesCategory;
    case 20000:
      return Game20000MaxGamesCategory;
    case 50000:
      return Game50000MaxGamesCategory;
    default:
    {
      NSException* exception = [NSException exceptionWithName:NSInvalidArgumentException
                                                       reason:[NSString stringWithFormat:@"Invalid 'max. games' number %d, no available category", maxGames]
                                                     userInfo:nil];
      @throw exception;
    }
  }
}

@end
