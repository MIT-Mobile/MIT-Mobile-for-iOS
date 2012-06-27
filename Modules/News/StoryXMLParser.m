#import "StoryXMLParser.h"
#import "NewsStory.h"
#import "CoreDataManager.h"
#import "MIT_MobileAppDelegate.h"
#import "MITMobileWebAPI.h"
#import "MITMobileServerConfiguration.h"

@interface StoryXMLParser ()
@property (nonatomic, assign) NSAutoreleasePool *downloadAndParsePool;

- (void)detachAndParseURL:(NSURL *)url;
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
{
    id <StoryXMLParserDelegate> delegate;
    
	NSThread *thread;
	
    ConnectionWrapper *connection;
    
	NSXMLParser *xmlParser;
	
    NSInteger expectedStoryCount;
    
    BOOL parsingTopStories;
    
	NSString *currentElement;
    NSMutableArray *currentStack;
    NSMutableDictionary *currentContents;
    NSMutableDictionary *currentImage;
	BOOL done;
    BOOL parseSuccessful;
    BOOL shouldAbort;
	BOOL isSearch;
	BOOL loadingMore;
	NSInteger totalAvailableResults;
    
    NSMutableArray *addedStories;
    
	NSAutoreleasePool *downloadAndParsePool;
}

@synthesize delegate;
@synthesize parsingTopStories;
@synthesize isSearch;
@synthesize loadingMore;
@synthesize totalAvailableResults;
@synthesize connection;
@synthesize xmlParser;
@synthesize currentElement;
@synthesize currentStack;
@synthesize currentContents;
@synthesize currentImage;
@synthesize addedStories;
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
NSString * const NewsTagThumbnail2xURL  = @"thumb152";
NSString * const NewsTagSmallURL        = @"smallURL";
NSString * const NewsTagFullURL         = @"fullURL";
NSString * const NewsTagImageCredits    = @"imageCredits";
NSString * const NewsTagImageCaption    = @"imageCaption";

NSString * const NewsTagImageWidth      = @"width";
NSString * const NewsTagImageHeight     = @"height";

- (NSString *)newsTagThumbURL {
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)]
        && [[UIScreen mainScreen] scale] == 2.0)
    {
        return NewsTagThumbnail2xURL;
    }
    return NewsTagThumbnailURL;
}

- (id) init
{
    self = [super init];
    if (self != nil) {
        delegate = nil;
		thread = nil;
        expectedStoryCount = 0;
        parsingTopStories = NO;
        connection = nil;
        currentElement = nil;
        currentStack = nil;
        currentContents = nil;
        currentImage = nil;
        addedStories = nil;
        downloadAndParsePool = nil;
        done = NO;
		isSearch = NO;
		loadingMore = NO;
		totalAvailableResults = 0;
        parseSuccessful = NO;
        shouldAbort = NO;
    }
    return self;
}

- (void)dealloc {
	if (![thread isFinished]) {
		ELog(@"***** %s called before parsing finished", __PRETTY_FUNCTION__);
	}
	[thread release];
	thread = nil;
    self.delegate = nil;
    self.connection = nil;
	self.xmlParser = nil;
    self.addedStories = nil;
    self.currentElement = nil;
    self.currentStack = nil;
    self.currentContents = nil;
    self.currentImage = nil;
	self.downloadAndParsePool = nil;
    [super dealloc];
}

- (void)loadStoriesForCategory:(NSInteger)category afterStoryId:(NSInteger)storyId count:(NSInteger)count {
	self.isSearch = NO;
    NSString *newsPath = nil;
    
    if (MITMobileWebGetCurrentServerType() == MITMobileWebDevelopment) {
        newsPath = @"newsoffice-dev";
    } else {
        newsPath = @"newsoffice";
    }
    
    NSURL *host = MITMobileWebGetCurrentServerURL();
    NSURL *baseURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/", [host absoluteString], newsPath]];
    NSMutableString *pathString = [NSMutableString stringWithCapacity:22];
    NSMutableArray *params = [NSMutableArray arrayWithCapacity:2];
    if (category != 0) {
        [params addObject:[NSString stringWithFormat:@"channel=%d", category]];
    } else {
        parsingTopStories = TRUE;
    }
	self.loadingMore = NO;
    if (storyId != 0) {
		self.loadingMore = YES;
        [params addObject:[NSString stringWithFormat:@"story_id=%d", storyId]];
    }
    if ([params count] > 0) {
        [pathString appendString:@"?"];
    }
    [pathString appendString:[params componentsJoinedByString:@"&"]];
    NSURL *fullURL = [NSURL URLWithString:pathString relativeToURL:baseURL];
    
    expectedStoryCount = 10; // if the server is ever made to support a range param, set this to count instead
    
	[self detachAndParseURL:fullURL];
}

- (void)loadStoriesforQuery:(NSString *)query afterIndex:(NSInteger)start count:(NSInteger)count {
	self.isSearch = YES;
	self.loadingMore = (start == 0) ? NO : YES;
	
	// before getting new results, clear old search results if this is a new search request
	if (self.isSearch && !self.loadingMore) {
		NSPredicate *predicate = [NSPredicate predicateWithFormat:@"searchResult == YES"];
		NSArray *results = [CoreDataManager objectsForEntity:NewsStoryEntityName matchingPredicate:predicate];
		for (NewsStory *aStory in results) {
			aStory.searchResult = NO;
		}
		[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
	}
	
    NSURL *fullURL = [NSURL URLWithString:[NSString stringWithFormat:@"http://web.mit.edu/newsoffice/index.php?option=com_search&view=isearch&searchword=%@&ordering=newest&limit=%d&start=%d", [query stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding], count, start]];
    expectedStoryCount = count;
    
	[self detachAndParseURL:fullURL];
}

- (void)detachAndParseURL:(NSURL *)url {
	if (thread) {
		ELog(@"***** %s called twice on the same instance", __PRETTY_FUNCTION__);
	}
	thread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadAndParse:) object:url];
	[thread start];
}

- (void)abort {
    shouldAbort = YES;
	[thread cancel];
}

// should be spawned on a separate thread
- (void)downloadAndParse:(NSURL *)url {
	self.downloadAndParsePool = [[NSAutoreleasePool alloc] init];
	done = NO;
    parseSuccessful = NO;
    
    self.connection = [[[ConnectionWrapper alloc] initWithDelegate:self] autorelease];
    self.addedStories = [NSMutableArray array];
    
    BOOL requestStarted = [connection requestDataFromURL:url];
	if (requestStarted) {
        [self performSelectorOnMainThread:@selector(didStartDownloading) withObject:nil waitUntilDone:NO];
		do {
			if ([[NSThread currentThread] isCancelled]) {
				if (self.connection) {
					[self.connection cancel];
					self.connection = nil;
				}
				if (self.xmlParser) {
					[self.xmlParser abortParsing];
					self.xmlParser = nil;
				}
				break;
			}
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
		} while (!done);
	} else {
        [self performSelectorOnMainThread:@selector(downloadError:) withObject:nil waitUntilDone:NO];
    }
    [downloadAndParsePool release];
	self.downloadAndParsePool = nil;
}

- (void)connection:(ConnectionWrapper *)wrapper handleData:(NSData *)data {
	if (shouldAbort) {
		return;
	}
    self.connection = nil;
    self.xmlParser = [[[NSXMLParser alloc] initWithData:data] autorelease];
	self.xmlParser.delegate = self;
    self.currentContents = [NSMutableDictionary dictionary];
    self.currentStack = [NSMutableArray array];
	[self.xmlParser parse];
	self.xmlParser = nil;
    self.currentStack = nil;
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
                      [self newsTagThumbURL],
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
            ELog(@"%s warning: found a nested <item> in the News XML.", __PRETTY_FUNCTION__);
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
    } else if ([elementName isEqualToString:NewsTagFullURL] && currentImage) {
        [currentImage setObject:attributeDict forKey:@"fullSize"];
    } else if ([elementName isEqualToString:@"items"]) {
		NSNumber *totalResults = [attributeDict objectForKey:@"totalResults"];
		if (totalResults) {
			self.totalAvailableResults = [totalResults integerValue];
		}
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
			story.searchResult = [NSNumber numberWithBool:isSearch]; // gets reset to NO before every search

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

            [self performSelectorOnMainThread:@selector(reportProgress:) withObject:[NSNumber numberWithFloat:[addedStories count] / (0.01 * expectedStoryCount)] waitUntilDone:NO];

            [addedStories addObject:story];
            
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
        NSString *thumbURL = [imageDict objectForKey:[self newsTagThumbURL]];
        NSString *smallURL = [imageDict objectForKey:NewsTagSmallURL];
        NSString *fullURL = [imageDict objectForKey:NewsTagFullURL];
        NSDictionary *smallSize = [imageDict objectForKey:@"smallSize"];
        NSDictionary *fullSize = [imageDict objectForKey:@"fullSize"];
		
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
        if (smallSize) {
            newsImage.smallImage.width = [NSNumber numberWithInteger:[[smallSize objectForKey:NewsTagImageWidth] integerValue]];
            newsImage.smallImage.height = [NSNumber numberWithInteger:[[smallSize objectForKey:NewsTagImageHeight] integerValue]];
        }
        newsImage.fullImage = [self imageRepForURLString:fullURL];
        if (fullSize) {
            newsImage.fullImage.width = [NSNumber numberWithInteger:[[fullSize objectForKey:NewsTagImageWidth] integerValue]];
            newsImage.fullImage.height = [NSNumber numberWithInteger:[[fullSize objectForKey:NewsTagImageHeight] integerValue]];
        }
    }
    return newsImage;
}

- (NewsImageRep *)imageRepForURLString:(NSString *)urlString {
    NewsImageRep *imageRep = nil;
    if (urlString && [urlString length] > 0) {
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
	[CoreDataManager saveDataWithTemporaryMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
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
