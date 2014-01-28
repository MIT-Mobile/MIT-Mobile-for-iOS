#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"

@class MITMapPlace;

@interface MITMapPlaceContent : MITManagedObject

@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) MITMapPlace *building;
@end
