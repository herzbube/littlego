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
/// @brief The UserDefaultsUpdater class manages the upgrade of the current set
/// of user defaults stored on the device to a newer format that matches the
/// format of the registration domain defaults, or factory defaults, deployed
/// with the current version of the application.
///
/// @ingroup utility
///
/// When a new version of an application is installed on a device, it may be
/// accompanied with a set of registration domain defaults, or factory defaults,
/// that have a different structure than the set of user defaults currently
/// stored on the device by the previous version of the application. The
/// difference might simply be a key that has been added or removed, or it
/// might be very complex and involve a complete reorganization of the user
/// defaults data.
///
/// Regardless of the nature of the change, it is desirable for code that
/// accesses the user defaults system that it can rely on the data structure
/// having a certain structure, namely the structure that it was developed
/// for during the last application development cycle. The task of
/// UserDefaultsUpdater therefore is to detect if a structural change has
/// taken place in the user defaults system, and to upgrade the user defaults
/// data to the new version. so that the rest of the application code does not
/// have to deal with this issue.
///
/// In order to be able to perform this task, UserDefaultsUpdater must be
/// triggered as early as possible during the application launch cycle, before
/// any other application code accesses the user defaults system. It is also
/// vital that the upgrade process is performed @e BEFORE the registration
/// domain defaults are added to the user defaults system.
///
///
/// @par Upgrading details
///
/// UserDefaultsUpdater performs the upgrade in a non-destructive manner, i.e.
/// existing user defaults are preserved if possible.
///
/// Despite this, UserDefaultsUpdater is capable of performing upgrades across
/// multiple versions of user defaults data (not just from the previous
/// version). Upgrades are performed incrementally to make this task easier.
///
///
/// @ The user defaults format version number
///
/// To find out if upgrades need to be performed, UserDefaultsUpdater compares
/// the format version of the current user defaults to the target format version
/// supplied to the upgrade:() method. The current user defaults format version
/// is determined by reading the key #userDefaultsVersionApplicationDomainKey
/// from the application domain.
///
/// If the two version numbers are the same, no upgrade is needed. If the target
/// version supplied to the upgrade:() method is higher, one or more incremental
/// upgrades are performed until the application domain data reaches a state
/// that matches the requested target format.
///
/// @note Downgrading is not supported. If the target version supplied to the
/// upgrade:() method is lower than the application domain value,
/// UserDefaultsUpdater tries to recover by performing a destructive downgrade.
/// All current user defaults are lost by this operation.
///
/// The user defaults format version number is an integral number that increases
/// monotonically. The number in effect denotes the version of the user defaults
/// data format, @b not the application version. For this reason, it is not
/// necessary for every new application version to also increase the user
/// defaults format version number.
///
/// UserDefaultsUpdater allows for gaps in the user defaults versioning scheme,
/// e.g. a new application version may go from user defaults format version 3
/// directly to version 5, bypassing version 4.
///
///
/// @par How to implement an incremental upgrade
///
/// An incremental upgrade must be implemented in a private class method of
/// UserDefaultsUpdater whose selector follows the naming scheme
/// @e upgradeToVersion<targetVersion>:().
///
/// For instance, to implement the upgrade to version 12 from the previous
/// version (may or may not be 11), a class method named upgradeToVersion12:()
/// must be implemented.
///
/// When the main method upgrade:() progresses along the upgrade path from the
/// application domain to the registration domain version number, it
/// automatically finds and invokes all upgrade methods that are named
/// according to the above scheme.
///
/// The parameter passed to the class method is an NSDictionary that stores the
/// registration domain defaults.
// -----------------------------------------------------------------------------
@interface UserDefaultsUpdater : NSObject
{
}

+ (int) upgradeToRegistrationDomainDefaults:(NSDictionary*)registrationDomainDefaults;

@end
