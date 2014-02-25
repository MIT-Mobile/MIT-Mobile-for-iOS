#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MITTestFlightLogger : DDAbstractLogger <DDLogger>
@property (nonatomic,strong) id<DDLogFormatter> logFormatter;
+ (id)sharedInstance;

- (id)init;
- (void)logMessage:(DDLogMessage *)logMessage;
@end
