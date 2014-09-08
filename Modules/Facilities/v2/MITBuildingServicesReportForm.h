//
//  MITBuildingServicesReportForm.h
//  MIT Mobile
//
//

#import <Foundation/Foundation.h>

#import "FacilitiesLocation.h"

@interface MITBuildingServicesReportForm : NSObject

@property (nonatomic, strong) FacilitiesLocation *location;

+ (MITBuildingServicesReportForm *)sharedServiceReport;

- (void)clearAll;

@end
