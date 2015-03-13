//
//  MITMartyResourceSearch.h
//  MIT Mobile
//
//  Created by Blake Skinner on 1/26/15.
//
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMobiusResource;

@interface MITMartyResourceSearch : NSManagedObject

@property (nonatomic, retain) NSString * query;
@property (nonatomic, retain) NSSet *resources;
@end

@interface MITMartyResourceSearch (CoreDataGeneratedAccessors)

- (void)addResourcesObject:(MITMobiusResource *)value;
- (void)removeResourcesObject:(MITMobiusResource *)value;
- (void)addResources:(NSSet *)values;
- (void)removeResources:(NSSet *)values;

@end
