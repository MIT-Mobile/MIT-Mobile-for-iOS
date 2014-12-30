#import "MITTelephoneHandler.h"

@interface MITTelephoneHandler () <UIAlertViewDelegate>
@property (nonatomic, strong, readonly) NSString *formattedPhoneNumber;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic, strong) NSURL *phoneURL;
@end

@implementation MITTelephoneHandler

#pragma mark - Singleton

+ (instancetype)sharedHandler
{
    static dispatch_once_t onceToken;
    static MITTelephoneHandler *sharedHandler = nil;
    dispatch_once(&onceToken, ^{
        sharedHandler = [MITTelephoneHandler new];
    });
    return sharedHandler;
}

#pragma mark - Caller

+ (void)attemptToCallPhoneNumber:(NSString *)phoneNumber
{
    MITTelephoneHandler *sharedHandler = [self sharedHandler];
    phoneNumber = [self convertLettersToPhoneDigitsInPhoneNumber:phoneNumber];
    NSCharacterSet *nonNumericCharacterSet = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    NSArray *components = [phoneNumber componentsSeparatedByCharactersInSet:nonNumericCharacterSet];
    phoneNumber = [components componentsJoinedByString:@""];
    sharedHandler.phoneNumber = phoneNumber;
    NSString *phoneURLString = [NSString stringWithFormat:@"tel:%@", phoneNumber];
    NSURL *phoneURL = [NSURL URLWithString:phoneURLString];
    sharedHandler.phoneURL = phoneURL;
    if ([[UIApplication sharedApplication] canOpenURL:phoneURL]) {
        [self showConfirmationDialogue];
    } else {
        NSLog(@"MITTelephoneHandler: Unable to open phoneURL: %@", phoneURL);
        sharedHandler.phoneNumber = nil;
        sharedHandler.phoneURL = nil;
    }
}

+ (NSString *)convertLettersToPhoneDigitsInPhoneNumber:(NSString *)phoneNumber
{
    NSDictionary *charactersToNumbersDictionary = @{
                                                    @"2" : @"aAbBcC",
                                                    @"3" : @"dDeEfF",
                                                    @"4" : @"gGhHiI",
                                                    @"5" : @"jJkKlL",
                                                    @"6" : @"mMnNoO",
                                                    @"7" : @"pPqQrRsS",
                                                    @"8" : @"tTuUvV",
                                                    @"9" : @"wWxXyYzZ"
                                                    };
    
    for (NSString *key in charactersToNumbersDictionary.allKeys) {
        NSString *characters = charactersToNumbersDictionary[key];
        NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:characters];
        NSArray *comps = [phoneNumber componentsSeparatedByCharactersInSet:characterSet];
        phoneNumber = [comps componentsJoinedByString:key];
    }

    return phoneNumber;
}

+ (void)showConfirmationDialogue
{
    MITTelephoneHandler *sharedHandler = [self sharedHandler];
    NSString *title = [NSString stringWithFormat:@"Call %@?", sharedHandler.formattedPhoneNumber];
    NSString *cancel = @"Cancel";
    NSString *confirm = @"Ok";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:nil delegate:sharedHandler cancelButtonTitle:cancel otherButtonTitles:confirm, nil];
    [alert show];
}

#pragma mark - Getters | Setters

- (NSString *)formattedPhoneNumber
{
    if (!self.phoneNumber) {
        return nil;
    }
    
    NSUInteger length = self.phoneNumber.length;
    BOOL hasLeadingOne = length > 0 && [self.phoneNumber characterAtIndex:0] == '1';
    
    if (length == 0 || (length > 10 && !hasLeadingOne) || (length > 11)) {
        return self.phoneNumber;
    }
    
    NSUInteger index = 0;
    NSMutableString *formattedString = [NSMutableString string];
    
    if (hasLeadingOne) {
        [formattedString appendString:@"1 "];
        index += 1;
    }
    
    if (length - index > 3) {
        NSString *areaCode = [self.phoneNumber substringWithRange:NSMakeRange(index, 3)];
        [formattedString appendFormat:@"(%@) ",areaCode];
        index += 3;
    }
    
    if (length - index > 3) {
        NSString *prefix = [self.phoneNumber substringWithRange:NSMakeRange(index, 3)];
        [formattedString appendFormat:@"%@-",prefix];
        index += 3;
    }
    
    NSString *remainder = [self.phoneNumber substringFromIndex:index];
    [formattedString appendString:remainder];
    
    return formattedString;
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        [[UIApplication sharedApplication] openURL:self.phoneURL];
    }
    self.phoneURL = nil;
    self.phoneNumber = nil;
}

@end
