

#import "CompositionSingleton.h"

@implementation CompositionSingleton

#pragma mark Singleton Methods

+ (id)sharedSingleton {
    static CompositionSingleton *sharedVideoSingleton = nil;
    @synchronized(self) {
        if (sharedVideoSingleton == nil)
            sharedVideoSingleton = [[self alloc] init];
    }
    return sharedVideoSingleton;
}

- (id)init {
    if (self = [super init]) {
        _errorMessage = nil;
        _musicPath = nil;
        _aShotListURLs = [[NSMutableArray alloc]init];
        _bShotListURLs = [[NSMutableArray alloc]init];
        _thisManyBrollRecorded = 0;
    }
    return self;
}

- (void)resetSingleton {
    _errorMessage = nil;
    _musicPath = nil;
    _aShotListURLs = [[NSMutableArray alloc]init];
    _bShotListURLs = [[NSMutableArray alloc]init];
    _thisManyBrollRecorded = 0;
}

- (void)dealloc {
    // Should never be called, but just here for clarity really.
}

@end
