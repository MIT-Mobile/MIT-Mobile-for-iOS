//
//  PDNetworking.h
//  PlayDoh
//
//  Created by Logan Wright on 2/20/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Foundation/Foundation.h>

@class PDEndpoint;

@interface PDNetworking : NSObject

+ (void)getForEndpoint:(PDEndpoint *)endpoint
        withCompletion:(void(^)(id object, NSError *error))completion;

+ (void)putForEndpoint:(PDEndpoint *)endpoint
        withCompletion:(void(^)(id object, NSError *error))completion;

+ (void)postForEndpoint:(PDEndpoint *)endpoint
         withCompletion:(void(^)(id object, NSError *error))completion;

+ (void)patchForEndpoint:(PDEndpoint *)endpoint
          withCompletion:(void(^)(id object, NSError *error))completion;

+ (void)deleteForEndpoint:(PDEndpoint *)endpoint
          withCompletion:(void(^)(id object, NSError *error))completion;

@end

