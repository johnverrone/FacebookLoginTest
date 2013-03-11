//
//  MyTokenCachingStrategy.h
//  FacebookLoginTest
//
//  Created by John Verrone on 1/28/13.
//  Copyright (c) 2013 John Verrone. All rights reserved.
//

#import <FacebookSDK/FBSessionTokenCachingStrategy.h>
#import <Parse/Parse.h>

@interface MyTokenCachingStrategy : FBSessionTokenCachingStrategy

// In a real app this uniquely identifies the user and is something
// the app knows before an FBSession open is attempted.
@property (nonatomic, strong) NSString *thirdPartySessionId;

@end
