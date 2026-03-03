// -----------------------------------------------------------------------------
// Copyright 2025 Patrick Näf (herzbube@herzbube.ch)
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


// Forward declarations
@class ArchiveViewModel;
@class BoardPositionModel;
@class BoardSetupModel;
@class BoardViewMetrics;
@class BoardViewModel;
@class CrashReportingModel;
@class GameVariationModel;
@class GtpCommandModel;
@class GtpEngineProfileModel;
@class GtpLogModel;
@class LoggingModel;
@class MagnifyingViewModel;
@class MarkupModel;
@class MiscellaneousModel;
@class NewGameModel;
@class NodeTreeViewModel;
@class PlayerModel;
@class ScoringModel;
@class SgfSettingsModel;
@class SoundHandling;
@class UiSettingsModel;
@class TimedPlayModel;


// -----------------------------------------------------------------------------
/// @brief The ModelProvider protocol provides access to all of the
/// application's model objects.
// -----------------------------------------------------------------------------
@protocol ModelProvider

/// @brief Model object that stores attributes of a new game.
@property(nonatomic, retain) NewGameModel* theNewGameModel;
/// @brief Model object that stores player data.
@property(nonatomic, retain) PlayerModel* playerModel;
/// @brief Model object that stores GTP engine profile data.
@property(nonatomic, retain) GtpEngineProfileModel* gtpEngineProfileModel;
/// @brief Model object that stores attributes used to manage the view hierarchy
/// that displays the Go board.
@property(nonatomic, retain) BoardViewModel* boardViewModel;
/// @brief Model object that calculates locations and sizes of Go board elements
/// as they are seen in the view hierarchy that displays the Go board.
@property(nonatomic, retain) BoardViewMetrics* boardViewMetrics;
/// @brief Model object that stores properties that define how the Go board
/// displays board positions.
@property(nonatomic, retain) BoardPositionModel* boardPositionModel;
/// @brief Model object that stores attributes used for scoring.
@property(nonatomic, retain) ScoringModel* scoringModel;
/// @brief Object that handles sounds and vibration.
@property(nonatomic, retain) SoundHandling* soundHandling;
/// @brief Model object that stores attributes used to manage the Archive view.
@property(nonatomic, retain) ArchiveViewModel* archiveViewModel;
/// @brief Model object that stores information about the GTP log, viewable on
/// the Diagnostics view.
@property(nonatomic, retain) GtpLogModel* gtpLogModel;
/// @brief Model object that stores canned GTP commands that can be managed and
/// submitted on the Diagnostics view.
@property(nonatomic, retain) GtpCommandModel* gtpCommandModel;
/// @brief Model object that stores attributes that describe the behaviour of
/// the crash reporting service.
@property(nonatomic, retain) CrashReportingModel* crashReportingModel;
/// @brief Model object that stores attributes that are relevant for the
/// logging service.
@property(nonatomic, retain) LoggingModel* loggingModel;
/// @brief Model object that stores attributes relating to the general user
/// interface appearance.
@property(nonatomic, retain) UiSettingsModel* uiSettingsModel;
/// @brief Model object that stores attributes relating to the magnifying
/// glass functionality.
@property(nonatomic, retain) MagnifyingViewModel* magnifyingViewModel;
/// @brief Model object that stores attributes related to the game setup prior
/// to the first move.
@property(nonatomic, retain) BoardSetupModel* boardSetupModel;
/// @brief Model object that stores attributes related to the processing of
/// SGF content.
@property(nonatomic, retain) SgfSettingsModel* sgfSettingsModel;
/// @brief Model object that stores attributes related to viewing and placing
/// markup on the board.
@property(nonatomic, retain) MarkupModel* markupModel;
/// @brief Model object that stores attributes used to manage the view hierarchy
/// that displays the node tree view.
@property(nonatomic, retain) NodeTreeViewModel* nodeTreeViewModel;
/// @brief Model object that stores attributes related to game variations.
@property(nonatomic, retain) GameVariationModel* gameVariationModel;
/// @brief Model object that stores attributes related to timed play.
@property(nonatomic, retain) TimedPlayModel* timedPlayModel;
/// @brief Model object that stores attributes related to miscellaneous topics.
@property(nonatomic, retain) MiscellaneousModel* miscellaneousModel;

@end
