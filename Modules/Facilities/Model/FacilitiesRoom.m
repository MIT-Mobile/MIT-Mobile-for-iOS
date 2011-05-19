//
//  FacilitiesRoom.m
//  MIT Mobile
//
//  Created by Blake Skinner on 5/11/11.
//  Copyright (c) 2011 MIT. All rights reserved.
//

#import "FacilitiesRoom.h"
#import "FacilitiesLocation.h"

@implementation FacilitiesRoom
@dynamic floor;
@dynamic number;
@dynamic building;

- (NSString*)displayString {
    return [NSString stringWithFormat:@"%@%03@",self.floor,self.number];
}

- (NSString*)description {
    return [NSString stringWithFormat:@"%@-%@",self.building,[self displayString]];
}

@end
