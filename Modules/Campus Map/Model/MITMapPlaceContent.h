#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class MITMapPlace;

@interface MITMapPlaceContent : NSManagedObject

@property (nonatomic, strong) NSURL * url;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) MITMapPlace *building;

@end
