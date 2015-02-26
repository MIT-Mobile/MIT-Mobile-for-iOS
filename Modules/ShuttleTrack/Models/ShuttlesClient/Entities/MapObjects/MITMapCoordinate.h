//
//  MITMapCoordinate.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "RLMObject.h"

@interface MITMapCoordinate : RLMObject
@property double latitude;
@property double longitude;
@end

RLM_ARRAY_TYPE(MITMapCoordinate)
