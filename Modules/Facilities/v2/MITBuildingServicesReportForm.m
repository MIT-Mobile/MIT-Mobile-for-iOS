//
//  MITBuildingServicesReportForm.m
//  MIT Mobile
//
//

#import "MITBuildingServicesReportForm.h"

@implementation MITBuildingServicesReportForm

+ (MITBuildingServicesReportForm *)sharedServiceReport
{
    static MITBuildingServicesReportForm *sharedReport = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedReport = [[self alloc] init];
    });
    
    return sharedReport;
}

- (void)setLocation:(FacilitiesLocation *)location shouldSetRoom:(BOOL)shouldSetRoom
{
    self.location = location;
    
    self.shouldSetRoom = shouldSetRoom;
}

- (void)clearAll
{
    self.location = nil;
}

@end
