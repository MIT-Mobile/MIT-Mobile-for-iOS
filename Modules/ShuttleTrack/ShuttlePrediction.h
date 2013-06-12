#import <Foundation/Foundation.h>

@interface ShuttlePrediction : NSObject
{
    NSString *_vehicleID;
    unsigned long long _timestamp;
    int _seconds;
}

- (void)updateInfo:(NSDictionary *)vehiclesInfo;
- (id)initWithDictionary:(NSDictionary *)dict;

@property (nonatomic, retain) NSString *vehicleID;
@property unsigned long long timestamp;
@property (assign) int seconds;

@end
