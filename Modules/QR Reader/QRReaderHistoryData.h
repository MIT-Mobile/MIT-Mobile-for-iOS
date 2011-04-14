//
//  QRReaderHistoryData.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/7/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class QRReaderResult;

@interface QRReaderHistoryData : NSObject {
	NSMutableArray *_results;
}

@property (nonatomic, retain) NSArray *results;
+ (QRReaderHistoryData*)sharedHistory;

- (void)eraseAll;
- (void)eraseResult:(QRReaderResult*)result;

- (QRReaderResult*)scanWithUID:(NSString *)uid;
- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date;
- (QRReaderResult*)insertScanResult:(NSString*)scanResult withDate:(NSDate*)date withImage:(UIImage*)image;

@end
