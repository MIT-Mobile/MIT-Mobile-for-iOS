#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class MITMobiusResource;

@interface MITMobiusResourcesTableSection : NSObject <MKAnnotation>
@property (nonatomic,readonly,copy) NSString *name;
@property (nonatomic,readonly,copy) NSString *hours;
@property (nonatomic,readonly,copy) NSArray *resources;
@property (nonatomic,readonly) BOOL isOpen;

- (instancetype)initWithName:(NSString*)name;
- (void)addResource:(MITMobiusResource*)resource;
- (BOOL)isOpenForDate:(NSDate*)date;
@end
