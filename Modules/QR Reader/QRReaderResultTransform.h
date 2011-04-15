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
