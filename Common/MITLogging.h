#import <Foundation/Foundation.h>
#ifndef _MIT_LOGGING_
#define _MIT_LOGGING_

/*
 * Log statements that turn to no-ops depending on compiler flags.
 *
 * VLog(@"Hello, World!");
 * DLog(@"Hello, World!");
 * WLog(@"Hello, World!");
 * ELog(@"Hello, World!");
 * 
 * Produces output like:
 *
 * |verbose| [main:68] Hello, World!
 * [main:69] Hello, World!
 * *warning* [main:70] Hello, World!
 * **error** [main:71] Hello, World!
 *
 */

#define MIT_SILENT 0 // Nothing (except for explicit calls to NSLog and printf)
#define MIT_RELEASE 1 // WLog and Elog
#define MIT_DEBUG 2 // DLog plus above
#define MIT_VERBOSE 3 // VLog plus above

// Choose console verbosity at compile time.
// You probably just want to use DLog().
// Define in project build settings under Other C Flags, e.g. -DDEBUG, -DVERBOSE, -DSILENT
#ifdef VERBOSE
    #define MIT_LOG_LEVEL MIT_VERBOSE
#elif DEBUG
    #define MIT_LOG_LEVEL MIT_DEBUG
#elif SILENT
    #define MIT_LOG_LEVEL MIT_SILENT
#else
    #define MIT_LOG_LEVEL MIT_SILENT
#endif

#define MITNSLog(level, fmt, ...) NSLog((@"" level " [%s:%d] " fmt), __FILE__, __LINE__, ##__VA_ARGS__)
#define MITPrintf(level, fmt, ...) MyLog(level, __FILE__, __LINE__, fmt, ##__VA_ARGS__)


// Wrap the function prototype in an extern C
// block if we are compiling this as C++ or
// Objective-C++ otherwise the name mangling
// will kick in and we'll get linking errors
#ifdef __cplusplus
extern "C" {
#endif

void MyLog(const char *level, const char *filepath, int line, NSString *format, ...) NS_FORMAT_FUNCTION(4,5);

#ifdef __cplusplus
}
#endif

// Use MITNSLog to include timestamps and the app's name
// Use MITPrintf for narrower logs
#define MITLog MITPrintf

#if MIT_LOG_LEVEL >= MIT_VERBOSE
    #define VLog(fmt, ...) MITLog("|verbose|", fmt, ##__VA_ARGS__)
#else
    #define VLog(...)
#endif

#if MIT_LOG_LEVEL >= MIT_DEBUG
    #define DLog(fmt, ...) MITLog(NULL, fmt, ##__VA_ARGS__)
#else
    #define DLog(...)
#endif

#if MIT_LOG_LEVEL >= MIT_RELEASE
    #define WLog(fmt, ...) MITLog("*warning*", fmt, ##__VA_ARGS__)
    #define ELog(fmt, ...) MITLog("**error**", fmt, ##__VA_ARGS__)
#else
    #define WLog(...)
    #define ELog(...)
#endif

#endif //_MIT_LOGGING_
