

#import "AVSESpliceCommand.h"
#import "CompositionSingleton.h"
#define degreesToRadians( degrees ) ( ( degrees ) / 180.0 * M_PI )

@implementation AVSESpliceCommand

@synthesize aRollArray;
@synthesize bRollArray;
//state variables
@synthesize bShotCount;
@synthesize aShotCount;
@synthesize timerWhole;
@synthesize secondsRemainingInA;
@synthesize isThereAnyALeft;
@synthesize isThereAnyBLeft;

//constants
CMTime oneSecond, oneAndHalfSeconds, twoSeconds, threeSeconds, fourSeconds, fiveSeconds, sixSeconds, sevenSeconds, eightSeconds, nineSeconds, tenSeconds;
CMTimeRange firstSecond;

//tracks
AVMutableCompositionTrack *compositionVideoTrack, *videoTrackA, *videoTrackB;
AVAssetTrack *aRollAudioTrack, *aRollVideoTrack, *bRollAudioTrack, *bRollVideoTrack;
AVAsset *aRollAsset, *bRollAsset;
AVMutableCompositionTrack *musicTrack, *compositionAudioTrack;

//editing parameters
int randomCut;
int bCutCounter;
bool firstTime = YES;
int shotsPerSegment = 3;
CMTime secondsOfA, secondsOfB, currentArollTimer, compensationHeadStart, bRollTimer, aRollTimer;
NSMutableArray *layerInstructionsArray, *compositionInstructionsArray, *cutList;
AVMutableVideoCompositionInstruction *compositionInstruction;
AVMutableVideoCompositionLayerInstruction *compositionLayerInstruction;

CompositionSingleton *sharedSingleton;

- (void)perform{
    sharedSingleton = [CompositionSingleton sharedSingleton];
    aRollArray = [[NSMutableArray alloc]init];
    bRollArray = [[NSMutableArray alloc]init];
    //try to access videos
    [self defineConstants];
    [self retrieveAssetsFromTempURL];
}

- (void)continuePerformWithAroll:(NSMutableArray*)aRoll andBroll:(NSMutableArray*)bRoll{
    
    bShotCount = 0;
    aShotCount = 0;
    
    isThereAnyBLeft = [bRoll count]!=0;
    isThereAnyALeft = [aRoll count]!=0;
    
    if (isThereAnyALeft) {
        AVAsset *aRollAsset = aRollArray[aShotCount];
        secondsRemainingInA = [aRollAsset duration];
    }
    
    timerWhole = kCMTimeZero;
    aRollTimer = kCMTimeZero;
    bRollTimer = kCMTimeZero;
    
    layerInstructionsArray = [[NSMutableArray alloc] init];
    compositionInstructionsArray = [[NSMutableArray alloc]init];
    cutList = [[NSMutableArray alloc]init];
    
    if (!self.mutableComposition) {
        self.mutableComposition = [AVMutableComposition composition];
        
        if (!isThereAnyALeft){
            [aRoll addObject:[AVAsset
                              assetWithURL:bRoll[0]]];
        }
        videoTrackA = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                           preferredTrackID:kCMPersistentTrackID_Invalid];
        [self altAddA];
        
        if (isThereAnyBLeft){
            videoTrackB = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                               preferredTrackID:kCMPersistentTrackID_Invalid];
            [self altAddB];
        }
        
        [self altInstructions];
        [self addAudio];
    }
    
}

-(void)altAddA{
    if ([aRollArray count]!=0) {
        for (AVAsset *aRollAsset in aRollArray) {
            [videoTrackA insertTimeRange:CMTimeRangeMake(kCMTimeZero, aRollAsset.duration)
                                 ofTrack:[aRollAsset tracksWithMediaType:AVMediaTypeVideo][0]
                                  atTime:aRollTimer error:nil];
            aRollTimer = CMTimeAdd(aRollTimer, aRollAsset.duration);
            [cutList addObject:[NSNumber numberWithDouble: CMTimeGetSeconds(aRollTimer)]];
        }
    }
    
}
//cover it up, do not add secondsOfA to timerWhole
//else wait a big longer, add 2*secondsOfA to timerWhole

-(void)altAddB{
    firstTime=YES;
    int bRollCount = 0;
    BOOL aRollIsLonger =CMTimeGetSeconds(bRollTimer)<=CMTimeGetSeconds(aRollTimer);
    BOOL bRollLeft = bRollCount < [bRollArray count]*2;
    BOOL blackVideoIsntGonnaShow;
    BOOL chance;
    
    while (aRollIsLonger&&bRollLeft) {
        bRollAsset = bRollArray[bRollCount%[bRollArray count]];
        [videoTrackB insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondsOfB)
                             ofTrack:[bRollAsset tracksWithMediaType:AVMediaTypeVideo][0]
                              atTime:bRollTimer error:nil];
        bRollTimer = CMTimeAdd(bRollTimer, secondsOfB);
        bRollCount++;
        aRollIsLonger =CMTimeGetSeconds(bRollTimer)<=CMTimeGetSeconds(aRollTimer);
        bRollLeft = bRollCount < [bRollArray count]*2;
        blackVideoIsntGonnaShow = CMTimeGetSeconds(bRollTimer)<=CMTimeGetSeconds(CMTimeSubtract(aRollTimer, secondsOfA));
        chance = arc4random()%1==0;
        if (blackVideoIsntGonnaShow && chance && ![self aCutIsApproaching:CMTimeGetSeconds(bRollTimer)]) {
            if (blackVideoIsntGonnaShow) {
                bRollTimer = CMTimeAdd(bRollTimer, secondsOfA);
            }else{
                bRollTimer = CMTimeAdd(bRollTimer, CMTimeSubtract(aRollTimer, secondsOfA));
            }
        }
    }
    
    bRollLeft = bRollCount < [bRollArray count];
    while (bRollLeft) {
        bRollAsset = bRollArray[bRollCount%[bRollArray count]];
        [videoTrackB insertTimeRange:CMTimeRangeMake(kCMTimeZero, secondsOfB)
                             ofTrack:[bRollAsset tracksWithMediaType:AVMediaTypeVideo][0]
                              atTime:bRollTimer error:nil];
        bRollTimer = CMTimeAdd(bRollTimer, secondsOfB);
        bRollCount++;
        bRollLeft = bRollCount < [bRollArray count];
    }
}

-(BOOL)aCutIsApproaching:(double)bCut {
    for (NSNumber *aCut in cutList) {
        if ([aCut doubleValue] > bCut) {
            return CMTimeGetSeconds(secondsOfA) > [aCut doubleValue] - bCut;
        }
    }
    return NO;
}

-(void)altInstructions{
    
    //timerWhole
    if (CMTimeGetSeconds(bRollTimer)>CMTimeGetSeconds(aRollTimer)) {
        timerWhole = bRollTimer;
    }else{
        timerWhole = aRollTimer;
    }
    
    AVMutableVideoCompositionInstruction * instruction_1 = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    instruction_1.timeRange = CMTimeRangeMake(kCMTimeZero, timerWhole);
    
    AVMutableVideoCompositionLayerInstruction *bRollInstruction =
    [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrackB];
    [bRollInstruction setOpacity:0 atTime:bRollTimer];
    
    AVMutableVideoCompositionLayerInstruction *aRollInstruction =
    [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrackA];
    
    instruction_1.layerInstructions =  @[bRollInstruction, aRollInstruction];
    
    self.mutableVideoComposition = [AVMutableVideoComposition videoComposition];
    self.mutableVideoComposition.instructions = [NSArray arrayWithObject:instruction_1];
    self.mutableVideoComposition.frameDuration = CMTimeMake(1, 30);
    self.mutableVideoComposition.renderSize = CGSizeMake(480, 640);
}


-(void)retrieveAssetsFromTempURL{
    NSMutableArray *URLsArray = sharedSingleton.bShotListURLs;
    
    for (NSURL *url in URLsArray) {
        AVAsset *asset = [[AVURLAsset alloc]initWithURL:url options:nil];
        [bRollArray addObject:asset];
    }
    
    URLsArray = sharedSingleton.aShotListURLs;
    if ([URLsArray count]!=0) {
        for (NSURL *url in URLsArray) {
            AVAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
            [aRollArray addObject:asset];
        }
    }else if([sharedSingleton.bShotListURLs count]!=0){
        AVAsset *asset = [[AVURLAsset alloc]initWithURL:sharedSingleton.bShotListURLs[0] options:nil];
        [aRollArray addObject:asset];
    }
    
    
    [self continuePerformWithAroll:aRollArray andBroll:bRollArray];
    
}

-(void)addAudio{
    [self clearAudioTrack];
    [self addArollAudio];
    [self addMusic];
    [[NSNotificationCenter defaultCenter] postNotificationName:AVSEEditCommandCompletionNotification object:self];
}

-(void)addMusic{
    NSError *error = nil;
    NSURL *audioURL = nil;
    if (sharedSingleton.musicPath!=nil) {
        audioURL = sharedSingleton.musicPath;
    }else{
        NSString *audioPath = [[NSBundle mainBundle] pathForResource:@"Music" ofType:@"m4a"];
        audioURL = [NSURL fileURLWithPath:audioPath];
    }
    
    AVAsset *audioAsset = [[AVURLAsset alloc] initWithURL:audioURL options:nil];
    musicTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                      preferredTrackID:kCMPersistentTrackID_Invalid];
    
    for (AVAssetTrack *track in [audioAsset tracksWithMediaType:AVMediaTypeAudio]){
        [musicTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, timerWhole)
                            ofTrack:track
                             atTime:kCMTimeZero error:&error];
        
    }
    
    AVMutableAudioMixInputParameters *mixParameters = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:musicTrack];
    [mixParameters setVolumeRampFromStartVolume:.3
                                    toEndVolume:.3
                                      timeRange:CMTimeRangeMake(kCMTimeZero, timerWhole)];
    
    self.mutableAudioMix = [AVMutableAudioMix audioMix];
    self.mutableAudioMix.inputParameters = @[mixParameters];
    
    
    
    
}

-(void)clearAudioTrack{
    [self.mutableComposition removeTrack:musicTrack];
    [self.mutableComposition removeTrack:compositionAudioTrack];
}

-(void)addArollAudio{
    NSError *error = nil;
    compositionAudioTrack = [self.mutableComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                 preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime currentInsertionTime = kCMTimeZero;
    if (aRollArray!=nil) {
        for (AVAsset *asset in aRollArray) {
            if (asset!=nil) {
                [compositionAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, [asset duration])
                                               ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio][0]
                                                atTime:currentInsertionTime error:&error];
                currentInsertionTime = CMTimeAdd(currentInsertionTime, [asset duration]);
            }
            
        }
    }
    
}

-(void)defineConstants{
    oneSecond = CMTimeMakeWithSeconds(1, 600);
    oneAndHalfSeconds = CMTimeMakeWithSeconds(1.5, 600);
    twoSeconds = CMTimeMakeWithSeconds(2, 600);
    threeSeconds = CMTimeMakeWithSeconds(3, 600);
    fourSeconds = CMTimeMakeWithSeconds(4, 600);
    fiveSeconds = CMTimeMakeWithSeconds(5, 600);
    sixSeconds = CMTimeMakeWithSeconds(6, 600);
    sevenSeconds = CMTimeMakeWithSeconds(7, 600);
    eightSeconds = CMTimeMakeWithSeconds(8, 600);
    nineSeconds = CMTimeMakeWithSeconds(9, 600);
    tenSeconds = CMTimeMakeWithSeconds(10, 600);
    
    secondsOfA = twoSeconds;
    secondsOfB = oneSecond;
    
    firstSecond = CMTimeRangeMake(kCMTimeZero, oneSecond);
    compensationHeadStart = kCMTimeZero;
}


@end