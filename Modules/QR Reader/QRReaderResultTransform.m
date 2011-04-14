//
//  QRReaderResultTransform.m
//  MIT Mobile
//
//  Created by Blake Skinner on 4/14/11.
//  Copyright 2011 MIT. All rights reserved.
//

#import "QRReaderResultTransform.h"

static QRReaderResultTransform *_sharedResultTransform = nil;

@interface QRReaderResultTransform ()
@property (nonatomic,retain) NSMutableDictionary *scanTitles;
@property (nonatomic,retain) NSMutableDictionary *alternateURLs;
@end

@implementation QRReaderResultTransform
@synthesize scanTitles = _scanTitles;
@synthesize alternateURLs = _alternateURLs;

- (id)init {
    self = [super init];
    
    if (self) {
        self.scanTitles = [NSMutableDictionary dictionary];
        self.alternateURLs = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (BOOL)scanHasTitle:(NSString*)string {
    return ([self.scanTitles objectForKey:string] != nil);
}

- (NSString*)titleForScan:(NSString*)string {
    NSString *title = [self.scanTitles objectForKey:string];
    
    if (title) {
        return [NSString stringWithString:title];
    } else {
        return [NSString stringWithString:string];
    }
}

- (NSString*)alternateTextForScan:(NSString*)string {
    NSString *alt = [self.alternateURLs objectForKey:string];

    if (alt) {
        return [NSString stringWithString:alt];
    } else {
        return [NSString stringWithString:string];
    }
}

#pragma mark -
#pragma mark Singleton Implementation
+ (QRReaderResultTransform*)sharedTransform {
    if (_sharedResultTransform == nil) {
        _sharedResultTransform = [[super allocWithZone:NULL] init];
    }
    
    return _sharedResultTransform;
}

+ (id)allocWithZone:(NSZone *)zone {
    return [[self sharedTransform] retain];
}

- (id)copyWithZone:(NSZone*)zone {
    return self;
}

- (id)retain {
    return self;
}

- (NSUInteger)retainCount {
    return NSUIntegerMax;
}

- (void)release {
    return;
}

- (id)autorelease {
    return self;
}
@end
