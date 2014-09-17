//
//  MITBuildingServicesReportForm.h
//  MIT Mobile
//
//

#import <Foundation/Foundation.h>

#import "FacilitiesLocation.h"
#import "FacilitiesRepairType.h"
#import "FacilitiesRoom.h"

@interface MITBuildingServicesReportForm : NSObject

@property (nonatomic, assign) BOOL shouldSetRoom;
@property (nonatomic, strong) FacilitiesLocation *location;
@property (nonatomic, strong) FacilitiesRepairType *problemType;

@property (nonatomic, strong) FacilitiesRoom *room;
@property (nonatomic, strong) NSString *roomAltName;

@property (nonatomic, strong) NSString *reportDescription;

@property (nonatomic, strong) UIImage *reportImage;

+ (MITBuildingServicesReportForm *)sharedServiceReport;

- (void)setLocation:(FacilitiesLocation *)location shouldSetRoom:(BOOL)shouldSetRoom;
- (void)clearAll;

@end
