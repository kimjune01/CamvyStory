
#import "CMVPreviewController.h"

#define ALREADY_EXPORTED 1
#define JUST_EXPORTED 2
#define INFO_BUTTON 3

@interface CMVPreviewController ()
- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys;
@end
static void *AVSEPlayerItemStatusContext = &AVSEPlayerItemStatusContext;
static void *AVSEPlayerLayerReadyForDisplay = &AVSEPlayerLayerReadyForDisplay;
@implementation CMVPreviewController

AVURLAsset *musicURLAsset;
AVPlayer *player;
AVSESpliceCommand *editCommand;
CompositionSingleton *sharedSingleton;
UITapGestureRecognizer *tapGestureRecognizer;
UISwipeGestureRecognizer *swipeGestureRecognizer;
bool exported = NO, launch = YES, veryFirstTime;
UIActivityIndicatorView *indicator;
int playCounter;

CGFloat screenWidth, screenHeight, sideMargin, topMargin, bottomMargin;

- (void)viewDidLoad{
    [super viewDidLoad];
	playCounter = 0;
    [self configureUI];
    [self.navigationController setDelegate:self];
    
    NSMutableArray *URLsArray = [[NSMutableArray alloc]init];
    sharedSingleton = [CompositionSingleton sharedSingleton];
    if ([sharedSingleton.bShotListURLs count]!=0) {
        URLsArray = sharedSingleton.bShotListURLs;
    }else if([sharedSingleton.aShotListURLs count]!=0){
        URLsArray = sharedSingleton.aShotListURLs;
    }
    
    [self checkIfVeryFirstTime];
    
    AVAsset *asset = [[AVURLAsset alloc]initWithURL:[URLsArray objectAtIndex:0] options:nil];
    NSArray *assetKeysToLoadAndTest = @[@"playable", @"composable", @"tracks", @"duration"];
	[asset loadValuesAsynchronouslyForKeys:assetKeysToLoadAndTest
                         completionHandler: ^{dispatch_async( dispatch_get_main_queue(),^{
        [self setUpPlaybackOfAsset:asset
                          withKeys:assetKeysToLoadAndTest];});
                         }];
    
	// Create AVPlayer, add rate and status observers
    player = [[AVPlayer alloc] init];
	[self setPlayer:player];
	[self addObservers];
    
}

-(void)checkIfVeryFirstTime{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    veryFirstTime = ![preferences boolForKey:@"veryFirstTime"];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //analytics
    self.screenName = @"Preview screen";
    //
    [self setUpGestureRecognizers];
    self.view.userInteractionEnabled = YES;
    
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    
}

-(void)addObservers{
    [self addObserver:self
           forKeyPath:@"player.currentItem.status"
              options:NSKeyValueObservingOptionNew
              context:AVSEPlayerItemStatusContext];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(editCommandCompletionNotificationReceiver:)
												 name:AVSEEditCommandCompletionNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(exportCommandCompletionNotificationReceiver:)
												 name:AVSEExportCommandCompletionNotification
											   object:nil];
}

-(void)setUpGestureRecognizers{
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                   action:@selector(didTap:)];
    [_playerView addGestureRecognizer:tapGestureRecognizer];
    
    swipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [_playerView addGestureRecognizer:swipeGestureRecognizer];
    
}

-(void)removeObservers{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self removeObserver:self forKeyPath:@"player.currentItem.status"];
    [self removeObserver:self forKeyPath:@"playerLayer.readyForDisplay"];
}

-(void)viewWillDisappear:(BOOL)animated{
    self.view.userInteractionEnabled = NO;
    
}


-(void)configureUI{
    self.view.backgroundColor = [UIColor darkGrayColor];
    _playerView.backgroundColor = [UIColor darkGrayColor];
	
    _playerLayer.zPosition = -100;
    _playButton.layer.zPosition = 1;
    _exportButton.layer.zPosition = 1;
    _changeMusicButton.layer.zPosition = 1;
    _resetButton.layer.zPosition = 1;
    _infoButton.layer.zPosition = 1;
    _moreButton.layer.zPosition = 1;
    
    
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    sideMargin = 8.0;
    topMargin = 13.0;
    bottomMargin = 8.0;
    
    _playerView.frame = screenRect;
    
    UIImage *exportImage = [UIImage imageNamed:@"exportStock.png"];
    [_exportButton setBackgroundImage:exportImage forState:UIControlStateNormal];
    [_exportButton setTitle:@"" forState:UIControlStateNormal];
    _exportButton.frame = CGRectMake(screenWidth-sideMargin-exportImage.size.width,
                                     screenHeight-bottomMargin-exportImage.size.height,
                                     exportImage.size.width,
                                     exportImage.size.height);
    _exportButton.hidden=YES;
    
    UIImage *musiconImage = [UIImage imageNamed:@"musicIcon.png"];
    [_changeMusicButton setBackgroundImage:musiconImage forState:UIControlStateNormal];
    [_changeMusicButton setTitle:@"" forState:UIControlStateNormal];
    _changeMusicButton.frame = CGRectMake((screenWidth-musiconImage.size.width)/2,
                                          screenHeight-musiconImage.size.height-bottomMargin,
                                          musiconImage.size.width,
                                          musiconImage.size.height);
    
    
    UIImage *resetImage = [UIImage imageNamed:@"trashStock.png"];
    [_resetButton setBackgroundImage:resetImage forState:UIControlStateNormal];
    [_resetButton setTitle:@"" forState:UIControlStateNormal];
    _resetButton.frame = CGRectMake(sideMargin,
                                    screenHeight-resetImage.size.height-bottomMargin,
                                    resetImage.size.width, resetImage.size.height);
    _resetButton.hidden=YES;
    
    UIImage *infoImage = [UIImage imageNamed:@"info.png"];
    [_infoButton setBackgroundImage:infoImage forState:UIControlStateNormal];
    [_infoButton setTitle:@"" forState:UIControlStateNormal];
    _infoButton.frame = CGRectMake(screenWidth-infoImage.size.width-sideMargin,
                                   topMargin,
                                   infoImage.size.width,
                                   infoImage.size.height);
    _infoButton.hidden=YES;
    
    UIImage *playImage = [UIImage imageNamed:@"play.png"];
    [_playButton setBackgroundImage:playImage forState:UIControlStateNormal];
    [_playButton setTitle:@"" forState:UIControlStateNormal];
    _playButton.hidden = YES;
    _playButton.frame = CGRectMake((screenWidth-playImage.size.width)/2,
                                   (screenHeight - playImage.size.height)/2,
                                   playImage.size.width,
                                   playImage.size.height);
    
    UIImage *moreImage = [UIImage imageNamed:@"left64.png"];
    [_moreButton setBackgroundImage:moreImage forState:UIControlStateNormal];
    [_moreButton setTitle:@"" forState:UIControlStateNormal];
    _moreButton.frame = CGRectMake(sideMargin,
                                   screenHeight-bottomMargin-(resetImage.size.height+resetImage.size.height)/2-moreImage.size.height-bottomMargin,
                                   moreImage.size.width,
                                   moreImage.size.height);
    
    
}

-(void)hidePlayingButtons{
    if (_exportButton.hidden == NO) {
        [UIView transitionWithView:_exportButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _exportButton.hidden=YES; }
                        completion:nil];
    }
    if (_infoButton.hidden == NO) {
        [UIView transitionWithView:_infoButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _infoButton.hidden=YES; }
                        completion:nil];
    }
    if (_resetButton.hidden == NO) {
        [UIView transitionWithView:_resetButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _resetButton.hidden=YES; }
                        completion:nil];
    }
    if (_playButton.hidden == NO) {
        [UIView transitionWithView:_playButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _playButton.hidden=YES; }
                        completion:nil];
    }
    if (_moreButton.hidden == NO) {
        [UIView transitionWithView:_moreButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{_moreButton.hidden=YES; }
                        completion:nil];
    }
    if (_changeMusicButton.alpha ==1) {
        [UIView transitionWithView:_changeMusicButton
                          duration:.3
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{_changeMusicButton.alpha = .4; }
                        completion:nil];
    }
    
}

-(void)showPlayingButtons{
    [UIView transitionWithView:_exportButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _exportButton.hidden=NO; }
                    completion:nil];
    _exportButton.enabled=YES;
    [UIView transitionWithView:_infoButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _infoButton.hidden=NO; }
                    completion:nil];
    _infoButton.enabled=YES;
    [UIView transitionWithView:_resetButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _resetButton.hidden=NO; }
                    completion:nil];
    _resetButton.enabled=YES;
    [UIView transitionWithView:_playButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _playButton.hidden=NO; }
                    completion:nil];
    _playButton.enabled=YES;
    [UIView transitionWithView:_moreButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _moreButton.hidden=NO; }
                    completion:nil];
    _moreButton.enabled=YES;
    [UIView transitionWithView:_changeMusicButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{_changeMusicButton.alpha = 1; }
                    completion:nil];
    _changeMusicButton.enabled=YES;
    
}

-(NSUInteger)supportedInterfaceOrientations{
	return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - Playback

- (void)setUpPlaybackOfAsset:(AVAsset *)asset withKeys:(NSArray *)keys{
	// This method is called when AVAsset has completed loading the specified array of keys.
	// playback of the asset is set up here.
	
	// Set up an AVPlayerLayer
	if ([[asset tracksWithMediaType:AVMediaTypeVideo] count] != 0) {
		// Create an AVPlayerLayer and add it to the player view if there is video, but hide it until it's ready for display
		AVPlayerLayer *newPlayerLayer = [AVPlayerLayer playerLayerWithPlayer:[self player]];
		
        //
        //[newPlayerLayer setFrame:[[[self playerView] layer] bounds]];
        double videoWidth = 480, videoHeight = 640;
        double screenRatio = [[UIScreen mainScreen] bounds].size.width/[[UIScreen mainScreen] bounds].size.height;
        double videoRatio = videoWidth/videoHeight;
        if (screenRatio>videoRatio) {
            videoWidth = screenWidth;
            videoHeight = videoWidth/videoRatio;
        }else{
            videoHeight = screenHeight;
            videoWidth = videoHeight*videoRatio;
        }
		[newPlayerLayer setFrame:CGRectMake(-(videoWidth-screenWidth)/2, -(videoHeight-screenHeight)/2, videoWidth, videoHeight)];
        [newPlayerLayer setHidden:YES];
		//
        
        [[[self playerView] layer] addSublayer:newPlayerLayer];
		[self setPlayerLayer:newPlayerLayer];
		[self addObserver:self forKeyPath:@"playerLayer.readyForDisplay" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:AVSEPlayerLayerReadyForDisplay];
	}
	
	[self splice];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
	if (context == AVSEPlayerItemStatusContext) {
		AVPlayerStatus status = [change[NSKeyValueChangeNewKey] integerValue];
		BOOL enable = NO;
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				enable = YES;
				break;
                
		}
		[[self playButton] setEnabled:enable];
	} else if (context == AVSEPlayerLayerReadyForDisplay) {
		if ([change[NSKeyValueChangeNewKey] boolValue] == YES) {
			[[self playerLayer] setHidden:NO];
		}
	} else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (double)duration{
	AVPlayerItem *playerItem = [[self player] currentItem];
	if ([playerItem status] == AVPlayerItemStatusReadyToPlay)
		return CMTimeGetSeconds([[playerItem asset] duration]);
	else
		return 0.f;
}

- (double)currentTime{
	return CMTimeGetSeconds([[self player] currentTime]);
}

- (void)setCurrentTime:(double)time{
	[[self player] seekToTime:CMTimeMakeWithSeconds(time, 1)];
}

- (void)didTap:(UIGestureRecognizer*)recognizer{
	[self playPauseToggle];
    
}

-(void)didSwipe:(UIGestureRecognizer*)recognizer{
    [self moreButton:self];
}

- (void)playPauseToggle{
    
    if (launch) {
        launch=NO;
        if (veryFirstTime) {
            [self.view ap_makeToast:@"Add your own music to add personality!" duration:3 position:APToastPositionTop];
        }
    }
    
    if ([[self player] rate] != 1.f) {
		if ([self currentTime] == [self duration])
			[self setCurrentTime:0.f];
		[[self player] play];
        [self hidePlayingButtons];
	} else {
		[[self player] pause];
        [self showPlayingButtons];
	}
}

- (void)reloadPlayerView{
	// This method is called every time a tool has been applied to a composition
	self.videoComposition.animationTool = NULL;
	AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(videoDidFinishPlaying:)
                                                 name:AVPlayerItemDidPlayToEndTimeNotification
                                               object:playerItem];
    
	playerItem.videoComposition = self.videoComposition;
	playerItem.audioMix = self.audioMix;
	
	[[self player] replaceCurrentItemWithPlayerItem:playerItem];
	
}

-(void)videoDidFinishPlaying:(NSNotification *) notification {
    if (veryFirstTime) {
        [self.view ap_makeToast:@"Press the back button to make more videos!" duration:5 position:APToastPositionTop];
    }
    
    [self showPlayingButtons];
    
    [UIView transitionWithView:_playButton
                      duration:.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _playButton.hidden=NO; }
                    completion:nil];
    
}

#pragma mark - Utilities

- (void)exportWillBegin{
    swipeGestureRecognizer.enabled=NO;
	tapGestureRecognizer.enabled=NO;
    _changeMusicButton.enabled=NO;
    _infoButton.enabled=NO;
    _exportButton.enabled=NO;
    _resetButton.enabled=NO;
    _playButton.hidden = YES;
    _moreButton.enabled=NO;
    
}

- (void)exportDidEnd{
    swipeGestureRecognizer.enabled=YES;
	tapGestureRecognizer.enabled=YES;
    _changeMusicButton.enabled=YES;
    _infoButton.enabled=YES;
    _resetButton.enabled=YES;
	_exportButton.enabled=YES;
    _moreButton.enabled=YES;
    exported=YES;
    
    [self showExportEndedDialog];
    
}

-(void)showExportEndedDialog{
    NSString *exportAlertTitle = @"Export finished";
    NSMutableString *exportAlertMessage = [[NSMutableString alloc] initWithString: @"Your video is now in your photo album"];
    
    if (sharedSingleton.errorMessage != nil) {
        exportAlertTitle = @"Export Failed";
        exportAlertMessage = [[NSMutableString alloc] initWithString: sharedSingleton.errorMessage];
        if ([sharedSingleton.errorMessage isEqualToString:@"User denied access"]) {
            [exportAlertMessage appendString: @"\nPlease give us permission to access your photo library in your settings"];
        }
    }else{
        [self itsNotTheVeryFirstTime];
    }
    
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:exportAlertTitle
                                                     message:exportAlertMessage
                                                    delegate:self
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles: nil];
    [alert show];
    alert.tag = JUST_EXPORTED;
    
}

-(void)itsNotTheVeryFirstTime{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    veryFirstTime = YES;
    [preferences setBool:YES forKey:@"veryFirstTime"];
}

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case INFO_BUTTON:
            switch (buttonIndex) {
                case 0:
                    break;
                case 1:
                    [self linkToWebsite];
                    break;
                default:
                    break;
            }
            break;
        case ALREADY_EXPORTED:
            switch (buttonIndex) {
                case 0:
                    break;
                default:
                    break;
            }
            break;
        case JUST_EXPORTED:
            switch (buttonIndex) {
                case 0:
                    if (veryFirstTime) {
                        [self.view ap_makeToast:@"Press the back button to make more videos!" duration:5 position:APToastPositionTop];
                    }
                    break;
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
    
}

-(void)linkToWebsite{
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.camvy.com"]];
}

- (void)editCommandCompletionNotificationReceiver:(NSNotification*) notification{
	if ([[notification name] isEqualToString:AVSEEditCommandCompletionNotification]) {
		self.composition = [[notification object] mutableComposition];
		self.videoComposition = [[notification object] mutableVideoComposition];
		self.audioMix = [[notification object] mutableAudioMix];
		dispatch_async( dispatch_get_main_queue(), ^{
			[self reloadPlayerView];
            [self playPauseToggle];
		});
	}
}

- (void)exportCommandCompletionNotificationReceiver:(NSNotification *)notification
{
	if ([[notification name] isEqualToString:AVSEExportCommandCompletionNotification]) {
		dispatch_async( dispatch_get_main_queue(), ^{
			[self exportDidEnd];
		});
	}
}

#pragma mark - Editing Tools


-(void)splice{
    editCommand = [[AVSESpliceCommand alloc] initWithComposition:self.composition
                                                videoComposition:self.videoComposition
                                                        audioMix:self.audioMix];
    [editCommand perform];
}

- (IBAction)exportToMovie:(id)sender{
    if (exported) {
        [self.view ap_makeToast:@"Check your photo album!" duration:2 position:APToastPositionTop];
    }else{
        [self exportWillBegin];
        exportCommand = [[AVSEExportCommand alloc] initWithComposition:self.composition
                                                      videoComposition:self.videoComposition
                                                              audioMix:self.audioMix];
        [exportCommand perform];
    }
}

- (IBAction)changeMusicButton:(id)sender {
    [player pause];
    [self presentMediaPicker];
    
}

- (IBAction)resetButton:(id)sender {
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reset" object:self];
    [sharedSingleton resetSingleton];
    [self.navigationController popViewControllerAnimated:YES];
    ///
    tapGestureRecognizer.enabled=NO;
    swipeGestureRecognizer.enabled=NO;
}

- (IBAction)infoButton:(id)sender {
    //
    UIAlertView * alert =[[UIAlertView alloc ] initWithTitle:@"Leave us feedback"
                                                     message:@"Can you help us make this app better? Go to www.camvy.com"
                                                    delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles: nil];
    [alert addButtonWithTitle:@"Go"];
    alert.tag = INFO_BUTTON;
    [alert show];
}

- (IBAction)playButton:(id)sender {
    [self playPauseToggle];
}

- (IBAction)moreButton:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
    [[self player] pause];
    tapGestureRecognizer.enabled=NO;
    swipeGestureRecognizer.enabled=NO;
}

-(void)presentMediaPicker{
    MPMediaPickerController *picker =
    [[MPMediaPickerController alloc]
     initWithMediaTypes: MPMediaTypeAnyAudio];
    
    [picker setDelegate: self];
    picker.prompt =
    NSLocalizedString (@"Add your music to the video",
                       "Prompt in media item picker");
    [self presentViewController:picker animated:YES completion:nil];
    
}

- (void) mediaPicker: (MPMediaPickerController *) mediaPicker
   didPickMediaItems: (MPMediaItemCollection *) collection {
    
    [self dismissViewControllerAnimated:YES completion:nil];
    [self identifyMusicIn: collection];
}

-(void) identifyMusicIn:(MPMediaItemCollection *) collection{
    MPMediaItem *musicItem = [[collection items] firstObject];
    NSURL *musicURL = [musicItem valueForProperty:MPMediaItemPropertyAssetURL];
    sharedSingleton.musicPath = musicURL;
    [editCommand addAudio];
    exported=NO;
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker{
    [self dismissViewControllerAnimated:YES completion:nil];
}


- (void)viewDidUnload {
    [self setChangeMusicButton:nil];
    [self setResetButton:nil];
    [self setPlayButton:nil];
    [self setInfoButton:nil];
    [self setInfoButton:nil];
    [self setPlayButton:nil];
    [super viewDidUnload];
}

-(void)dealloc{
    [self removeObservers];
}

@end