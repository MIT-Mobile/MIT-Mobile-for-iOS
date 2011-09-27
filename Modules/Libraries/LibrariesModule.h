#import <Foundation/Foundation.h>
#import "MITModule.h"


@interface LibrariesModule : MITModule {
    NSOperationQueue *_requestQueue;
}

@property (nonatomic, retain) NSOperationQueue *requestQueue;

@end
