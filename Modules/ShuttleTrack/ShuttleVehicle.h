#import <Foundation/Foundation.h>

@interface ShuttleVehicle : NSObject
{
    NSString *_vehicleID;
    double _latitude;
    double _longitude;
    int _heading;
    double _speed;
    int _lastReport;
}

- (void)updateInfo:(NSDictionary *)vehiclesInfo;
- (id)initWithDictionary:(NSDictionary *)dict;

@property (nonatomic, retain) NSString *vehicleID;
@property (assign) double latitude;
@property (assign) double longitude;
@property (assign) int heading;
@property (assign) double speed;
@property (assign) int lastReport;



@end
