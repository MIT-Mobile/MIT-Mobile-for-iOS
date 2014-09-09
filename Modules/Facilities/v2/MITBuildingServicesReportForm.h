//
//  MITBuildingServicesReportForm.h
//  MIT Mobile
//
//

#import <Foundation/Foundation.h>

#import "FacilitiesLocation.h"
#import "FacilitiesRepairType.h"

@interface MITBuildingServicesReportForm : NSObject

@property (nonatomic, strong) FacilitiesLocation *location;
@property (nonatomic, strong) FacilitiesRepairType *problemType;

+ (MITBuildingServicesReportForm *)sharedServiceReport;

- (void)clearAll;

@end
