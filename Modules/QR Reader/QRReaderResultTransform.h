//
//  QRReaderResultTransform.h
//  MIT Mobile
//
//  Created by Blake Skinner on 4/14/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface QRReaderResultTransform : NSObject {
    NSMutableDictionary *_scanTitles;
    NSMutableDictionary *_alternateURLs;
}

+ (QRReaderResultTransform*)sharedTransform;

- (BOOL)scanHasTitle:(NSString*)string;
- (NSString*)titleForScan:(NSString*)string;
- (NSString*)alternateTextForScan:(NSString*)string;


@end
