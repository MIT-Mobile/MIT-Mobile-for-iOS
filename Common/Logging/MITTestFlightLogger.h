//
//  MITTestFlightLogger.h
//  MIT Mobile
//
//  Created by Blake Skinner on 6/7/13.
//
//

#import <Foundation/Foundation.h>
#import "DDLog.h"

@interface MITTestFlightLogger : DDAbstractLogger <DDLogger>
@property (nonatomic,strong) id<DDLogFormatter> logFormatter;
+ (id)sharedInstance;

- (id)init;
- (void)logMessage:(DDLogMessage *)logMessage;
@end
