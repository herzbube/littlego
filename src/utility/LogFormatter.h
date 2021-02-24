// -----------------------------------------------------------------------------
// Copyright 2021 Patrick Näf (herzbube@herzbube.ch)
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
/// @brief Enumerates the styles that can be used to format log messages.
///
/// @ingroup utility
// -----------------------------------------------------------------------------
enum LogFormatStyle
{
  LogFormatStyleWithTimestamp,    ///< @brief Add a timestamp to the log message.
  LogFormatStyleWithoutTimestamp  ///< @brief Do not add a timestamp to the log message.
};

// -----------------------------------------------------------------------------
/// @brief The LogFormatter class adopts the DDLogFormatter protocol to provide
/// an applicatin-specific log formatter for CocoaLumberjack.
///
/// @ingroup utility
// -----------------------------------------------------------------------------
@interface LogFormatter : NSObject <DDLogFormatter>
{
}

- (id) init;
- (id) initWithLogFormatStyle:(enum LogFormatStyle)logFormatStyle;

@end
