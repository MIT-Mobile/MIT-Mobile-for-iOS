#import "DDDispatchQueueLogFormatter.h"
#import "MITLogFormatter.h"

@interface DDDispatchQueueLogFormatter ()
- (NSString *)stringFromDate:(NSDate *)date;
- (NSString *)queueThreadLabelForLogMessage:(DDLogMessage *)logMessage;
@end

@implementation MITLogFormatter
- (id)init
{
    self = [super init];
    
    if (self) {
        self->dateFormatString = @"HH:mm:ss";
    }
    return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
    NSString *dateString = [self stringFromDate:logMessage->timestamp];
	NSString *queueThreadLabel = [self queueThreadLabelForLogMessage:logMessage];
    NSString *levelName = @"?";
    
    switch (logMessage->logLevel) {
        case LOG_LEVEL_VERBOSE:
            levelName = @"V";
            break;
        
        case LOG_LEVEL_DEBUG:
            levelName = @"D";
            break;
            
        case LOG_LEVEL_INFO:
            levelName = @"I";
            break;
            
        case LOG_LEVEL_WARN:
            levelName = @"W";
            break;
            
        case LOG_LEVEL_ERROR:
            levelName = @"E";
            break;
    }
	
	return [NSString stringWithFormat:@"%@:(%@):[%@] %@", dateString, levelName, queueThreadLabel, logMessage->logMsg];
}
@end
