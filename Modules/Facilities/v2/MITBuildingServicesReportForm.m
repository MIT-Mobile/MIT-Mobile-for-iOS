//
//  MITBuildingServicesReportForm.m
//  MIT Mobile
//
//

#import "MITBuildingServicesReportForm.h"
#import "NSString+EmailValidation.h"

NSString * const MITBuildingServicesLocationChosenNoticiation = @"MITBuildingServicesLocationChosenNoticiation";
NSString * const MITBuildingServicesLocationCustomTextNotification = @"MITBuildingServicesLocationCustomTextNotification";

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

- (BOOL)isValidForm
{
    if( self.reportImage == nil )
    {
        return NO;
    }
    
    if( ![self isValidEmail] )
    {
        return NO;
    }
    
    if( self.location == nil && self.customLocation == nil )
    {
        return nil;
    }
    
    if( self.shouldSetRoom && self.room == nil && self.roomAltName == nil )
    {
        return nil;
    }
    
    if( self.reportDescription == nil || [self.reportDescription length] == 0 )
    {
        return nil;
    }
    
    if( self.problemType == nil )
    {
        return nil;
    }
    
    return YES;
}

- (void)setLocation:(FacilitiesLocation *)location shouldSetRoom:(BOOL)shouldSetRoom
{
    self.location = location;
    
    self.shouldSetRoom = (location == nil ? NO : shouldSetRoom);
}

- (void)clearAll
{
    self.email = nil;
    self.location = nil;
    self.customLocation = nil;
    self.reportDescription = nil;
    self.problemType = nil;
    self.room = nil;
    self.roomAltName = nil;
    self.reportImage = nil;
    self.reportImageData = nil;
    self.shouldSetRoom = NO;
}

- (BOOL)isValidEmail
{
    return [self.email isValidEmail];
}

@end
