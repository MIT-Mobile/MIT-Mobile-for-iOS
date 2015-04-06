#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "MITManagedObject.h"
#import "MITMappedObject.h"

@class MITMobiusResource;

typedef NS_ENUM(NSInteger, MITMobiusImageSize) {
    MITMobiusImageSmall = 0,
    MITMobiusImageMedium,
    MITMobiusImageLarge,
    MITMobiusImageOriginal
};

@interface MITMobiusImage : MITManagedObject <MITMappedObject>

@property (nonatomic, retain) NSString * identifier;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) MITMobiusResource *resource;

- (NSURL*)URLForImageWithSize:(MITMobiusImageSize)imageSize;
@end
