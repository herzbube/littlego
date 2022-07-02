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


// -----------------------------------------------------------------------------
/// @brief Class extension with private properties for
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
@interface HandleMarkupEditingInteractionCommand()
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
/// handles a markup editing interaction on @a point. The type of interaction
/// is defined by @a markupTool and @a markupType. @a markupWasMoved indicates
/// whether the markup is new or has been moved.
///
/// @note This is the designated initializer of
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)point
          markupTool:(enum MarkupTool)markupTool
          markupType:(enum MarkupType)markupType
      markupWasMoved:(bool)markupWasMoved
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.point = point;
  self.labelText = nil;
  self.startPoint = nil;
  self.endPoint = nil;
  self.markupTool = markupTool;
  self.markupType = markupType;
  self.markupWasMoved = markupWasMoved;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// places a marker or label with @a labelText at @a point. The type of
/// interaction is defined by @a markupTool and @a markupType. @a markupWasMoved
/// indicates whether the markup is new or has been moved.
///
/// @note This is the designated initializer of
/// HandleMarkupEditingInteractionCommand.
// -----------------------------------------------------------------------------
- (id) initWithPoint:(GoPoint*)point
           labelText:(NSString*)labelText
          markupTool:(enum MarkupTool)markupTool
          markupType:(enum MarkupType)markupType
      markupWasMoved:(bool)markupWasMoved
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.point = point;
  self.labelText = labelText;
  self.startPoint = nil;
  self.endPoint = nil;
  self.markupTool = markupTool;
  self.markupType = markupType;
  self.markupWasMoved = markupWasMoved;

  return self;
}

// -----------------------------------------------------------------------------
/// @brief Initializes a HandleMarkupEditingInteractionCommand object that
/// handles a markup editing interaction from @a startPoint to @a endPoint.
/// The type of interaction is defined by @a markupTool and @a markupType.
//  @a markupWasMoved indicates whether the markup is new or has been moved.
// -----------------------------------------------------------------------------
- (id) initWithStartPoint:(GoPoint*)startPoint
                 endPoint:(GoPoint*)endPoint
               markupTool:(enum MarkupTool)markupTool
               markupType:(enum MarkupType)markupType
           markupWasMoved:(bool)markupWasMoved
{
  // Call designated initializer of superclass (CommandBase)
  self = [super init];
  if (! self)
    return nil;

  self.point = nil;
  self.labelText = nil;
  self.startPoint = startPoint;
  self.endPoint = endPoint;
  self.markupTool = markupTool;
  self.markupType = markupType;
  self.markupWasMoved = markupWasMoved;

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

  if (self.point)
  {
    if (self.markupTool == MarkupToolLabel)
    {
      if (self.labelText)
      {
        [self handleMarkupEditingInteractionOnPoint:self.point
                                optionalSecondPoint:nil
                                     withMarkupTool:self.markupTool
                                         markupType:self.markupType
                                          labelText:self.labelText
                                     markupWasMoved:self.markupWasMoved
                                               node:currentNode];
      }
      else
      {
        [self handleEnterNewLabelTextOnPoint:self.point
                              withMarkupTool:self.markupTool
                                  markupType:self.markupType
                              markupWasMoved:self.markupWasMoved
                                        node:currentNode];
      }
    }
    else
    {
      [self handleMarkupEditingInteractionOnPoint:self.point
                              optionalSecondPoint:nil
                                   withMarkupTool:self.markupTool
                                       markupType:self.markupType
                                        labelText:nil
                                   markupWasMoved:self.markupWasMoved
                                             node:currentNode];
    }
  }
  else
  {
    [self handleMarkupEditingInteractionOnPoint:self.startPoint
                            optionalSecondPoint:self.endPoint
                                 withMarkupTool:self.markupTool
                                     markupType:self.markupType
                                      labelText:nil
                                 markupWasMoved:self.markupWasMoved
                                           node:currentNode];
  }

  return true;
}

#pragma mark - Helpers for doIt

// -----------------------------------------------------------------------------
/// @brief Performs the actual markup editing interaction handling. Is called
/// both from doIt() and after the user entered a new label text when the
/// markup tool is #MarkupToolLabel.
// -----------------------------------------------------------------------------
- (void) handleMarkupEditingInteractionOnPoint:(GoPoint*)point
                           optionalSecondPoint:(GoPoint*)secondPoint
                                withMarkupTool:(enum MarkupTool)markupTool
                                    markupType:(enum MarkupType)markupType
                                     labelText:(NSString*)labelText
                                markupWasMoved:(bool)markupWasMoved
                                          node:(GoNode*)node
{
  bool applicationStateDidChange = false;

  @try
  {
    [[ApplicationStateManager sharedManager] beginSavePoint];

    NSString* intersection = point.vertex.string;
    GoNodeMarkup* nodeMarkup = node.goNodeMarkup;

    NSArray* pointsWithChangedMarkup = nil;

    switch (markupTool)
    {
      case MarkupToolSymbol:
      {
        bool markupDataDidChange = [self handlePlaceSymbol:markupType onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolMarker:
      {
        bool markupDataDidChange;
        if (labelText)
          markupDataDidChange = [self handlePlaceLabel:labelText onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        else
          markupDataDidChange = [self handlePlaceMarker:markupType onIntersection:intersection withNodeMarkup:nodeMarkup];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolLabel:
      {
        bool markupDataDidChange = [self handlePlaceLabel:labelText onIntersection:intersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
        if (markupDataDidChange)
          pointsWithChangedMarkup = @[point];
        break;
      }
      case MarkupToolConnection:
      {
        if (secondPoint)
        {
          NSString* fromIntersection = intersection;
          NSString* toIntersection = secondPoint.vertex.string;
          bool markupDataDidChange = [self handlePlaceConnection:markupType fromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup markupWasMoved:markupWasMoved];
          if (markupDataDidChange)
            pointsWithChangedMarkup = @[point, secondPoint];
        }
        else
        {
          pointsWithChangedMarkup = [self handleRemoveConnectionIfExistsAtIntersection:intersection withNodeMarkup:nodeMarkup];
        }
        break;
      }
      case MarkupToolEraser:
      {
        if (secondPoint)
        {
          NSString* fromIntersection = intersection;
          NSString* toIntersection = secondPoint.vertex.string;
          pointsWithChangedMarkup = [self handleEraseMarkupInRectangleFromIntersection:fromIntersection toIntersection:toIntersection withNodeMarkup:nodeMarkup];
        }
        else
        {
          pointsWithChangedMarkup = [self handleEraseMarkupOnIntersection:intersection withNodeMarkup:nodeMarkup];
        }
        break;
      }
      default:
      {
        applicationStateDidChange = false;
        NSString* errorMessage = [NSString stringWithFormat:@"Failed to handle markup editing interaction, unsupported markup tool: %d (markup type = %d)", markupTool, markupType];
        DDLogError(@"%@: %@", self, errorMessage);
        NSException* exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                         reason:errorMessage
                                                       userInfo:nil];
        @throw exception;
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

  if (pointsWithChangedMarkup.count == 2)
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
                                                      onIntersection:intersection
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
/// handleMarkupEditingInteractionOnPoint:optionalSecondPoint:withMarkupTool:markupType:labelText:node:(),
/// because the latter wraps the invocation of its handler methods into a pair
/// of beginSavePoint/commitSavePoint method calls, which requires the handler
/// method to work synchronously. This method does not work synchronously, it
/// presents EditTextDelegate.
// -----------------------------------------------------------------------------
- (void) handleEnterNewLabelTextOnPoint:(GoPoint*)point
                         withMarkupTool:(enum MarkupTool)markupTool
                             markupType:(enum MarkupType)markupType
                         markupWasMoved:(bool)markupWasMoved
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
  editTextController.context = @[point, [NSNumber numberWithInt:markupTool], [NSNumber numberWithInt:markupType], [NSNumber numberWithBool:markupWasMoved], node];

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
    NSArray* context = editTextController.context;
    GoPoint* point = [context objectAtIndex:0];
    enum MarkupTool markupTool = [[context objectAtIndex:1] intValue];
    enum MarkupType markupType = [[context objectAtIndex:2] intValue];
    bool markupWasMoved = [[context objectAtIndex:3] boolValue];
    GoNode* node = [context objectAtIndex:4];

    NSString* labelText = editTextController.text;

    [self handleMarkupEditingInteractionOnPoint:point
                            optionalSecondPoint:nil
                                 withMarkupTool:markupTool
                                     markupType:markupType
                                      labelText:labelText
                                 markupWasMoved:markupWasMoved
                                           node:node];
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
        NSString* fromIntersection = key.firstObject;
        NSString* toIntersection = key.lastObject;
        [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];
        return [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
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
        NSString* fromIntersection = key.firstObject;
        NSString* toIntersection = key.lastObject;
        [nodeMarkup removeConnectionFromVertex:fromIntersection toVertex:toIntersection];

        if (pointsWithChangedMarkup)
          singleOrNoMarkupWasErased = false;
        else
          pointsWithChangedMarkup = [self pointsArrayWithFromIntersection:fromIntersection toIntersection:toIntersection];
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

    if (pointsWithChangedMarkup)
      singleOrNoMarkupWasErased = false;
    else
      pointsWithChangedMarkup = pointsWithChangedMarkupSingleIntersection;
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
