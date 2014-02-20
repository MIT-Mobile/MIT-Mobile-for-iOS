#import <Foundation/Foundation.h>
#import <libkern/OSAtomic.h>
#import "DDLog.h"

@class DispatchQueueLogFormatter;

@interface MITLogFormatter : DDDispatchQueueLogFormatter
- (id)init;

@end
