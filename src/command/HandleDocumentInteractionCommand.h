// -----------------------------------------------------------------------------
// Copyright 2013 Patrick Näf (herzbube@herzbube.ch)
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


// -----------------------------------------------------------------------------
/// @brief The HandleDocumentInteractionCommand class is responsible for
/// importing an .sgf file that was passed into the application via the
/// system's document interaction mechanism.
///
/// The URL referring to .sgf file is the value of the ApplicationDelegate
/// property @e documentInteractionURL.
///
/// HandleDocumentInteractionCommand displays an alert to the user informing
/// her under which name the imported .sgf file can be found in the archive.
/// Command execution returns while the alert is still displayed.
// -----------------------------------------------------------------------------
@interface HandleDocumentInteractionCommand : CommandBase
{
}

@end
