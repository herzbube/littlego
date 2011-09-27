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
#import "../CommandBase.h"


// -----------------------------------------------------------------------------
/// @brief The BackupGameCommand class is responsible for backing up the game
/// that is currently in progress in the event that the application is put in
/// the background by the application.
///
/// BackupGameCommand writes an .sgf file to a fixed location in the
/// application's library folder. Because the backup file is not in the shared
/// document folder, it is not visible/accessible in iTunes.
///
/// @see RestoreGameCommand.
///
/// @note BackupGameCommand executes asynchronously in a secondary thread.
///
///
/// @par Gory implementation details
///
/// The reason for having a proper thread main loop and several subtasks is
/// that the response to the savesgf GTP command cannot be delivered otherwise.
///
/// The initial implementation of BackupGameCommand used an NSBlockOperation to
/// run the background task, but this resulted in the loss of the GtpResponse
/// object, and GtpClient being unable to post
/// #gtpResponseWasReceivedNotification.
///
/// The reason for these problems:
/// - The secondary thread created by NSBlockOperation ended as soon as the
///   GtpCommand had finished executing
/// - GtpClient earlier had queued a performSelector: for the secondary thread
/// - But the selector was, of course, never performed because the thread had
///   already exited
///
/// The solution for this problem was to create a thread that keeps executing
/// its run loop long enough so that the queued performSelector: has a chance
/// to execute.
///
/// To bring a semblance of order and architecture into this mess, the command
/// implementation uses the concept of "subtasks":
/// - Subtask 1 is the actual main background task: Submitting the "savesgf"
///   command to the GTP engine.
/// - Subtask 2 is the actual subtask: Waiting for the GTP response.
/// The main task is ended when the last subtask finishes its work.
// -----------------------------------------------------------------------------
@interface BackupGameCommand : CommandBase
{
}

- (id) init;

@end
