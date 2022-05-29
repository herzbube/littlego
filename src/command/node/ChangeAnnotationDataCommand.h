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
#import "CommandBase.h"

// Forward declarations
@class GoNode;


// -----------------------------------------------------------------------------
/// @brief The ChangeAnnotationDataCommand class is responsible for directing
/// the change of a piece of annotation data associated with a given GoNode.
/// The initializer being used determines which data is being changed. If the
/// new data is the same as the existing data ChangeAnnotationDataCommand does
/// nothing.
///
/// The process consists of the following steps:
/// - Create a GoNodeAnnotation object if none exists yet. In the case of a move
///   valuation change no GoNodeAnnotation object is created because the data
///   is stored in the GoMove object.
/// - Change the data in the GoNodeAnnotation object or, in the case of a move
///   valuation change, in the GoMove object.
/// - Remove the GoNodeAnnotation object if it only contains default data.
/// - Set the document dirty flag.
/// - Post a #nodeAnnotationDataDidChange notification.
/// - Save the application state
// -----------------------------------------------------------------------------
@interface ChangeAnnotationDataCommand : CommandBase
{
}

- (id) initWithNode:(GoNode*)node shortDescription:(NSString*)shortDescription longDescription:(NSString*)longDescription;
- (id) initWithNode:(GoNode*)node boardPositionValuation:(enum GoBoardPositionValuation)boardPositionValuation;
- (id) initWithNode:(GoNode*)node estimatedScoreSummary:(enum GoScoreSummary)scoreSummary value:(double)scoreValue;
- (id) initWithNode:(GoNode*)node boardPositionHotspotDesignation:(enum GoBoardPositionHotspotDesignation)hotspotDesignation;
- (id) initWithNode:(GoNode*)node moveValuation:(enum GoMoveValuation)moveValuation;

@end
