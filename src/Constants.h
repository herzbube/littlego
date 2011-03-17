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


extern const float gHalfPixel;

enum GoMoveType
{
  PlayMove,
  PassMove,
  ResignMove
};

// -----------------------------------------------------------------------------
/// @name Notifications
// -----------------------------------------------------------------------------
//@{
/// @brief Is sent when a command is submitted to the GTP engine. The GtpCommand
/// instance that is submitted is associated with the notification.
extern NSString* gtpCommandSubmittedNotification;
/// @brief Is sent when a response is received from the GTP engine. The
/// GtpResponse instance that was received is associated with the notification.
extern NSString* gtpResponseReceivedNotification;
/// @brief Is sent to indicate that the GTP engine is no longer idle.
extern NSString* gtpEngineRunningNotification;
/// @brief Is sent to indicate that the GTP engine is idle.
extern NSString* gtpEngineIdleNotification;
//@}
