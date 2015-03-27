// -----------------------------------------------------------------------------
// Copyright 2015 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The MainMenuPresenterDelegate protocol must be adopted by the
/// delegate of MainMenuPresenter.
// -----------------------------------------------------------------------------
@protocol MainMenuPresenterDelegate
- (void) presentMainMenu;
@end


// -----------------------------------------------------------------------------
/// @brief The MainMenuPresenter class provides a shared object that knows how
/// to trigger presentation of the application main menu.
///
/// MainMenuPresenter is a mediator that bridges the gap between two controller
/// objects:
/// - The controller object that is responsible for the UI representation of the
///   Main Menu action
/// - The controller object that is responsible for presenting the main menu
// -----------------------------------------------------------------------------
@interface MainMenuPresenter : NSObject
{
}

+ (MainMenuPresenter*) sharedPresenter;
+ (void) releaseSharedPresenter;

- (void) presentMainMenu:(id)sender;

@property(nonatomic, assign) id<MainMenuPresenterDelegate> mainMenuPresenterDelegate;

@end
