// -----------------------------------------------------------------------------
// Copyright 2022 Patrick Näf (herzbube@herzbube.ch)
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
#import "HandleMarkupEditingInteractionCommand.h"
#import "../backup/BackupGameToSgfCommand.h"
#import "../../go/GoGame.h"
#import "../../go/GoBoard.h"
#import "../../go/GoBoardPosition.h"
#import "../../go/GoNode.h"
#import "../../go/GoNodeMarkup.h"
#import "../../go/GoPoint.h"
#import "../../go/GoUtilities.h"
#import "../../go/GoVertex.h"
#import "../../main/ApplicationDelegate.h"
#import "../../shared/ApplicationStateManager.h"
#import "../../ui/UiSettingsModel.h"
#import "../../ui/UIViewControllerAdditions.h"
#import "../../utility/MarkupUtilities.h"
#import "../../utility/ExceptionUtility.h"


enum MarkupEditingInteraction
{
  MEIPlaceNewSymbol,
  MEIPlaceNewConnection,
  MEIPlaceNewMarker,
  MEIPlaceNewLabel,
  MEIPlaceMovedSymbol,
  MEIPlaceMovedConnection,
  MEIPlaceMovedMarker,
  MEIPlaceMovedLabel,
  MEIEraseMarkupAtPoint,
  MEIEraseMarkupInArea,
  MEIEraseConnectionAtPoint,
  MEINone,
};

// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
@interface HandleMarkupEditingInteractionCommand()
@property(nonatomic, assign) enum MarkupEditingInteraction interaction;

@property(nonatomic, retain) GoPoint* point;
@property(nonatomic, retain) NSString* labelText;
@property(nonatomic, retain) GoPoint* startPoint;
@property(nonatomic, retain) GoPoint* endPoint;
@property(nonatomic, assign) enum MarkupTool markupTool;
@property(nonatomic, assign) enum MarkupType markupType;
@property(nonatomic, assign) bool markupWasMoved;
@end


@implementation HandleMarkupEditingInteractionCommand

#pragma mark - Initialization and deallocation

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// cannot handle any markup editing interaction. Executing a command that
/// was initialized with this initializer fails.
///
/// @note This is the designated initializer of
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithNoInteraction
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.interaction = MEINone;
  self.point = nil;
  self.labelText = nil;
  self.startPoint = nil;
  self.endPoint = nil;
  self.markupTool = MarkupToolSymbol;
  self.markupType = MarkupTypeSymbolCircle;
  self.markupWasMoved = false;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// places new markup of type @a markupType on @a point.
///
/// The newly placed markup is determined according to certain rules, some of
/// which are governed by user preferences. For instance, for symbols or markers
/// the next free symbol or marker is determined according to user preferences
/// (this could even lead to removal of a symbol or marker). For labels the
/// label text is determined interactively.
///
/// Connections cannot be placed with this initializer. Instead use
/// initPlaceNewOrMovedConnection:fromPoint:toPoint:connectionWasMoved:().
// -----------------------------------------------------------------------------
- (id) initPlaceNewMarkupAtPoint:(GoPoint*)point
                      markupTool:(enum MarkupTool)markupTool
                      markupType:(enum MarkupType)markupType
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  if (markupTool == MarkupToolSymbol)
    self.interaction = MEIPlaceNewSymbol;
  else if (markupTool == MarkupToolMarker)
    self.interaction = MEIPlaceNewMarker;
  else if (markupTool == MarkupToolLabel)
    self.interaction = MEIPlaceNewLabel;
  else
    [ExceptionUtility throwInternalInconsistencyExceptionWithFormat:@"initPlaceNewMarkupAtPoint:markupTool:markupType: failed, invalid markup tool %d" argumentValue:markupTool];

  self.point = point;
  self.markupTool = markupTool;
  self.markupType = markupType;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// places a moved markup symbol of type @a symbol on @a point.
///
/// No logic is used to determin the symbol to place, @a symbol defines the
/// exact symbol to place.
// -----------------------------------------------------------------------------
- (id) initPlaceMovedSymbol:(enum GoMarkupSymbol)symbol
                    atPoint:(GoPoint*)point
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  self.interaction = MEIPlaceMovedSymbol;

  self.point = point;
  self.markupTool = MarkupToolSymbol;
  self.markupType = [MarkupUtilities markupTypeForSymbol:symbol];
  self.markupWasMoved = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// places a markup connection of type @a connection starting at @a fromPoint
/// and going to @a toPoint. If @a connectionWasMoved is @e false the
/// connection is a new connection, if @a connectionWasMoved is @e true the
/// connection already existed but either its starting or end point was moved
/// from a previous location.
// -----------------------------------------------------------------------------
- (id) initPlaceNewOrMovedConnection:(enum GoMarkupConnection)connection
                           fromPoint:(GoPoint*)fromPoint
                             toPoint:(GoPoint*)toPoint
                  connectionWasMoved:(bool)connectionWasMoved
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  if (connectionWasMoved)
    self.interaction = MEIPlaceMovedConnection;
  else
    self.interaction = MEIPlaceNewConnection;

  self.startPoint = fromPoint;
  self.endPoint = toPoint;
  self.markupTool = MarkupToolConnection;
  self.markupType = [MarkupUtilities markupTypeForConnection:connection];
  self.markupWasMoved = connectionWasMoved;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// places a moved marker or label of type @a label with text @a labelText on
/// @a point.
///
/// No logic or interactivity is used to determin the marker or label text to
/// place, @a labelText defines the exact text to place.
// -----------------------------------------------------------------------------
- (id) initPlaceMovedLabel:(enum GoMarkupLabel)label
             withLabelText:(NSString*)labelText
                   atPoint:(GoPoint*)point
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  if (label == GoMarkupLabelLabel)
  {
    self.interaction = MEIPlaceMovedLabel;
    self.markupTool = MarkupToolLabel;
  }
  else
  {
    self.interaction = MEIPlaceMovedMarker;
    self.markupTool = MarkupToolMarker;
  }

  self.point = point;
  self.labelText = labelText;
  self.markupType = [MarkupUtilities markupTypeForLabel:label];
  self.markupWasMoved = true;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// erases all markup located at @a point.
// -----------------------------------------------------------------------------
- (id) initEraseMarkupAtPoint:(GoPoint*)point
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  self.interaction = MEIEraseMarkupAtPoint;
  self.point = point;
  self.markupTool = MarkupToolConnection;
  self.markupType = MarkupTypeEraser;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// erases all markup in an entire rectangular area defined by @a fromPoint and
/// @a endPoint, which are diagonally opposed corners of the rectangle.
// -----------------------------------------------------------------------------
- (id) initEraseMarkupInRectangleFromPoint:(GoPoint*)fromPoint
                                   toPoint:(GoPoint*)toPoint
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  self.interaction = MEIEraseMarkupInArea;
  self.startPoint = fromPoint;
  self.endPoint = toPoint;
  self.markupTool = MarkupToolEraser;
  self.markupType = MarkupTypeEraser;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// erases a connection whose start or end point is at @a point.
// -----------------------------------------------------------------------------
- (id) initEraseConnectionAtPoint:(GoPoint*)point
{
  self = [self initWithNoInteraction];
  if (! self)
    return nil;

  self.interaction = MEIEraseConnectionAtPoint;
  self.point = point;
  self.markupTool = MarkupToolConnection;
  self.markupType = MarkupTypeEraser;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Deallocates memory allocated by this
/// HandleMarkupEditingInteractionCommand object.
// -----------------------------------------------------------------------------
- (void) dealloc
{
  self.point = nil;
  self.labelText = nil;
  self.startPoint = nil;
  self.endPoint = nil;

  [super dealloc];
}

#pragma mark - CommandBase methods

// -----------------------------------------------------------------------------
/// @brief Executes this command. See the class documentation for details.
// -----------------------------------------------------------------------------
- (bool) doIt
{
  if (self.interaction == MEINone)
  {
    DDLogError(@"%@: Unable to handle markup interaction of type %d", self, self.interaction);
    return false;
  }

  if (! self.point && ! (self.startPoint && self.endPoint))
  {
    DDLogError(@"%@: Unable to handle markup interaction because neither a single point nor a start/end point pair is set", self);
    return false;
  }

  GoGame* game = [GoGame sharedGame];
  GoBoardPosition* boardPosition = game.boardPosition;
  int currentBoardPosition = boardPosition.currentBoardPosition;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  if (appDelegate.uiSettingsModel.uiAreaPlayMode != UIAreaPlayModeEditMarkup)
  {
    // Alas, defensive programming. Cf. HandleBoardSetupInteractionCommand,
    // although the scenarios handled there should not be possible for markup
    // editing because markup editing does not involve showing an alert.
    [self showAlertNotInMarkupEditingMode:currentBoardPosition];
    return false;
  }

  if (currentBoardPosition == 0)
  {
    // Alas, defensive programming. Cf. HandleBoardSetupInteractionCommand,
    // although the scenarios handled there should not be possible for markup
    // editing because markup editing does not involve showing an alert.
    [self showAlertOnBoardPositionZero];
    return false;
  }

  GoNode* currentNode = boardPosition.currentNode;
  GoNodeMarkup* nodeMarkup = currentNode.goNodeMarkup;
  if (! nodeMarkup)
  {
    nodeMarkup = [[[GoNodeMarkup alloc] init] autorelease];
    currentNode.goNodeMarkup = nodeMarkup;
  }

  if (self.interaction == MEIPlaceNewLabel)
  {
    [self handleEnterNewLabelTextOnPoint:self.point
                                    node:currentNode];
  }
  else
  {
    [self handleMarkupEditingInteractionWithNode:currentNode];
  }

  return true;
}

#pragma mark - Helpers for doIt

// -----------------------------------------------------------------------------
/// @brief Performs the actual markup editing interaction handling. Is called
/// both from doIt() and after the user entered a new label text when the
/// interaction is #MEIPlaceNewLabel.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingInteractionWithNode:(GoNode*)node
{
  bool applicationStateDidChange = false;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    GoNodeMarkup* nodeMarkup = node.goNodeMarkup;

    NSArray* pointsWithChangedMarkup = nil;

    switch (self.interaction)
    {
      case MEIPlaceNewSymbol:
      case MEIPlaceMovedSymbol:
      {
        NSString* intersection = self.point.vertex.string;
        bool markupWasMoved = self.interaction == MEIPlaceMovedLabel;
        bool markupDataDidChange = [self handlePlaceSymbol:self.markupType onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[self.point];
        break;
      }
      case MEIPlaceNewConnection:
      case MEIPlaceMovedConnection:
      {
        NSString* fromIntersection = self.startPoint.vertex.string;
        NSString* toIntersection = self.endPoint.vertex.string;
        bool markupWasMoved = self.interaction == MEIPlaceMovedConnection;
        bool markupDataDidChange = [self handlePlaceConnection:self.markupType fromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[self.startPoint, self.endPoint];
        break;
      }
      case MEIPlaceNewMarker:
      {
        NSString* intersection = self.point.vertex.string;
        bool markupDataDidChange = [self handlePlaceMarker:self.markupType onIntersection:intersection withNodeMarkup:nodeMarkup];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[self.point];
        break;
      }
      case MEIPlaceMovedMarker:
      {
        NSString* intersection = self.point.vertex.string;
        bool markupDataDidChange = [self handlePlaceLabel:self.labelText onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:true];;
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[self.point];
        break;
      }
      case MEIPlaceNewLabel:
      case MEIPlaceMovedLabel:
      {
        NSString* intersection = self.point.vertex.string;
        bool markupWasMoved = self.interaction == MEIPlaceMovedLabel;
        bool markupDataDidChange = [self handlePlaceLabel:self.labelText onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[self.point];
        break;
      }
      case MEIEraseMarkupAtPoint:
      {
        NSString* intersection = self.point.vertex.string;
        pointsWithChangedMarkup = [self handleEraseMarkupOnIntersection:intersection withNodeMarkup:nodeMarkup];
        break;
      }
      case MEIEraseMarkupInArea:
      {
        NSString* fromIntersection = self.startPoint.vertex.string;
        NSString* toIntersection = self.endPoint.vertex.string;
        pointsWithChangedMarkup = [self handleEraseMarkupInRectangleFromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup];
        break;
      }
      case MEIEraseConnectionAtPoint:
      {
        NSString* intersection = self.point.vertex.string;
        pointsWithChangedMarkup = [self handleRemoveConnectionIfExistsAtIntersection:intersection withNodeMarkup:nodeMarkup];
        break;
      }
      default:
      {
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to handle markup editing interaction, unsupported interaction: %d", self.interaction];
        DDLogError(@"%@: %@", self, errorMessage);
        [ExceptionUtility throwInternalInconsistencyExceptionWithErrorMessage:errorMessage];
        // Dummy code to make compiler happy
        applicationStateDidChange = false;
        pointsWithChangedMarkup = nil;
        break;
      }
    }

    if (! nodeMarkup.hasMarkup)
      node.goNodeMarkup = nil;

    if (pointsWithChangedMarkup)
    {
      applicationStateDidChange = true;
      [self postMarkupOnPointsDidChangeNotification:pointsWithChangedMarkup];
      [[[[BackupGameToSgfCommand alloc] init] autorelease] submit];
    }
  }
  @finally
  {
    if (applicationStateDidChange)
      [[ApplicationStateManager sharedManager] applicationStateDidChange];
    [[ApplicationStateManager sharedManager] commitSavePoint];
  }
}

// -----------------------------------------------------------------------------
/// @brief Posts #markupOnPointsDidChange to the global notification center
/// with an appropriate notification object.
// -----------------------------------------------------------------------------
- (void) postMarkupOnPointsDidChangeNotification:(NSArray*)pointsWithChangedMarkup
{
  NSArray* notificationObject;

  if (pointsWithChangedMarkup.count == 2 &&
      [pointsWithChangedMarkup.firstObject isKindOfClass:[GoPoint class]] &&
      [pointsWithChangedMarkup.lastObject isKindOfClass:[GoPoint class]])
  {
    GoPoint* connectionFromPoint = pointsWithChangedMarkup.firstObject;
    GoPoint* connectionToPoint = pointsWithChangedMarkup.lastObject;
    NSArray* pointsInConnectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:connectionFromPoint
                                                                            oppositeCornerPoint:connectionToPoint
                                                                                         inGame:[GoGame sharedGame]];
    notificationObject = @[connectionFromPoint, connectionToPoint, pointsInConnectionRectangle];
  }
  else
  {
    notificationObject = pointsWithChangedMarkup;
  }

  [[NSNotificationCenter defaultCenter] postNotificationName:markupOnPointsDidChange object:notificationObject];
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that the markup editing
/// interaction is not possible because the application is currently not in
/// markup editing mode.
// -----------------------------------------------------------------------------
- (void) showAlertNotInMarkupEditingMode:(int)currentBoardPosition
{
  NSString* alertTitle = @"Markup editing action canceled";
  NSString* alertMessage;
  // Try to find out why we are no longer in markup editing mode so that we can
  // display a more informative alert message
  if (currentBoardPosition == 0)
    alertMessage = @"The markup editing action was canceled because the board shows board position 0 and is no longer in markup editing mode. Markup can only be edited on board positions greater than zero.";
  else
    alertMessage = @"The markup editing action was canceled because the board is no longer in markup editing mode.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

// -----------------------------------------------------------------------------
/// @brief Shows an alert that informs the user that the markup editing
/// interaction is not possible because the board is currently showing board
/// position 0.
// -----------------------------------------------------------------------------
- (void) showAlertOnBoardPositionZero
{
  NSString* alertTitle = @"Markup editing action canceled";
  NSString* alertMessage = @"The markup editing action was canceled because the board shows board position 0. Markup can only be edited on board positions greater than zero.";
  DDLogWarn(@"%@: %@", self, alertMessage);

  void (^okActionBlock) (UIAlertAction*) = ^(UIAlertAction* action)
  {
    [self didDismissAlertWithButton:AlertButtonTypeOk];
  };

  [[ApplicationDelegate sharedDelegate].window.rootViewController presentOkAlertWithTitle:alertTitle
                                                                                  message:alertMessage
                                                                                okHandler:okActionBlock];

  [self retain];  // must survive until the handler method is invoked
}

#pragma mark - Alert handler

// -----------------------------------------------------------------------------
/// @brief Alert handler method.
// -----------------------------------------------------------------------------
- (void) didDismissAlertWithButton:(enum AlertButtonType)alertButtonType
{
  [self autorelease];  // balance retain that is sent before an alert is shown
}

#pragma mark - Place symbol

// -----------------------------------------------------------------------------
/// @brief Entry point for handling symbol markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceSymbol:(enum MarkupType)markupType
            onIntersection:(NSString*)intersection
            withNodeMarkup:(GoNodeMarkup*)nodeMarkup
            markupWasMoved:(bool)markupWasMoved
{
  // TODO xxx user preference
  bool exclusiveSymbols = true;

  enum GoMarkupSymbol symbolForSelectedMarkupType = [MarkupUtilities symbolForMarkupType:markupType];
  NSSet* symbolsThatCannotBeUsed = [NSSet set];
  bool symbolExists = false;
  enum GoMarkupSymbol existingSymbol = GoMarkupSymbolCircle;  // dummy initialize

  NSDictionary* symbols = nodeMarkup.symbols;
  if (symbols)
  {
    NSNumber* existingSymbolAsNumber = symbols[intersection];
    if (existingSymbolAsNumber)
    {
      symbolExists = true;
      existingSymbol = existingSymbolAsNumber.intValue;
    }

    if (exclusiveSymbols)
      symbolsThatCannotBeUsed = [[[NSSet alloc] initWithArray:symbols.allValues] autorelease];
    else if (symbolExists)
      symbolsThatCannotBeUsed = [[[NSSet alloc] initWithArray:@[existingSymbolAsNumber]] autorelease];
  }

  enum GoMarkupSymbol newSymbol;
  bool canUseNewSymbol = false;

  if (markupWasMoved)
  {
    newSymbol = symbolForSelectedMarkupType;
    canUseNewSymbol = true;
  }
  else if (symbolExists)
  {
    // Cycle through the symbols, starting with the next symbol after the
    // existing one. When we reach the selected markup type without having found
    // a free symbol, we delete the existing symbol, even if there are free
    // symbols afterwards. This allows the user to cycle through the free
    // symbols and eventually get rid of the existing symbol.
    newSymbol = [MarkupUtilities nextSymbolAfterSymbol:existingSymbol];

    while (newSymbol != symbolForSelectedMarkupType && ! canUseNewSymbol)
    {
      NSNumber* newSymbolAsNumber = [NSNumber numberWithInt:newSymbol];
      if ([symbolsThatCannotBeUsed containsObject:newSymbolAsNumber])
        newSymbol = [MarkupUtilities nextSymbolAfterSymbol:newSymbol];
      else
        canUseNewSymbol = true;
    }
  }
  else
  {
    // Cycle through the symbols, starting with the selected markup type. When
    // we reach the selected markup type without having found a free symbol, we
    // do nothing => this can happen only in exclusive mode when all symbols
    // have already been placed; the user in this case has to remove an existing
    // symbol first.
    newSymbol = symbolForSelectedMarkupType;

    do
    {
      NSNumber* newSymbolAsNumber = [NSNumber numberWithInt:newSymbol];
      if ([symbolsThatCannotBeUsed containsObject:newSymbolAsNumber])
        newSymbol = [MarkupUtilities nextSymbolAfterSymbol:newSymbol];
      else
        canUseNewSymbol = true;
    }
    while (newSymbol != symbolForSelectedMarkupType && ! canUseNewSymbol);
  }

  bool markupDataDidChange = true;
  if (canUseNewSymbol)
    [nodeMarkup setSymbol:newSymbol atVertex:intersection];
  else if (symbolExists)
    [nodeMarkup removeSymbolAtVertex:intersection];
  else
    markupDataDidChange = false;

  if (markupDataDidChange)
    [nodeMarkup removeLabelAtVertex:intersection];

  return markupDataDidChange;
}

#pragma mark - Place marker

// -----------------------------------------------------------------------------
/// @brief Entry point for handling marker markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceMarker:(enum MarkupType)markupType
            onIntersection:(NSString*)intersection
            withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  bool markerOfRequestedTypeExists = false;
  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
  {
    NSString* label = labels[intersection];
    if (label)
    {
      enum MarkupType markupTypeOfLabel = [MarkupUtilities markupTypeOfLabel:label];
      markerOfRequestedTypeExists = (markupType == markupTypeOfLabel);
    }
  }

  NSString* nextFreeMarker = [MarkupUtilities nextFreeMarkerOfType:markupType
                                                        inNodeMarkup:nodeMarkup];

  bool markupDataDidChange = true;
  if (nextFreeMarker)
    [nodeMarkup setLabel:nextFreeMarker atVertex:intersection];
  else if (markerOfRequestedTypeExists)
    [nodeMarkup removeLabelAtVertex:intersection];
  else
    markupDataDidChange = false;

  if (markupDataDidChange)
    [nodeMarkup removeSymbolAtVertex:intersection];

  return markupDataDidChange;
}

#pragma mark - Place label

// -----------------------------------------------------------------------------
/// @brief Entry point for handling label markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceLabel:(NSString*)labelText
           onIntersection:(NSString*)intersection
           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
           markupWasMoved:(bool)markupWasMoved
{
  NSString* existingLabel = nil;

  NSDictionary* labels = nodeMarkup.labels;
  if (labels)
    existingLabel = labels[intersection];

  // Clean up user input
  labelText = [GoNodeMarkup removeNewlinesAndTrimLabel:labelText];

  bool markupDataDidChange = true;
  if (labelText && labelText.length > 0)
  {
    if (existingLabel && [labelText isEqualToString:existingLabel])
      markupDataDidChange = markupWasMoved ? true : false;  // if moved, then the label was removed somewhere else => data did change
    else
      [nodeMarkup setLabel:labelText atVertex:intersection];
  }
  else
  {
    if (existingLabel)
      [nodeMarkup removeLabelAtVertex:intersection];
    else
      markupDataDidChange = false;
  }

  if (markupDataDidChange)
    [nodeMarkup removeSymbolAtVertex:intersection];

  return markupDataDidChange;
}

#pragma mark - Place label - Present EditTextDelegate

// -----------------------------------------------------------------------------
/// @brief Presents a popup that allows the user to enter a new label text.
/// If the user did not cancel the editing process, invokes
/// handleMarkupEditingInteractionOnIntersection:withMarkupModel:labelText:nodeMarkup:().
///
/// This method is invoked from doIt() and not from
/// handleMarkupEditingInteractionWithNode:(), because the latter wraps the
/// invocation of its handler methods into a pair of
/// beginSavePoint/commitSavePoint method calls, which requires the handler
/// method to work synchronously. This method does not work synchronously, it
/// presents EditTextDelegate.
// -----------------------------------------------------------------------------
- (void) handleEnterNewLabelTextOnPoint:(GoPoint*)point
                                   node:(GoNode*)node
{
  NSString* intersection = point.vertex.string;
  GoNodeMarkup* nodeMarkup = node.goNodeMarkup;

  NSDictionary* labels = nodeMarkup.labels;
  NSString* labelText = labels ? labels[intersection] : nil;

  EditTextController* editTextController = [[EditTextController controllerWithText:labelText
                                                                             style:EditTextControllerStyleTextField
                                                                          delegate:self] retain];
  editTextController.title = @"Edit label text";
  editTextController.acceptEmptyText = true;
  editTextController.context = node;

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.window.rootViewController presentNavigationControllerWithRootViewController:editTextController];
  [editTextController release];

  [self retain];  // must survive until EditTextController invokes the delegate method that indicates the end of the editing session
}

#pragma mark - Place label - EditTextDelegate overrides

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
- (void) didEndEditing:(EditTextController*)editTextController didCancel:(bool)didCancel
{
  [self autorelease];  // balance retain that is sent before EditTextController is shown

  if (! didCancel)
  {
    GoNode* node = editTextController.context;
    self.labelText = editTextController.text;
    [self handleMarkupEditingInteractionWithNode:node];
  }

  ApplicationDelegate* appDelegate = [ApplicationDelegate sharedDelegate];
  [appDelegate.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Place/remove connection

// -----------------------------------------------------------------------------
/// @brief Entry point for handling connection markup placing. Returns true if
/// markup data changed, returns false if markup data did not change.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (bool) handlePlaceConnection:(enum MarkupType)markupType
              fromIntersection:(NSString*)fromIntersection
                toIntersection:(NSString*)toIntersection
                withNodeMarkup:(GoNodeMarkup*)nodeMarkup
                markupWasMoved:(bool)markupWasMoved
{
  bool connectionExists = false;
  enum GoMarkupConnection existingConnection = GoMarkupConnectionArrow;  // dummy initialize

  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    NSArray* intersections = @[fromIntersection, toIntersection];
    NSNumber* existingConnectionAsNumber = connections[intersections];
    if (existingConnectionAsNumber)
    {
      connectionExists = true;
      existingConnection = existingConnectionAsNumber.intValue;
    }
  }

  enum GoMarkupConnection newConnection = (markupType == MarkupTypeConnectionArrow)
    ? GoMarkupConnectionArrow
    : GoMarkupConnectionLine;

  bool markupDataDidChange = true;
  if (connectionExists && existingConnection == newConnection)
    markupDataDidChange = markupWasMoved ? true : false;  // if moved, then the connection was removed somewhere else => data did change
  else
    [nodeMarkup setConnection:newConnection fromVertex:fromIntersection toVertex:toIntersection];

  return markupDataDidChange;
}

// -----------------------------------------------------------------------------
/// @brief Entry point for handling connection markup removal. Returns an array
/// with the start/end GoPoint objects of the connection that was removed.
/// Returns @e nil if no connection was removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleRemoveConnectionIfExistsAtIntersection:(NSString*)intersection
                                           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    for (NSArray* key in connections.allKeys)
    {
      if ([key containsObject:intersection])
      {
        // Use key components before key is released by removing it from the
        // dictionary
        NSString* fromIntersection = key.firstObject;
        NSString* toIntersection = key.lastObject;
        NSArray* pointsWithChangedMarkup = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];

        [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];

        return pointsWithChangedMarkup;
      }
    }
  }

  return nil;
}

#pragma mark - Erase markup

// -----------------------------------------------------------------------------
/// @brief Entry point for handling markup erasing on a single intersection. If
/// a single connection was removed, returns an array with the start/end GoPoint
/// objects of the connection that was removed. If a single symbol or label was
/// removed, returns an array with the GoPoint object from which the symbol or
/// label was removed. If more than one markup element was removed, returns an
/// empty array. Returns @e nil if no markup was removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleEraseMarkupOnIntersection:(NSString*)intersection
                              withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  // Usually only one symbol, marker, label or connection is erased; in that
  // case we can tell the rest of the application about this => drawing will
  // be optimized. If many markup items are erased then the information becomes
  // too complex to parse, so we don't provide the information and let the
  // entire board redraw its symbol layers.
  bool singleOrNoMarkupWasErased = true;
  NSArray* pointsWithChangedMarkup = nil;

  NSDictionary* symbols = nodeMarkup.symbols;
  if (symbols && symbols[intersection])
  {
    [nodeMarkup removeSymbolAtVertex:intersection];

    if (pointsWithChangedMarkup)
      singleOrNoMarkupWasErased = false;
    else
      pointsWithChangedMarkup = [self pointsArrayWithIntersection:intersection];
  }

  NSDictionary* labels = nodeMarkup.labels;
  if (labels && labels[intersection])
  {
    [nodeMarkup removeLabelAtVertex:intersection];

    if (pointsWithChangedMarkup)
      singleOrNoMarkupWasErased = false;
    else
      pointsWithChangedMarkup = [self pointsArrayWithIntersection:intersection];
  }

  NSDictionary* connections = nodeMarkup.connections;
  if (connections)
  {
    for (NSArray* key in connections.allKeys)
    {
      if ([key containsObject:intersection])
      {
        // Use key components before key is released by removing it from the
        // dictionary
        NSString* fromIntersection = key.firstObject;
        NSString* toIntersection = key.lastObject;
        NSArray* localPointsWithChangedMarkup = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];

        [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];

        if (pointsWithChangedMarkup)
          singleOrNoMarkupWasErased = false;
        else
          pointsWithChangedMarkup = localPointsWithChangedMarkup;
      }
    }
  }

  if (singleOrNoMarkupWasErased)
    return pointsWithChangedMarkup;
  else
    return @[];
}

// -----------------------------------------------------------------------------
/// @brief Entry point for handling markup erasing in a rectangle defined by
/// the diagonally opposite corner intersections @a fromIntersection and
/// @a toIntersection. If a single connection was removed, returns an array with
/// the start/end GoPoint objects of the connection that was removed. If a
/// single symbol or label was removed, returns an array with the GoPoint object
/// from which the symbol or label was removed. If more than one markup element
/// was removed, returns an empty array. Returns @e nil if no markup was
/// removed.
///
/// See document MANUAL for details how this works.
// -----------------------------------------------------------------------------
- (NSArray*) handleEraseMarkupInRectangleFromIntersection:(NSString*)fromIntersection
                                           toIntersection:(NSString*)toIntersection
                                           withNodeMarkup:(GoNodeMarkup*)nodeMarkup
{
  NSArray* pointsArray = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
  GoPoint* fromPoint = pointsArray.firstObject;
  GoPoint* toPoint = pointsArray.lastObject;

  GoGame* game = [GoGame sharedGame];
  NSArray* pointsInSelectionRectangle = [GoUtilities pointsInRectangleDelimitedByCornerPoint:fromPoint
                                                                         oppositeCornerPoint:toPoint
                                                                                      inGame:game];

  // If by chance only one symbol, marker, label or connection is erased
  // then we can tell the rest of the application about this => drawing will
  // be optimized. If many markup items are erased then the information becomes
  // too complex to parse, so we don't provide the information and let the
  // entire board redraw its symbol layers.
  bool singleOrNoMarkupWasErased = true;
  NSArray* pointsWithChangedMarkup = nil;

  for (GoPoint* pointInSelectionRectangle in pointsInSelectionRectangle)
  {
    NSString* intersection = pointInSelectionRectangle.vertex.string;

    NSArray* pointsWithChangedMarkupSingleIntersection = [self handleEraseMarkupOnIntersection:intersection
                                                                                withNodeMarkup:nodeMarkup];

    if (pointsWithChangedMarkupSingleIntersection)
    {
      if (pointsWithChangedMarkup)
        singleOrNoMarkupWasErased = false;
      else
        pointsWithChangedMarkup = pointsWithChangedMarkupSingleIntersection;
    }
  }

  if (singleOrNoMarkupWasErased)
    return pointsWithChangedMarkup;
  else
    return @[];
}

#pragma mark - Private helpers

// -----------------------------------------------------------------------------
/// @brief Private helper. Returns an NSArray with a GoPoint object that
/// corresponds to @a intersection.
// -----------------------------------------------------------------------------
- (NSArray*) pointsArrayWithIntersection:(NSString*)intersection
{
  GoBoard* board = [GoGame sharedGame].board;
  GoPoint* point = [board pointAtVertex:intersection];
  return @[point];
}

// -----------------------------------------------------------------------------
/// @brief Private helper. Returns an NSArray with two GoPoint objects that
/// correspond to @a fromIntersection and @a toIntersection.
// -----------------------------------------------------------------------------
- (NSArray*) pointsArrayWithFromIntersection:(NSString*)fromIntersection
                              toIntersection:(NSString*)toIntersection
{
  GoBoard* board = [GoGame sharedGame].board;
  GoPoint* fromPoint = [board pointAtVertex:fromIntersection];
  GoPoint* toPoint = [board pointAtVertex:toIntersection];
  return @[fromPoint, toPoint];
}

@end
