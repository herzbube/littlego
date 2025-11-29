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
/// - FilesystemMonitor guarantees that the delegate is notified in the context
///   of the main thread.
/// - Once monitoring is started, it must also be stopped, otherwise
///   FilesystemMonitor can never be deallocated.
// -----------------------------------------------------------------------------
@interface FilesystemMonitor : NSObject
{
}

- (id) initWithURL:(NSURL*)url delegate:(id<FilesystemMonitorDelegate>)delegate;

- (void) startMonitoring;
- (void) stopMonitoring;

@end
