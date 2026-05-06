// -----------------------------------------------------------------------------
// Copyright 2025-2026 Patrick Näf (herzbube@herzbube.ch)
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
@class FilesystemMonitor;


// -----------------------------------------------------------------------------
/// @brief Enumerates the changes that are detected by FilesystemMonitor.
// -----------------------------------------------------------------------------
enum FilesystemMonitorChangeType
{
  /// @brief The filesystem object's data changed.
  FilesystemMonitorChangeTypeDataChanged,
  /// @brief The filesystem object's metadata changed.
  FilesystemMonitorChangeTypeMetadataChanged,
  /// @brief The filesystem object's size changed.
  FilesystemMonitorChangeTypeSizeChanged,
  /// @brief The filesystem object was renamed.
  FilesystemMonitorChangeTypeRenamed,
  /// @brief The filesystem object was deleted.
  FilesystemMonitorChangeTypeDeleted,
  /// @brief The filesystem object's link count changed.
  FilesystemMonitorChangeTypeObjectLinkCountChanged,
  /// @brief Access to the filesystem object was revoked via the revoke(2)
  /// system call, or the underlying fileystem was unmounted.
  FilesystemMonitorChangeTypeRevoked
};


// -----------------------------------------------------------------------------
/// @brief The delegate of FilesystemMonitor must adopt the
/// FilesystemMonitorDelegate protocol.
// -----------------------------------------------------------------------------
@protocol FilesystemMonitorDelegate <NSObject>
@required
/// @brief Notifies the delegate that @a filesystemMonitor detected a change on
/// @a url. @a changeType indicates what kind of change was detected. This
/// method is guaranteed to be invoked in the context of the main thread.
- (void) filesystemMonitor:(FilesystemMonitor*)filesystemMonitor
            changeOccurred:(enum FilesystemMonitorChangeType)changeType
                       url:(NSURL*)url;
@end


// -----------------------------------------------------------------------------
/// @brief The FilesystemMonitor class monitors a given filesystem object for
/// changes and notifies a delegate about each change.
///
/// Things to keep in mind when using FilesystemMonitor:
/// - FilesystemMonitor can only monitor filesystem objects that exist at the
///   time monitoring is started.
/// - If a filesystem object is deleted after monitoring was started,
///   FilesystemMonitor will no longer receive events from the system and
///   monitoring will effectively stop working.
/// - If a filesystem object is renamed after monitoring was started,
///   FilesystemMonitor will continue to receive events from the system for
///   the renamed object. However, the URL supplied to FilesystemMonitor upon
///   initialization, and that is used to notify the delegate, will continue to
///   refer to the old path. Restarting monitoring will fail because the
///   filesystem object will no longer be available under the old path.
/// - If a filesystem object is a file and it is overwritten after monitoring
///   was started, then monitoring may or may not stop working. For details
///   see the section "Overwriting files" below.
/// - FilesystemMonitor guarantees that the delegate is notified in the context
///   of the main thread.
/// - Once monitoring is started, it must also be stopped, otherwise
///   FilesystemMonitor can never be deallocated.
///
///
/// @par Overwriting files
///
/// If a file is overwritten, i.e. the file content is changed without changing
/// the file's name, the way how the overwrite is done can have an impact on
/// monitoring.
///
/// If the overwrite is done by changing the file's content without touching the
/// file's filesystem entry, the monitoring will continue just fine.
///
/// However, if the overwrite is done by first deleting and then re-creating the
/// file, FilesystemMonitor will see a delete event and, as described above,
/// will stop monitoring.
///
/// To mitigate such deleting overwrite implementations, FilesystemMonitor
/// attempts to restart monitoring after it has seen a delete event. Whether or
/// not this works is a question of timing, specifically the time that elapses
/// between the file being deleted and it being re-created. If
/// FilesystemMonitor's attempt to restart monitoring occurs before the file is
/// re-created, the restart attempt will fail and monitoring will remain
/// stopped.
///
/// At the time of writing this, experiments with different overwrite
/// implementations in the iOS simulator environments on a Silicon Mac have
/// shown the following behaviours:
/// - std::filesystem::copy() performs a non-deleting overwrite.
/// - The command line utility "cp" performs a non-deleting overwrite.
/// - Redirecting in the shell with ">" performs a non-deleting overwrite.
/// - std::filesystem::rename performs a deleting overwrite.
/// - The NSFileManager method
///   replaceItemAtURL:withItemAtURL:backupItemName:options:resultingItemURL:error:()
///   performs a deleting overwrite.
// -----------------------------------------------------------------------------
@interface FilesystemMonitor : NSObject
{
}

- (id) initWithURL:(NSURL*)url delegate:(id<FilesystemMonitorDelegate>)delegate;

- (bool) startMonitoring;
- (void) stopMonitoring;

@property(nonatomic, assign, readonly) bool isMonitoringStarted;

@end
