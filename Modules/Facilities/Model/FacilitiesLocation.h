//
//  FacilitiesLocation.h
//  MIT Mobile
//
//  Created by Blake Skinner on 5/11/11.
//  Copyright (c) 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class FacilitiesRoom;

@interface FacilitiesLocation : NSManagedObject {
@private
}
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSString * uid;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSDate * roomsUpdated;
@property (nonatomic, retain) NSSet* categories;

@end
