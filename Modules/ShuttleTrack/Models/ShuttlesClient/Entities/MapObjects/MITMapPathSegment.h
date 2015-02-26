//
//  MITMapPathSegment.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import <Realm/Realm.h>
#import "MITMapCoordinate.h"

@interface MITMapPathSegment : RLMObject
@property RLMArray<MITMapCoordinate> *coordinates;
@end

RLM_ARRAY_TYPE(MITMapPathSegment)
