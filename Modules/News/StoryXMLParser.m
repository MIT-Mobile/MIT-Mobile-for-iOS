#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileWebAPI.h"

@interface StoryXMLParser (Private)

- (void)downloadAndParse:(NSURL *)url;
- (NSArray *)itemWhitelist;
- (NSArray *)imageWhitelist;
- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict;
- (NewsImageRep *)imageRepForURLString:(NSString *)urlString;

- (void)didStartDownloading;
- (void)didStartParsing;
- (void)reportProgress:(NSNumber *)percentComplete;
- (void)parseEnded;
- (void)downloadError:(NSError *)error;
- (void)parseError:(NSError *)error;

@end


@implementation StoryXMLParser

@synthesize delegate;
@synthesize parsingTopStories;
@synthesize connection;
@synthesize currentElement;
@synthesize currentStack;
@synthesize currentContents;
@synthesize currentImage;
@synthesize newStories;
@synthesize downloadAndParsePool;

NSString * const NewsTagItem            = @"item";
NSString * const NewsTagTitle           = @"title";
NSString * const NewsTagAuthor          = @"author";
NSString * const NewsTagCategory        = @"category";
NSString * const NewsTagLink            = @"link";
NSString * const NewsTagStoryId         = @"story_id";
NSString * const NewsTagFeatured        = @"featured";
NSString * const NewsTagSummary         = @"description";
NSString * const NewsTagPostDate        = @"postDate";
NSString * const NewsTagBody            = @"body";

NSString * const NewsTagImage           = @"image";
NSString * const NewsTagOtherImages     = @"otherImages";
NSString * const NewsTagThumbnailURL    = @"thumbURL";
NSString * const NewsTagSmallURL        = @"smallURL";
NSString * const NewsTagFullURL         = @"fullURL";
NSString * const NewsTagImageCredits    = @"imageCredits";
NSString * const NewsTagImageCaption    = @"imageCaption";

NSString * const NewsTagImageWidth      = @"width";
NSString * const NewsTagImageHeight     = @"height";

- (id) init
{
    self = [super init];
    if (self != nil) {
        delegate = nil;
        expectedStoryCount = 0;
        parsingTopStories = NO;
        connection = nil;
        currentElement = nil;
        currentStack = nil;
        currentContents = nil;
        currentImage = nil;
        newStories = nil;
        downloadAndParsePool = nil;
        done = NO;
        parseSuccessful = NO;
        shouldAbort = NO;
    }
    return self;
}

- (void)dealloc {
    self.delegate = nil;
    self.connection = nil;
    self.newStories = nil;
    self.currentElement = nil;
    self.currentStack = nil;
    self.currentContents = nil;
    self.currentImage = nil;
    
    self.downloadAndParsePool = nil;
    [super dealloc];
}

- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count {
#ifdef USE_MOBILE_DEV
    NSString *newsPath = @"newsoffice-dev";
#else
    NSString *newsPath = @"newsoffice";
#endif
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@/", MITMobileWebAPIURLString, newsPath]];
    NSMutableString *pathString = [NSMutableString stringWithCapacity:22];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:2];
    if (category != 0) {
        [params addObject:[NSString stringWithFormat:@"channel=%d", category]];
    } else {
        parsingTopStories = TRUE;
    }

    if (storyId != 0) {
        [params addObject:[NSString stringWithFormat:@"story_id=%d", storyId]];
    }
    if ([params count] > 0) {
        [pathString appendString:@"?"];
    }
    [pathString appendString:[params componentsJoinedByString:@"&"]];
    NSURL *fullURL = [NSURL URLWithString:pathString relativeToURL:baseURL];
    
    expectedStoryCount = 10; // if the server is ever made to support a range param, set this to count instead
    
	[NSThread detachNewThreadSelector:@selector(downloadAndParse:) toTarget:self withObject:fullURL];
}

- (void)abort {
    shouldAbort = YES;
}

// should be spawned on a separate thread
- (void)downloadAndParse:(NSURL *)url {
	self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
	done = NO;
    parseSuccessful = NO;
    
    self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    self.newStories = [NSMutableArray array];
    
    BOOL requestStarted = [connection requestDataFromURL:url];
	if (requestStarted) {
        [self performSelectorOnMainThread:@selector(didStartDownloading) withObject:nil waitUntilDone:NO];
        // set the merge policy to deal with conflicts: the most recently parsed articles always win
        [[CoreDataManager managedObjectContext] setMergePolicy:NSOverwriteMergePolicy];
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!done);
	} else {
        [self performSelectorOnMainThread:@selector(downloadError:) withObject:nil waitUntilDone:NO];
    }
    [downloadAndParsePool release];
	self.downloadAndParsePool = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
	parser.delegate = self;
    self.currentContents = [NSMutableDictionary dictionary];
    self.currentStack = [NSMutableArray array];
	[parser parse];
	[parser release];
    self.currentStack = nil;
    parser = nil;
    self.connection = nil;
	done = YES;
}

- (void)connection:(ConnectionWrapper *)wrapper handleConnectionFailureWithError:(NSError *)error {
	[self performSelectorOnMainThread:@selector(downloadError:) withObject:error waitUntilDone:NO];
	done = YES;
}

#pragma mark NSXMLParser delegation

- (NSArray *)itemWhitelist {
    static NSArray *itemWhitelist;
    
    if (!itemWhitelist) {
        itemWhitelist = [[NSArray arrayWithObjects:
                      NewsTagTitle,
                      NewsTagAuthor,
                      NewsTagCategory,
                      NewsTagLink,
                      NewsTagStoryId,
                      NewsTagFeatured,
                      NewsTagSummary,
                      NewsTagPostDate,
                      NewsTagBody, nil] retain];
    }
    return itemWhitelist;
}

- (NSArray *)imageWhitelist {
    static NSArray *imageWhitelist;
    
    if (!imageWhitelist) {
        imageWhitelist = [[NSArray arrayWithObjects:
                      NewsTagThumbnailURL,
                      NewsTagSmallURL,
                      NewsTagFullURL,
                      NewsTagImageCredits,
                      NewsTagImageCaption, nil] retain];
    }
    return imageWhitelist;
}


- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *) qualifiedName attributes:(NSDictionary *)attributeDict {
    
    self.currentElement = elementName;
	if ([elementName isEqualToString:NewsTagItem]) {
        if ([[currentContents allValues] count] > 0) {
            NSLog(@"%s warning: found a nested <item> in the News XML.", __PRETTY_FUNCTION__);
            [currentContents removeAllObjects];
        }
        NSArray *whitelist = [self itemWhitelist];
        for (NSString *key in whitelist) {
            [currentContents setObject:[NSMutableString string] forKey:key];
        }
	} else if ([elementName isEqualToString:NewsTagOtherImages]) {
        [currentContents setObject:[NSMutableArray array] forKey:NewsTagOtherImages];
    } else if ([elementName isEqualToString:NewsTagImage]) {
        // prep new image element
        self.currentImage = [NSMutableDictionary dictionary];
        NSArray *whitelist = [self imageWhitelist];
        for (NSString *key in whitelist) {
            [currentImage setObject:[NSMutableString string] forKey:key];
        }
        if ([[currentStack lastObject] isEqualToString:NewsTagItem]) {
            // if last tag on stack is <item>, then this is an inline image
            [currentContents setObject:currentImage forKey:NewsTagImage];
        } else {
            // otherwise, this belongs in <otherImages>
            NSMutableArray *otherImages = [currentContents objectForKey:NewsTagOtherImages];
            [otherImages addObject:currentImage];
        }
    } else if ([elementName isEqualToString:NewsTagSmallURL] && currentImage) {
        [currentImage setObject:attributeDict forKey:@"smallSize"];
    }
    [currentStack addObject:elementName];
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    
    if (shouldAbort) {
        [parser abortParsing];
        return;
    }
    
    string = [string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    NSMutableDictionary *currentDict = nil;
    NSArray *whitelist = nil;
    
    if ([currentStack indexOfObject:NewsTagImage] != NSNotFound) {
        currentDict = currentImage;
        whitelist = [self imageWhitelist];
    } else if ([currentStack indexOfObject:NewsTagItem] != NSNotFound) {
        currentDict = currentContents;
        whitelist = [self itemWhitelist];
    } else {
        return;
    }
    
    if ([string length] > 0 && [whitelist containsObject:currentElement]) {
        NSMutableString *value = [currentDict objectForKey:currentElement];
        [value appendString:string];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    
    NSAutoreleasePool *tinyPool = [[NSAutoreleasePool alloc] init];
    
    [currentStack removeLastObject];

	if ([elementName isEqualToString:NewsTagItem]) {
            // use existing story if it's already in the db
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"story_id == %d", [[currentContents objectForKey:NewsTagStoryId] integerValue]];
            NewsStory *story = [[CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate] lastObject];
            // otherwise create new
            if (!story) {
                story = (NewsStory *)[CoreDataManager insertNewObjectForEntityForName:NewsStoryEntityName];
            }

            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            formatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"] autorelease];
            [formatter setDateFormat:@"EEE, d MMM y HH:mm:ss zzz"];
            [formatter setTimeZone:[NSTimeZone localTimeZone]];
            NSDate *postDate = [formatter dateFromString:[currentContents objectForKey:NewsTagPostDate]];
            [formatter release];
            
            story.story_id = [NSNumber numberWithInteger:[[currentContents objectForKey:NewsTagStoryId] integerValue]];
            story.postDate = postDate;
            story.title = [currentContents objectForKey:NewsTagTitle];
            story.link = [currentContents objectForKey:NewsTagLink];
            story.author = [currentContents objectForKey:NewsTagAuthor];
            story.summary = [currentContents objectForKey:NewsTagSummary];
            story.body = [currentContents objectForKey:NewsTagBody];
            [story addCategory:[[currentContents objectForKey:NewsTagCategory] integerValue]];
            if (parsingTopStories) {
                // because NewsStory objects are shared between categories, only set this to YES, never revert it to NO
                story.topStory = [NSNumber numberWithBool:parsingTopStories];
            }

            story.featured = [NSNumber numberWithBool:[[currentContents objectForKey:NewsTagFeatured] boolValue]];
            
            story.inlineImage = [self imageWithDictionary:[currentContents objectForKey:NewsTagImage]];
            
            NSMutableArray *otherImagesDict = [currentContents objectForKey:NewsTagOtherImages];
            NSInteger i = 0;
            for (NSDictionary *otherImage in otherImagesDict) {
                NewsImage *anImage = [self imageWithDictionary:otherImage];
                if (anImage) {
                    anImage.ordinality = [NSNumber numberWithInteger:i];
                    i++;
                    [story addGalleryImage:anImage];
                }
            }

            [self performSelectorOnMainThread:@selector(reportProgress:) withObject:[NSNumber numberWithFloat:[newStories count] / (0.01 * expectedStoryCount)] waitUntilDone:NO];

            [newStories addObject:story];
            
            // prepare for next item
            [currentContents removeAllObjects];
	}
    [tinyPool release];
    
}

- (void)reportProgress:(NSNumber *)percentComplete {
    if ([self.delegate respondsToSelector:@selector(parser:didMakeProgress:)]) {
        [self.delegate parser:self didMakeProgress:[percentComplete floatValue]];
    }
}

- (NewsImage *)imageWithDictionary:(NSDictionary *)imageDict {
    NewsImage *newsImage = nil;
    if (imageDict) {
        NSString *credits = [imageDict objectForKey:NewsTagImageCredits];
        NSString *caption = [imageDict objectForKey:NewsTagImageCaption];
        NSString *thumbURL = [imageDict objectForKey:NewsTagThumbnailURL];
        NSString *smallURL = [imageDict objectForKey:NewsTagSmallURL];
        NSString *fullURL = [imageDict objectForKey:NewsTagFullURL];
        NSDictionary *smallSize = [imageDict objectForKey:@"smallSize"];
        
        // every <image> in the feed has at least a <fullURL>, so index on that
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"fullImage.url == %@", fullURL];
        newsImage = [[CoreDataManager objectsForEntity:NewsImageEntityName matchingPredicate:predicate] lastObject];
        if (!newsImage) {
            newsImage = [CoreDataManager insertNewObjectForEntityForName:NewsImageEntityName];
        }
        
        newsImage.credits = credits;
        newsImage.caption = caption;
        newsImage.thumbImage = [self imageRepForURLString:thumbURL];
        newsImage.smallImage = [self imageRepForURLString:smallURL];
        newsImage.fullImage = [self imageRepForURLString:fullURL];
        if (smallSize) {
            newsImage.smallImage.width = [NSNumber numberWithInteger:[[smallSize objectForKey:NewsTagImageWidth] integerValue]];
            newsImage.smallImage.height = [NSNumber numberWithInteger:[[smallSize objectForKey:NewsTagImageHeight] integerValue]];
        }
    }
    return newsImage;
}

- (NewsImageRep *)imageRepForURLString:(NSString *)urlString {
    NewsImageRep *imageRep = nil;
    if (urlString) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"url == %@", urlString];
        imageRep = [[CoreDataManager objectsForEntity:NewsImageRepEntityName matchingPredicate:predicate] lastObject];
        if (!imageRep) {
            imageRep = [CoreDataManager insertNewObjectForEntityForName:NewsImageRepEntityName];
            imageRep.url = urlString;
        }
    }
    return imageRep;
}

#pragma mark -
#pragma mark StoryXMLParser delegation

- (void)didStartDownloading {
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidStartDownloading:)]) {
		[self.delegate parserDidStartDownloading:self];	
	}
}

- (void)didStartParsing {
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidStartParsing:)]) {
		[self.delegate parserDidStartParsing:self];	
	}
}

- (void)parseEnded {
	if (parseSuccessful && self.delegate != nil && [self.delegate respondsToSelector:@selector(parserDidFinishParsing:)]) {
		[self.delegate parserDidFinishParsing:self];
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
    [self performSelectorOnMainThread:@selector(parseError:) withObject:error waitUntilDone:NO];
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    [self performSelectorOnMainThread:@selector(didStartParsing) withObject:nil waitUntilDone:NO];
}
         
- (void)parserDidEndDocument:(NSXMLParser *)parser {
    if (shouldAbort) {
        [parser abortParsing];
        return;
    }
    
    parseSuccessful = YES;
    [CoreDataManager saveData];
    if (parseSuccessful) {
        [self performSelectorOnMainThread:@selector(parseEnded) withObject:nil waitUntilDone:NO];
    }
}

- (void)downloadError:(NSError *)error {
    parseSuccessful = NO;
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithDownloadError:)]) {
		[self.delegate parser:self didFailWithDownloadError:error];	
	}
}

- (void)parseError:(NSError *)error {
    parseSuccessful = NO;
	if (self.delegate != nil && [self.delegate respondsToSelector:@selector(parser:didFailWithParseError:)]) {
		[self.delegate parser:self didFailWithParseError:error];	
	}
}

@end
