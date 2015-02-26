//
//  MITMapBoundingBox.h
//  MITShuttleApi
//
//  Created by Logan Wright on 2/25/15.
//  Copyright (c) 2015 LowriDevs. All rights reserved.
//

#import "RLMObject.h"
#import "MITMapCoordinate.h"

@interface MITMapBoundingBox : RLMObject
@property MITMapCoordinate *northWest;
@property MITMapCoordinate *southEast;
@end
