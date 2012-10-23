#import "MITLogging.h"

void mit_logger_init( void )
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        {
            DDASLLogger *logger = [DDASLLogger sharedInstance];
            logger.logFormatter = [[DispatchQueueLogFormatter alloc] init];
            [DDLog addLogger:logger];
        }
        
#if defined(DEBUG)
        {
            DDTTYLogger *logger = [DDTTYLogger sharedInstance];
            logger.logFormatter = [[DispatchQueueLogFormatter alloc] init];
            [DDLog addLogger:logger];
        }
#endif //DEBUG
        
        DDLogCVerbose(@"Logger initialized!");
    });
}