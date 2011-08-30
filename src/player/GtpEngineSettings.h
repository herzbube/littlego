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



// -----------------------------------------------------------------------------
/// @brief The GtpEngineSettings class collects settings that define the
/// behaviour of the GTP engine for a computer Player. GtpEngineSettings is
/// an optional linear extension of the Player class.
// -----------------------------------------------------------------------------
@interface GtpEngineSettings : NSObject
{
}

- (id) init;
- (id) initWithDictionary:(NSDictionary*)dictionary;
- (NSDictionary*) asDictionary;
- (void) applySettings;

/// @brief The maximum amount of memory in MB that the Fuego GTP engine is
/// allowed to consume.
@property int fuegoMaxMemory;
/// @brief The number of threads that the Fuego GTP engine should use for its
/// calculations.
@property int fuegoThreadCount;
/// @brief True if Fuego should play with pondering on.
@property bool fuegoPondering;
/// @brief True if Fuego should reuse the subtree from the previous search.
@property bool fuegoReuseSubtree;

@end
