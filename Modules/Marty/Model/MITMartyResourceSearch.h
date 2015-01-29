//
//  MITMartyResourceSearch.h
//  MIT Mobile
//
//  Created by Blake Skinner on 1/26/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMartyResource;

@interface MITMartyResourceSearch : NSManagedObject

@property (nonatomic, retain) NSString * query;
@property (nonatomic, retain) NSSet *resources;
@end

@interface MITMartyResourceSearch (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMartyResource *)value;
- (void)removeResourcesObject:(MITMartyResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
