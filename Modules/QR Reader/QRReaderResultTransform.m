#import "QRReaderResultTransform.h"
#import "MITMobileServerConfiguration.h"

static QRReaderResultTransform *_sharedResultTransform = nil;

@interface QRReaderResultTransform ()
@property (nonatomic,retain) NSMutableDictionary *scanTitles;
@property (nonatomic,retain) NSMutableDictionary *alternateURLs;

- (void)updateTitles;
- (void)updateAlts;
@end

@implementation QRReaderResultTransform
@synthesize scanTitles = _scanTitles;
@synthesize alternateURLs = _alternateURLs;

- (id)init {
    self = [super init];
    
    if (self) {
        self.scanTitles = [NSMutableDictionary dictionary];
        self.alternateURLs = [NSMutableDictionary dictionary];
        [self updateTitles];
        [self updateAlts];
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

- (void)updateTitles {
    [self.scanTitles setObject:@"MIT150 Open House"
                        forKey:@"http://m.mit.edu/open-house/"];
    [self.scanTitles setObject:@"MIT150 Open House: Engineering, Technology and Invention"
                        forKey:@"http://m.mit.edu/open-house/eng"];
    [self.scanTitles setObject:@"MIT150 Open House: Energy, Environment and Sustainability"
                        forKey:@"http://m.mit.edu/open-house/energy"];
    [self.scanTitles setObject:@"MIT150 Open House: Entrepreneurship and Management "
                        forKey:@"http://m.mit.edu/open-house/entrepreneurship"];
    [self.scanTitles setObject:@"MIT150 Open House: Life Sciences and Biotechnology"
                        forKey:@"http://m.mit.edu/open-house/biotech"];
    [self.scanTitles setObject:@"MIT150 Open House: The Sciences"
                        forKey:@"http://m.mit.edu/open-house/sciences"];
    [self.scanTitles setObject:@"MIT150 Open House: Air and Space Flight"
                        forKey:@"http://m.mit.edu/open-house/air"];
    [self.scanTitles setObject:@"MIT150 Open House: Architecture, Planning and Design"
                        forKey:@"http://m.mit.edu/open-house/architecture"];
    [self.scanTitles setObject:@"MIT150 Open House: Arts, Humanities and Social Sciences"
                        forKey:@"http://m.mit.edu/open-house/humanities"];
    [self.scanTitles setObject:@"MIT150 Open House: MIT Learning, Life and Culture"
                        forKey:@"http://m.mit.edu/open-house/life"];
}

- (void)updateAlts {
    NSString *mitMobileBase = @"mitmobile://calendar/category?listID=OpenHouse&openHouseIdentifier=%@";

    [self.alternateURLs setObject:[NSString stringWithFormat:@"mitmobile://calendar/category?listID=OpenHouse%@", @"open-house"]
                           forKey:@"http://m.mit.edu/open-house"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"eng"]
                           forKey:@"http://m.mit.edu/open-house/eng"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"energy"]
                           forKey:@"http://m.mit.edu/open-house/energy"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"entrepreneurship"]
                           forKey:@"http://m.mit.edu/open-house/entrepreneurship"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"biotech"]
                           forKey:@"http://m.mit.edu/open-house/biotech"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"sciences"]
                           forKey:@"http://m.mit.edu/open-house/sciences"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"air"]
                           forKey:@"http://m.mit.edu/open-house/air"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"architecture"]
                           forKey:@"http://m.mit.edu/open-house/architecture"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"humanities"]
                           forKey:@"http://m.mit.edu/open-house/humanities"];
    [self.alternateURLs setObject:[NSString stringWithFormat:mitMobileBase,@"life"]
                           forKey:@"http://m.mit.edu/open-house/life"];
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

- (oneway void)release {
    return;
}

- (id)autorelease {
    return self;
}
@end
