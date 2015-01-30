// -----------------------------------------------------------------------------
// Copyright 2011-2013 Patrick Näf (herzbube@herzbube.ch)
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
#import "UIDeviceAdditions.h"


@implementation UIDevice(UIDeviceAdditions)

// -----------------------------------------------------------------------------
/// @brief Returns a list of device suffixes, one suffix for each device
/// supported by this application. The list has no particular order.
// -----------------------------------------------------------------------------
+ (NSArray*) deviceSuffixes;
{
  static NSArray* deviceSuffixes = nil;
  if (! deviceSuffixes)
    deviceSuffixes = [[NSArray arrayWithObjects:iPhoneDeviceSuffix, iPadDeviceSuffix, nil] retain];
  return deviceSuffixes;
}

// -----------------------------------------------------------------------------
/// @brief Returns a device-specific suffix that matches the current device
/// type.
///
/// The suffix string returned by this method can be used to mimick the
/// behaviour of the system for Info.plist keys or other ressources, where a
/// client can specify a base name only and the system will automatically tack
/// on a device specific suffix such as "~ipad" or "~iphone".
// -----------------------------------------------------------------------------
+ (NSString*) currentDeviceSuffix
{
  static NSString* currentDeviceSuffix = nil;
  if (! currentDeviceSuffix)
  {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
      currentDeviceSuffix = iPhoneDeviceSuffix;
    else
      currentDeviceSuffix = iPadDeviceSuffix;
  }
  return currentDeviceSuffix;
}

// -----------------------------------------------------------------------------
/// @brief Returns the major system version number. For instance, if the system
/// version is 5.1.1 this returns 5.
// -----------------------------------------------------------------------------
+ (int) systemVersionMajor
{
  static int systemVersionMajor = -1;
  if (-1 == systemVersionMajor)
  {
    NSString* systemVersion = [[UIDevice currentDevice] systemVersion];
    NSArray* systemVersionParts = [systemVersion componentsSeparatedByString:@"."];
    NSString* systemVersionMajorString = [systemVersionParts objectAtIndex:0];
    systemVersionMajor = [systemVersionMajorString intValue];
  }
  return systemVersionMajor;
}

// -----------------------------------------------------------------------------
/// @brief Returns the amount of physical memory in Megabytes that is available
/// on this device.
// -----------------------------------------------------------------------------
+ (int) physicalMemoryMegabytes
{
  unsigned long long physicalMemoryBytes = [NSProcessInfo processInfo].physicalMemory;
  unsigned long long physicalMemoryMegaBytes = (physicalMemoryBytes / 1024 / 1024);
  // Cast is required because unsigned long long and int differ in size in
  // 64-bit. Cast is safe because it is extremely unlikely that a device will
  // have more than pow(2, 31) Megabytes of memory (= 2048 Gigabytes) in the
  // foreseeable future.
  return (int)physicalMemoryMegaBytes;
}

@end
