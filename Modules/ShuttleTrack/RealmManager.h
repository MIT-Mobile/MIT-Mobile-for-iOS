//
//  RealmManager.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>

// TODO: Make this a category instead

@interface RealmManager : NSObject
+ (RLMRealm *)shuttlesRealm;
@end
