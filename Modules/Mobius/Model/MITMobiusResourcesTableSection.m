#import "MITMobiusResourcesTableSection.h"
#import "MITMobiusModel.h"
#import "MITAdditions.h"

@implementation MITMobiusResourcesTableSection {
    BOOL _coordinateNeedsUpdate;
    CLLocationCoordinate2D _coordinate;
}

@synthesize hours = _hours;
@synthesize resources = _resources;

- (instancetype)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = [name copy];
        _coordinateNeedsUpdate = YES;
    }

    return self;
}

- (void)addResource:(MITMobiusResource *)resource
{
    NSMutableArray *array = [[NSMutableArray alloc] init];
    if (_resources) {
        [array addObjectsFromArray:_resources];
    }

    [array addObject:resource];
    _resources = [array copy];
    _hours = nil;
    _coordinateNeedsUpdate = YES;
}

- (NSString*)hours
{
    static NSDateFormatter *dateFormatter = nil;
    static dispatch_once_t token;
    dispatch_once(&token, ^{
        dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.timeStyle = NSDateFormatterShortStyle;
        dateFormatter.dateStyle = NSDateFormatterNoStyle;
    });

    if (_hours == nil) {
        NSDate *currentDate = [NSDate date];
        NSMutableOrderedSet *dateRanges = [[NSMutableOrderedSet alloc] init];
        [_resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
            [resource.hours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *resourceHours, BOOL *stop) {
                NSDate *startDay = [resourceHours.startDate startOfDay];
                NSDate *endDay = [resourceHours.endDate endOfDay];

                // Check to see if today's date is at least on the proper day (or lies between)
                // the min/max values of each range of open hours
                if ([currentDate dateFallsBetweenStartDate:startDay endDate:endDay]) {
                    NSString *hourRange = [NSString stringWithFormat:@"%@ - %@",[dateFormatter stringFromDate:resourceHours.startDate], [dateFormatter stringFromDate:resourceHours.endDate]];
                    [dateRanges addObject:hourRange];
                }
            }];
        }];

        _hours = [[dateRanges array] componentsJoinedByString:@", "];
    }

    return _hours;
}

- (BOOL)isOpen
{
    return [self isOpenForDate:[NSDate date]];
}

- (BOOL)isOpenForDate:(NSDate*)date
{
    NSParameterAssert(date);

    __block BOOL isOpen = NO;
    [_resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
        [resource.hours enumerateObjectsUsingBlock:^(MITMobiusResourceHours *resourceHours, BOOL *stop) {
            isOpen = [date dateFallsBetweenStartDate:resourceHours.startDate endDate:resourceHours.endDate];

            if (isOpen) {
                (*stop) = YES;
            }
        }];

        if (isOpen) {
            (*stop) = YES;
        }
    }];

    return isOpen;
}

- (MITMobiusResource*)objectAtIndexedSubscript:(NSUInteger)idx
{
    return self.resources[idx];
}

#pragma mark MKAnnotation
- (CLLocationCoordinate2D)coordinate
{
    if (_coordinateNeedsUpdate) {
        if (self.resources.count > 0) {
            __block MKMapPoint centroidPoint = MKMapPointMake(0, 0);
            __block NSUInteger pointCount = 0;

            [self.resources enumerateObjectsUsingBlock:^(MITMobiusResource *resource, NSUInteger idx, BOOL *stop) {
                CLLocationCoordinate2D coordinate = resource.coordinate;
                if (CLLocationCoordinate2DIsValid(coordinate)) {
                    MKMapPoint mapCoordinate = MKMapPointForCoordinate(coordinate);
                    centroidPoint.x += mapCoordinate.x;
                    centroidPoint.y += mapCoordinate.y;
                    ++pointCount;
                }
            }];

            if (pointCount > 0) {
                centroidPoint.x /= (double)(pointCount);
                centroidPoint.y /= (double)(pointCount);
                _coordinate = MKCoordinateForMapPoint(centroidPoint);
            } else {
                _coordinate = kCLLocationCoordinate2DInvalid;
            }
        } else {
            _coordinate = kCLLocationCoordinate2DInvalid;
        }

        _coordinateNeedsUpdate = NO;
    }

    return _coordinate;
}

- (NSString*)title
{
    return self.name;
}

- (NSString*)subtitle
{
    return self.hours;
}

@end
