//
//  MITBuildingServicesReportForm.h
//  MIT Mobile
//
//

#import <Foundation/Foundation.h>

#import "FacilitiesLocation.h"
#import "FacilitiesRepairType.h"
#import "FacilitiesRoom.h"

extern NSString * const MITBuildingServicesLocationChosenNoticiation;
extern NSString * const MITBuildingServicesLocationCustomTextNotification;

@interface MITBuildingServicesReportForm : NSObject

// user email (pre-filled or manually typed
@property (nonatomic, strong) NSString *email;

// location properties
@property (nonatomic, strong) FacilitiesLocation *location;
@property (nonatomic, strong) NSString *customLocation;

@property (nonatomic, strong) FacilitiesRepairType *problemType;

// room properties
@property (nonatomic, assign) BOOL shouldSetRoom;
@property (nonatomic, strong) FacilitiesRoom *room;
@property (nonatomic, strong) NSString *roomAltName;

// description property
@property (nonatomic, strong) NSString *reportDescription;

// image properties
@property (nonatomic, strong) UIImage *reportImage;
@property (nonatomic, strong) NSData *reportImageData;

+ (MITBuildingServicesReportForm *)sharedServiceReport;

- (void)submitFormWithCompletionBlock:(void (^)(NSDictionary *responseObject, NSError *error))completionBlock
                  progressUpdateBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressUpdateBlock;

- (void)setLocation:(FacilitiesLocation *)location shouldSetRoom:(BOOL)shouldSetRoom;

- (void)persistEmail;
- (BOOL)isValidForm;
- (void)clearAll;

@end
