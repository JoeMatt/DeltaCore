//
//  DeltaCore.h
//  DeltaCore
//
//  Created by Joseph Mattiello on 2/6/23.
//  Copyright (c) 2023 Joseph Mattiello. All rights reserved.
//

#if SWIFT_MODULE
@import Foundation;
#else
#import <Foundation/Foundation.h>
#endif
//! Project version number for DeltaCore.
FOUNDATION_EXPORT double DeltaCoreVersionNumber;

//! Project version string for DeltaCore.
FOUNDATION_EXPORT const unsigned char DeltaCoreVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <DeltaCore/PublicHeader.h>
typedef NSString *GameType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *CheatType NS_TYPED_EXTENSIBLE_ENUM;
typedef NSString *GameControllerInputType NS_TYPED_EXTENSIBLE_ENUM;

extern NSNotificationName _Nonnull const DeltaRegistrationRequestNotification;


#if __has_include(<UIKit/UIKit.h>)
#import <UIKit/UIKit.h>

// Used by GameWindow.
@interface UIWindow (Private)

@property (nullable, weak, nonatomic, setter=_setLastFirstResponder:) UIResponder *_lastFirstResponder /* API_AVAILABLE(ios(16)) */;
- (void)_restoreFirstResponder /* API_AVAILABLE(ios(16)) */;

@end
#elif __has_include(<AppKit/AppKit.h>)
#import <AppKit/AppKit.h>
// Used by GameWindow.
@interface NSWindow (Private)

@property (nullable, weak, nonatomic, setter=_setLastFirstResponder:) NSResponder *_lastFirstResponder /* API_AVAILABLE(ios(16)) */;
- (void)_restoreFirstResponder /* API_AVAILABLE(ios(16)) */;

@end
#endif
