//
//  UIImage+Metadata.h
//  MIT Mobile
//
//  Created by Yev Motov on 9/15/14.
//
//

#import <UIKit/UIKit.h>

@interface UIImage (Metadata)

- (void)updateMetadata:(NSMutableDictionary *)imageProperties
 withCompletionHandler:(void(^)(NSData *imageData))completionHandler;

@end
