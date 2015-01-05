#import <UIKit/UIKit.h>

@interface UIImage (Metadata)

- (void)updateMetadata:(NSMutableDictionary *)imageProperties
 withCompletionHandler:(void(^)(NSData *imageData))completionHandler;

@end
