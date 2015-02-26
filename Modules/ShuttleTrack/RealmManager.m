//
//  RealmManager.m
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "RealmManager.h"

static NSString * const ShuttlesRealmName = @"ShuttlesRealm";

@implementation RealmManager

+ (RLMRealm *)shuttlesRealm {
    return [RLMRealm realmWithPath:[self realmPathWithName:ShuttlesRealmName]];
}

+ (NSString *)realmPathWithName:(NSString *)realmName {
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *customRealmPath = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.realm", realmName]];
    return customRealmPath;
}

@end
