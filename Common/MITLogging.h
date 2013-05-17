#import "DDLog.h"
#import "DDASLLogger.h"
#import "DDFileLogger.h"
#import "DDTTYLogger.h"
#import "DispatchQueueLogFormatter.h"

#ifdef DEBUG
static const int ddLogLevel = LOG_LEVEL_VERBOSE;
#define MITLogFatal(fmt,...) do { DDLogError(fmt,##__VA_ARGS__); [[NSAssertionHandler currentHandler] handleFailureInFunction:[NSString stringWithCString:__PRETTY_FUNCTION__ encoding:NSUTF8StringEncoding] file:[NSString stringWithCString:__FILE__ encoding:NSUTF8StringEncoding] lineNumber:__LINE__ description:fmt,##__VA_ARGS__]; } while (0)
#else
static const int ddLogLevel = LOG_LEVEL_WARN;
#define MITLogFatal(fmt,...) do { DDLogError(fmt,##__VA_ARGS__); } while (0)
#endif