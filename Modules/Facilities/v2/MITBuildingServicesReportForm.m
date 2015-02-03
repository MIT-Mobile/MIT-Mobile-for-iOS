#import "MITTouchstoneController.h"
#import "MITTouchstoneRequestOperation.h"
#import "MITTouchstoneRequestOperation+MITMobileV2.h"

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

- (void)submitFormWithCompletionBlock:(void (^)(NSDictionary *, NSError *))completionBlock
                  progressUpdateBlock:(void (^)(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite))progressUpdateBlock
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithCapacity:8];
    params[@"name"] = @"";
    
    NSString *email = self.email;
    if (email) {
        params[@"email"] = email;
    }
    
    FacilitiesLocation *location = self.location;
    FacilitiesRoom *room = self.room;
    FacilitiesRepairType *type = self.problemType;
    NSString *description = self.reportDescription;
    NSString *customLocation = self.customLocation;
    NSString *customRoom = self.roomAltName;
    
    if (location) {
        params[@"locationName"] = location.name;
        params[@"buildingNumber"] = location.number;
        params[@"location"] = location.uid;
    } else if( customLocation ) {
        params[@"locationNameByUser"] = customLocation;
    }
    
    if (room) {
        params[@"roomName"] = room.number;
    } else if( customRoom ) {
        params[@"roomNameByUser"] = customRoom;
    }
    
    if( type.name ) {
        params[@"problemType"] = type.name;
    }
    
    if( description )
    {
        params[@"message"] = description;
    }
    
    NSData *pictureData = self.reportImageData;
    if (pictureData)
    {
        params[@"image"] = pictureData;
        params[@"imageFormat"] = @"image/jpeg";
    }
    
    NSURLRequest *request = [NSURLRequest requestForModule:@"facilities" command:@"upload" parameters:params method:@"POST"];
    MITTouchstoneRequestOperation *requestOperation = [[MITTouchstoneRequestOperation alloc] initWithRequest:request];
    
    [requestOperation setCompletionBlockWithSuccess:^(MITTouchstoneRequestOperation *operation, NSDictionary *responseObject) {
        if ([responseObject[@"success"] boolValue])
        {
            if( completionBlock ) completionBlock( responseObject, nil );
        }
        else
        {
            if( completionBlock ) completionBlock( responseObject, [NSError errorWithDomain:@"Unknown Error" code:-1 userInfo:nil] );
        }
    } failure:^(MITTouchstoneRequestOperation *operation, NSError *error) {
        if( completionBlock ) completionBlock( nil, error );
    }];
    
    [requestOperation setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if( progressUpdateBlock ) progressUpdateBlock( bytesWritten, totalBytesWritten, totalBytesExpectedToWrite );
    }];
    
    [[NSOperationQueue mainQueue] addOperation:requestOperation];
}

- (BOOL)isValidForm
{    
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
    [self setLocation:nil shouldSetRoom:NO];
    
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
    // Email address should not be validated in this request form.
    // Just verify that some text was entered.
    return self.email != nil && self.email.length > 0;
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
