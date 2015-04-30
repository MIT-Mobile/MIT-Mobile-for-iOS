#import <Foundation/Foundation.h>

@class MITMobiusResourceDataSource;
@class MITMobiusAttributesDataSource;

@interface MITMobiusDataSource : NSObject
@property (nonatomic,strong) MITMobiusResourceDataSource *resourceDataSource;
@property (nonatomic,strong) MITMobiusAttributesDataSource *attributesDataSource;

+ (NSURL*)mobiusServerURL;

@end
