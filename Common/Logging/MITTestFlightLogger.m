#import "MITTestFlightLogger.h"

@implementation MITTestFlightLogger
+ (id)sharedInstance
{
    static MITTestFlightLogger *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[MITTestFlightLogger alloc] init];
    });
    
    return sharedInstance;
}

- (id)init
{
    self = [super init];
    
    if (self) {
        // No initialization to be done
    }
    
    return self;
}

- (NSString*)loggerName
{
    return @"edu.mit.mobile.MITTestFlightLogger";
}

- (void)logMessage:(DDLogMessage *)logMessage
{
    NSString *logMsg = logMessage->logMsg;
	
	if (formatter) {
		logMsg = [formatter formatLogMessage:logMessage];
	}
	
	if (logMsg) {
		TFLog(@"%@",logMsg);
	}
}

@end
