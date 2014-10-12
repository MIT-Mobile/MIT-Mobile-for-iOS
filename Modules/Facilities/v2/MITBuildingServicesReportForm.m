//
//  MITBuildingServicesReportForm.m
//  MIT Mobile
//
//

#import "MITTouchstoneController.h"
#import "MITBuildingServicesReportForm.h"
#import "NSString+EmailValidation.h"

NSString * const MITBuildingServicesLocationChosenNoticiation = @"MITBuildingServicesLocationChosenNoticiation";
NSString * const MITBuildingServicesLocationCustomTextNotification = @"MITBuildingServicesLocationCustomTextNotification";

NSString * const MITBuildingServicesEmailKey = @"MITBuildingServicesEmailKey";

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

- (void)setCustomLocation:(NSString *)customLocation
{
    self.location = nil;
    self.shouldSetRoom = NO;
    
    _customLocation = customLocation;
}

- (void)setLocation:(FacilitiesLocation *)location shouldSetRoom:(BOOL)shouldSetRoom
{
    self.location = location;
    
    self.shouldSetRoom = (location == nil ? NO : shouldSetRoom);
    
    // reset the room names when location is changed.
    self.room = nil;
    self.roomAltName = nil;
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

- (NSString *)email
{
    if( _email != nil && _email.length > 0 )
    {
        return _email;
    }
    
    // email is still not set -> check if user is signed in
    NSString *loggedInUserEmail = [[MITTouchstoneController sharedController] userEmailAddress];
    if( loggedInUserEmail != nil && loggedInUserEmail.length > 0 )
    {
        return loggedInUserEmail;
    }
    
    // if user is not logged in and email wasn't typed in manually -> check UserDefaults
    NSString *persistedEmail = [[NSUserDefaults standardUserDefaults] objectForKey:MITBuildingServicesEmailKey];
    if( persistedEmail != nil && persistedEmail.length > 0 )
    {
        return persistedEmail;
    }
    
    // _email must be nil at this point
    return _email;
}

- (BOOL)isValidEmail
{
    return [self.email isValidEmail];
}

// persist email when user submits a form, so that email can be reused next time.
- (void)persistEmail
{
    if( self.email == nil )
    {
        return;
    }
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:self.email forKey:MITBuildingServicesEmailKey];
    [userDefaults synchronize];
}

@end
