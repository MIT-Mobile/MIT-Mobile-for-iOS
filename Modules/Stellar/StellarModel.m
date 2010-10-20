
#import "StellarModel.h"
#import "StellarCourse.h"
#import "StellarClass.h"
#import "StellarAnnouncement.h"
#import "StellarCache.h"
#import "ConnectionWrapper.h"
#import "CoreDataManager.h"

#define MONTH 30 * 24 * 60 * 60

NSString * const MyStellarChanged = @"MyStellarChanged";

/** This class is responsible for grabbing stellar data 
 the methods are written to accept callbacks, so everything is asynchronous
 
 there are three levels of data retrieval (depending on the type of query being executed)
 
 StellarCache  (in local memory, disappears after every application launch)
 
 CoreData (semi permanent on disk storage)
 
 MITMobileWebAPI (requires server connection to call the mit mobile web server)
**/

@implementation StellarModel

+ (BOOL) coursesCached {
	NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
	NSDate *coursesLastSaved = (NSDate *)[settings objectForKey:@"stellarCoursesLastSaved"];
	if(coursesLastSaved == nil) {
		return NO;
	} else {
		return (BOOL)(-[coursesLastSaved timeIntervalSinceNow] < MONTH);
	}
}

// TODO: Everyone of the load* calls leaks an instance each of MITMobileWebAPI and its *Request. It might take a slight redesign of this class to make them not leak.

+ (void) loadCoursesFromServerAndNotify: (id<CoursesLoadedDelegate>)delegate {
	if([StellarModel coursesCached]) {
		[delegate coursesLoaded];
		return;
	}
	
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI 
		jsonLoadedDelegate:[[[CoursesRequest alloc] 
			initWithCoursesDelegate:delegate] autorelease]];
	[apiRequest requestObjectFromModule:@"stellar" command:@"courses" parameters:nil];
}

+ (void) loadClassesForCourse: (StellarCourse *)stellarCourse delegate: (id<ClassesLoadedDelegate>) delegate {
	NSArray *classes = [StellarCache getClassListForCourse:stellarCourse];
	if(classes != nil) {
		[delegate classesLoaded:classes];
	} else {
		MITMobileWebAPI *apiRequest = [MITMobileWebAPI
			jsonLoadedDelegate:[[[ClassesRequest alloc] 
				initWithDelegate:delegate course:stellarCourse] autorelease]];
		[apiRequest 
			requestObjectFromModule:@"stellar" 
			command:@"subjectList" 
			parameters:[NSDictionary dictionaryWithObject: stellarCourse.number forKey:@"id"]];
	}
}

+ (void) executeStellarSearch: (NSString *)searchTerms delegate: (id<ClassesSearchDelegate>)delegate {
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI
		jsonLoadedDelegate:[[[ClassesSearchRequest alloc]
			initWithDelegate:delegate searchTerms:searchTerms] autorelease]];
	[apiRequest 
		requestObjectFromModule:@"stellar" 
		command:@"search" 
		parameters:[NSDictionary dictionaryWithObject:searchTerms forKey:@"query"]];
}
	
+ (NSArray *) allCourses {
	return [CoreDataManager fetchDataForAttribute:StellarCourseEntityName];
}

+ (NSArray *) myStellarClasses {
	NSMutableArray *classesWithNoContext = [[NSMutableArray new] autorelease];
	for(StellarClass *class in [CoreDataManager fetchDataForAttribute:StellarClassEntityName]) {
		[classesWithNoContext addObject:[CoreDataManager insertObjectGraph:class context:nil]];
	}
	[classesWithNoContext sortUsingFunction:classNameCompare context:NULL];
	return classesWithNoContext;
}

+ (void) loadAllClassInfo: (StellarClass *)class delegate: (id<ClassInfoLoadedDelegate>)delegate {
	// there three states class info can exist in
	// 1) just contains general information such as the name and location and instructors
	// 2) contains all the class information (including details such as the annoucements) but may not be up-to-date
	// 3) contains all the information and has been recently retrived from the mobile web server (therefore is up-to-date)
	
	StellarClass *generalClassInfo = [StellarCache getGeneralClassInfo:class];	
	if(generalClassInfo) {
		[delegate generalClassInfoLoaded:generalClassInfo];
	}
	
	// check if some version of all the class data is available in cache or CoreData
	StellarClass *allClassInfo = [StellarCache getAllClassInfo:class];
	if(allClassInfo) {
		[delegate initialAllClassInfoLoaded:allClassInfo];
	} else {
		allClassInfo = [self getOldClass:class];
		if(allClassInfo) {
			allClassInfo = [CoreDataManager insertObjectGraph:allClassInfo context:nil];
			[StellarCache addAllClassInfo:allClassInfo];
		}
		
	}
	[delegate initialAllClassInfoLoaded:allClassInfo];
	
	// finally we call the server to get the most definitive data
	MITMobileWebAPI *apiRequest = [MITMobileWebAPI
		jsonLoadedDelegate:[[[ClassInfoRequest alloc] 
			initWithClassInfoDelegate:delegate] autorelease]];
	
	[apiRequest 
		requestObjectFromModule:@"stellar" 
		command:@"subjectInfo" 
		parameters:[NSDictionary dictionaryWithObject: class.masterSubjectId forKey:@"id"]];
}

+ (StellarClass *) getOldClass: (StellarClass *)class {
	return [CoreDataManager getObjectForEntity:StellarClassEntityName attribute:@"masterSubjectId" value:class.masterSubjectId];
}

+ (void) saveClassToFavorites: (StellarClass *)class {
	StellarClass *oldClassInfo = [self getOldClass:class];
	if(oldClassInfo) {
		[CoreDataManager deleteObject:oldClassInfo];
        [CoreDataManager saveData];
	}
	
	class.isFavorited = [NSNumber numberWithInt:1];
	[CoreDataManager insertObjectGraph:class];
	[CoreDataManager saveData];
	
	[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
}

+ (void) removeClassFromFavorites: (StellarClass *)class notify: (BOOL)sendNotification{
	class.isFavorited = [NSNumber numberWithInt:0];
	NSManagedObject *managedObject = [CoreDataManager getObjectForEntity:StellarClassEntityName attribute:@"masterSubjectId" value:class.masterSubjectId];
	if(managedObject) {
		[CoreDataManager deleteObject:managedObject];
        [CoreDataManager saveData];
	}
	
	if(sendNotification) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
	}
}

+ (void) removeClassFromFavorites: (StellarClass *)class {
	[self removeClassFromFavorites:class notify:YES];
}

+ (void) removeOldFavorites: (id<ClearMyStellarDelegate>)delegate {
	NSArray *favorites = [self myStellarClasses];
	if([favorites count]) {
		// we call the server to get the current semester
		MITMobileWebAPI *apiRequest = [MITMobileWebAPI
			jsonLoadedDelegate:[[[TermRequest alloc] 
				initWithClearMyStellarDelegate:delegate stellarClasses:favorites] autorelease]];
		
		[apiRequest requestObjectFromModule:@"stellar" command:@"term" parameters:nil];
	}
}

+ (StellarClass *) emptyClassWithMasterId: (NSString *)masterSubjectId {
	StellarClass *stellarClass = (StellarClass *)[CoreDataManager insertNewObjectWithNoContextForEntity:StellarClassEntityName];
	stellarClass.masterSubjectId = masterSubjectId;
	return stellarClass;
}
	
+ (StellarClass *) StellarClassFromDictionary: (NSDictionary *)aDict {
	StellarClass *stellarClass = (StellarClass *)[CoreDataManager insertNewObjectWithNoContextForEntity:StellarClassEntityName];
	stellarClass.masterSubjectId = [aDict objectForKey:@"masterId"];
	stellarClass.name = [aDict objectForKey:@"name"];
	stellarClass.title = [aDict objectForKey:@"title"];
	stellarClass.blurb = [aDict objectForKey:@"description"];
	stellarClass.term = [aDict objectForKey:@"term"];
	stellarClass.url = [aDict objectForKey:@"stellarUrl"];
	stellarClass.lastAccessedDate = [NSDate date];
	
	// add the class times
	NSInteger orderId = 0;
	for(NSDictionary *time in (NSArray *)[aDict objectForKey:@"times"]) {
		[stellarClass addTimesObject:[StellarModel stellarTimeFromDictionary:time class:stellarClass orderId:orderId]];
		orderId++;
	}
	
	// add the class staff
	NSDictionary *staff = (NSDictionary *)[aDict objectForKey:@"staff"];
	NSArray *instructors = (NSArray *)[staff objectForKey:@"instructors"];
	NSArray *tas = (NSArray *)[staff objectForKey:@"tas"];	
	for(NSString *staff in instructors) {
		[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"instructor"]];
	}
	for(NSString *staff in tas) {
		[stellarClass addStaffObject:[StellarModel stellarStaffFromName:staff class:stellarClass type:@"ta"]];
	}

	
	// add the annoucements
	NSArray *annoucements;
	if(annoucements = [aDict objectForKey:@"announcements"]) {
		for(NSDictionary *annoucementDict in annoucements) {
			[stellarClass addAnnouncementObject:[StellarModel stellarAnnouncementFromDict:annoucementDict]];
		}
	}
	
	return stellarClass;
}

+ (StellarClassTime *) stellarTimeFromDictionary: (NSDictionary *)time class:(StellarClass *)class orderId: (NSInteger)orderId {
	StellarClassTime *stellarClassTime = (StellarClassTime *)[CoreDataManager insertNewObjectWithNoContextForEntity:StellarClassTimeEntityName];
	stellarClassTime.stellarClass = class;
	stellarClassTime.title = [time objectForKey:@"title"];
	stellarClassTime.location = [time objectForKey:@"location"];
	stellarClassTime.time = [time objectForKey:@"time"];
	stellarClassTime.order = [NSNumber numberWithInt:orderId];
	return stellarClassTime;
}

+ (StellarStaffMember *) stellarStaffFromName: (NSString *)name class:(StellarClass *)class type: (NSString *)type {
	StellarStaffMember *stellarStaffMember = (StellarStaffMember *)[CoreDataManager insertNewObjectWithNoContextForEntity:StellarStaffMemberEntityName];
	stellarStaffMember.stellarClass = class;
	stellarStaffMember.name = name;
	stellarStaffMember.type = type;
	return stellarStaffMember;
}

+ (StellarAnnouncement *) stellarAnnouncementFromDict: (NSDictionary *)dict {
	StellarAnnouncement *stellarAnnouncement = (StellarAnnouncement *)[CoreDataManager insertNewObjectWithNoContextForEntity:StellarAnnouncementEntityName];
	stellarAnnouncement.pubDate = [NSDate dateWithTimeIntervalSince1970:(NSTimeInterval)[(NSNumber *)[dict objectForKey:@"unixtime"] doubleValue]];
	stellarAnnouncement.title = (NSString *)[dict objectForKey:@"title"];
	stellarAnnouncement.text = (NSString *)[dict objectForKey:@"text"];
	return stellarAnnouncement;
}
	
@end

@implementation CoursesRequest
@synthesize coursesLoadedDelegate;

- (id) initWithCoursesDelegate: (id<CoursesLoadedDelegate>)delegate {
	if(self = [super init]) {
		self.coursesLoadedDelegate = delegate;
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	for(NSDictionary *aDict in (NSArray *)object) {
		StellarCourse *stellarCourse = [CoreDataManager getObjectForEntity:StellarCourseEntityName attribute:@"number" value:[aDict objectForKey:@"short"]];
		if(stellarCourse == nil) {
			stellarCourse = (StellarCourse *)[CoreDataManager insertNewObjectForEntityForName:StellarCourseEntityName];
			stellarCourse.number = [aDict objectForKey:@"short"];
		}
		stellarCourse.title = [aDict objectForKey:@"name"];
	}
	[CoreDataManager saveData];
	[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"stellarCoursesLastSaved"];
	[self.coursesLoadedDelegate coursesLoaded];
}
	
- (void) dealloc {
	[coursesLoadedDelegate release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[self.coursesLoadedDelegate handleCouldNotReachStellar];
}

@end

@implementation ClassesRequest
@synthesize classesLoadedDelegate, stellarCourse;

- (id) initWithDelegate: (id<ClassesLoadedDelegate>)delegate course: (StellarCourse *)course {
	if(self = [super init]) {
		self.classesLoadedDelegate = delegate;
		self.stellarCourse = course;
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSMutableArray *classes = [NSMutableArray array];
	for(NSDictionary *aDict in (NSArray *)object) {
		[classes addObject:[StellarModel StellarClassFromDictionary:aDict]];
	}
	[StellarCache addClassList:classes forCourse:self.stellarCourse];
	[self.classesLoadedDelegate classesLoaded:classes];
}	

- (void) dealloc {
	[classesLoadedDelegate release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[self.classesLoadedDelegate handleCouldNotReachStellar];
}

@end

@implementation ClassesSearchRequest

- (id) initWithDelegate: (id<ClassesSearchDelegate>)delegate searchTerms: (NSString *)theSearchTerms {
	if(self = [super init]) {
		classesSearchDelegate = [delegate retain];
		searchTerms = [theSearchTerms retain];
	}
	return self;
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSMutableArray *classes = [NSMutableArray array];
	for(NSDictionary *aDict in (NSArray *)object) {
		[classes addObject:[StellarModel StellarClassFromDictionary:aDict]];
	}
	[classesSearchDelegate searchComplete:classes searchTerms:searchTerms];
}	

- (void) dealloc {
	[classesSearchDelegate release];
	[searchTerms release];
	[super dealloc];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[classesSearchDelegate handleCouldNotReachStellarWithSearchTerms:searchTerms];
}

@end

@implementation ClassInfoRequest
@synthesize classInfoLoadedDelegate;

- (id) initWithClassInfoDelegate: (id<ClassInfoLoadedDelegate>)delegate {
	if(self = [super init]) {
		self.classInfoLoadedDelegate = delegate;
	}
	return self;
}

- (void) dealloc {
	[classInfoLoadedDelegate release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {	
	if([(NSDictionary *)object objectForKey:@"error"]) {
		[self.classInfoLoadedDelegate handleClassNotFound];
		return;
	}
	
	// check if this class exists in the CoreData store (ie the application had some reason to save it previously)
	// if it saved it previously we want update Class Info in the CoreData store
	StellarClass *classFromServer = [StellarModel StellarClassFromDictionary:(NSDictionary *)object];
	
	StellarClass *oldClassInfo = [StellarModel getOldClass:classFromServer];
	
	if(oldClassInfo) {
		// an old copy exists on disk, so remove and be sure that new copy is commited/saved to disk right now
		classFromServer.isFavorited = oldClassInfo.isFavorited;
		
		[CoreDataManager deleteObject:oldClassInfo];
		[CoreDataManager insertObjectGraph:classFromServer];
		[CoreDataManager saveData];
	} 
	
	[StellarCache addAllClassInfo:classFromServer];
	[self.classInfoLoadedDelegate finalAllClassInfoLoaded:classFromServer];
}

- (void)handleConnectionFailureForRequest:(MITMobileWebAPI *)request {
	[self.classInfoLoadedDelegate handleCouldNotReachStellar];
}

@end


@implementation TermRequest

- (id) initWithClearMyStellarDelegate: (id<ClearMyStellarDelegate>)delegate stellarClasses: (NSArray *)theMyStellarClasses {
	if(self = [super init]) {
		clearMyStellarDelegate = [delegate retain];
		myStellarClasses = [theMyStellarClasses retain];
		
	}
	return self;
}

- (void) dealloc {
	[myStellarClasses release];
	[clearMyStellarDelegate release];
	[super dealloc];
}

- (void)request:(MITMobileWebAPI *)request jsonLoaded: (id)object {
	NSString *term = [(NSDictionary *)object objectForKey:@"term"];
	NSMutableArray *oldClasses = [NSMutableArray array];
	for(StellarClass *class in myStellarClasses) {
		if(![term isEqualToString:class.term]) {
			[StellarModel removeClassFromFavorites:class notify:NO];
			[oldClasses addObject:class];
		}
	}
	
	if([oldClasses count]) {
		[[NSNotificationCenter defaultCenter] postNotificationName:MyStellarChanged object:nil];
		[clearMyStellarDelegate classesRemoved:oldClasses];
	}
}

@end


NSInteger classNameCompare(id class1, id class2, void *context) {
	// examples.. if class is "6.002 / 8.003", course=@"6", classPart=@"002" firstWord="6.002"

	NSString *name1 = ((StellarClass *)class1).name;
	NSString *firstWord1 = [[name1 componentsSeparatedByString:@" "] objectAtIndex:0];
	NSArray *numberParts1 = [firstWord1 componentsSeparatedByString:@"."];
	NSString *course1 = [numberParts1 objectAtIndex:0];
	NSString *classPart1=nil;
	if([numberParts1 count] > 1) {
		classPart1 = [numberParts1 objectAtIndex:1];
	}
	
	NSString *name2 = ((StellarClass *)class2).name;
	NSString *firstWord2 = [[name2 componentsSeparatedByString:@" "] objectAtIndex:0];
	NSArray *numberParts2 = [firstWord2 componentsSeparatedByString:@"."];
	NSString *course2 = [numberParts2 objectAtIndex:0];
	NSString *classPart2=nil;
	if([numberParts2 count] > 1) {
		classPart2 = [numberParts2 objectAtIndex:1];
	}
	
	// check the nil cases first
	// we first order by course number
	if(!classPart1 && !classPart2) {
		// nothing of the format X.YYY found in the classes name string (so just do a raw comparison)
		return [name1 compare:name2];
	}
	if(!classPart1) {
		return 1;
	}
	if(!classPart2) {
		return -1;
	}
	
	if([course1 compare:course2 options:NSNumericSearch] != 0) {
		return [course1 compare:course2 options:NSNumericSearch];
	}
	
	if([classPart1 compare:classPart2] != 0) {
		return [classPart1 compare:classPart2];
	}
	
	return [name1 compare:name2];
}