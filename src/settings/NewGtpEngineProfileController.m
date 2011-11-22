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
#import "NewGtpEngineProfileController.h"
#import "../ui/TableViewCellFactory.h"
#import "../ApplicationDelegate.h"
#import "../player/GtpEngineProfileModel.h"
#import "../player/GtpEngineProfile.h"


// -----------------------------------------------------------------------------
/// @brief Enumerates the sections presented in the "New Profile" table view.
// -----------------------------------------------------------------------------
enum NewProfileTableViewSection
{
  ProfileNameSection,
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
/// @brief Class extension with private methods for
/// NewGtpEngineProfileController.
// -----------------------------------------------------------------------------
@interface NewGtpEngineProfileController()
/// @name Initialization and deallocation
//@{
- (void) dealloc;
//@}
/// @name UIViewController methods
//@{
- (void) viewDidLoad;
- (void) viewDidUnload;
//@}
/// @name Action methods
//@{
- (void) create:(id)sender;
//@}
/// @name UITableViewDataSource protocol
//@{
- (NSInteger) numberOfSectionsInTableView:(UITableView*)tableView;
- (NSInteger) tableView:(UITableView*)tableView numberOfRowsInSection:(NSInteger)section;
- (UITableViewCell*) tableView:(UITableView*)tableView cellForRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITableViewDelegate protocol
//@{
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath;
//@}
/// @name UITextFieldDelegate protocol method.
//@{
- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string;
//@}
/// @name Helpers
//@{
- (bool) isProfileValid;
//@}
@end


@implementation NewGtpEngineProfileController

@synthesize delegate;
@synthesize profile;


// -----------------------------------------------------------------------------
/// @brief Convenience constructor. Creates a NewGtpEngineProfileController
/// instance of grouped style.
// -----------------------------------------------------------------------------
+ (NewGtpEngineProfileController*) controllerWithDelegate:(id<NewGtpEngineProfileDelegate>)delegate
{
  NewGtpEngineProfileController* controller = [[NewGtpEngineProfileController alloc] initWithStyle:UITableViewStyleGrouped];
  if (controller)
  {
    [controller autorelease];
    controller.delegate = delegate;
    controller.profile = [[[GtpEngineProfile alloc] init] autorelease];
  }
  return controller;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this NewGtpEngineProfileController
/// object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.delegate = nil;
  self.profile = nil;
  [super dealloc];
}

// -----------------------------------------------------------------------------
/// @brief Called after the controller’s view is loaded into memory, usually
/// to perform additional initialization steps.
// -----------------------------------------------------------------------------
- (void) viewDidLoad
{
  [super viewDidLoad];

  assert(self.delegate != nil);

  // Configure the navigation item representing this controller. This item will
  // be displayed by the navigation controller that wraps this controller in
  // its navigation bar.
  self.navigationItem.title = @"New Profile";
  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Create"
                                                                            style:UIBarButtonItemStyleDone
                                                                           target:self
                                                                           action:@selector(create:)];
  self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
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
/// @brief Invoked when the user wants to create a new profile object using the
/// data that has been entered so far.
// -----------------------------------------------------------------------------
- (void) create:(id)sender
{
  GtpEngineProfileModel* model = [ApplicationDelegate sharedDelegate].gtpEngineProfileModel;
  assert(model);
  [model add:self.profile];

  [self.delegate didCreateNewProfile:self];
  [self.navigationController popViewControllerAnimated:YES];
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
    default:
      assert(0);
      break;
  }
  return 0;
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
      enum TableViewCellType cellType = TextFieldCellType;
      cell = [TableViewCellFactory cellWithType:cellType tableView:tableView];
      UITextField* textField = (UITextField*)[cell viewWithTag:TextFieldCellTextFieldTag];
      textField.delegate = self;
      textField.text = self.profile.name;
      textField.placeholder = @"Profile name";
      // Place the insertion point into this field; might be better to
      // do this in viewWillAppear:
      [textField becomeFirstResponder];
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
- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath*)indexPath
{
  [tableView deselectRowAtIndexPath:indexPath animated:NO];
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
  self.profile.name = [textField.text stringByReplacingCharactersInRange:range withString:string];
  // Make sure that the new profile cannot be added, unless its name is valid
  self.navigationItem.rightBarButtonItem.enabled = [self isProfileValid];
  // Accept all changes, even those that make the profile name invalid
  // -> the user must simply continue editing until the profile name becomes
  //    valid
  return YES;
}

// -----------------------------------------------------------------------------
/// @brief Returns true if the current profile object contains valid data so
/// that the object can safely be added to the profile model.
// -----------------------------------------------------------------------------
- (bool) isProfileValid
{
  return (self.profile.name.length > 0);
}

@end
