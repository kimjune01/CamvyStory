
#import "CMVPreviewController.h"
#import "CMVCameraViewController.h"
#import "CompositionSingleton.h"
#import "CMVBlueRedSwapFilter.h"
#import "CMVLookupFilter.h"
#import "CMVTutorialView.h"


#define IS_WIDESCREEN ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )
#define IS_IPHONE ( [ [ [ UIDevice currentDevice ] model ] isEqualToString: @"iPhone" ] )
#define IS_IPHONE_5 ( IS_IPHONE && IS_WIDESCREEN )
#define IS_IPHONE_4 ( IS_IPHONE && !IS_WIDESCREEN )
#define FAST 0.2
#define MEDIUM 0.35
#define SLOW 0.5

@implementation CMVCameraViewController

NSString *AVCaptureSessionPreset;
GPUImageView *filterView;
int filterCounter = 3000, longPressCounter;
float progress;
float kBrollSeconds = 1.0;
BOOL isBackCameraOn, isFlashOn, isRecordingSomething = NO;
int bShotCounter = 0;
int aShotCounter = 0;
int kShotsRequired = 2, kShotsSuggested = 5;
NSTimer *timer;
float timeElapsed, aRollTimeElapsed, bRollTimeElapsed;
float timeInterval = .05f;
BOOL recordingAroll, viewsAreGray;
UISwipeGestureRecognizer *leftSwipeGestureRecognizer;
UISwipeGestureRecognizer *rightSwipeGestureRecognizer;
UITapGestureRecognizer *tapGestureRecognizer;
UILongPressGestureRecognizer *longPressGestureRecognizer;
CompositionSingleton *sharedSingleton;
NSString *shotTitle;
bool firstToastRecordAroll = YES, firstToastSwitchButton = YES, firstToastMakeButton = YES, firstToastSwipe = YES, firstToastUndoButton = YES, veryFirstTime;
int toastRecordBButtonCounter, launchCounter = 0;
NSInteger toastOnScreen, switchToastOnScreen, selfieStoryToastOnScreen, cutToastOnScreen, undoToast;

UIImage *rotateImage;
UIImageView * launchScreenImageView;
CGFloat screenWidth, screenHeight, sideMargin, topMargin, bottomMargin;

CMVCameraViewController *previewController;
GPUImageGaussianBlurFilter *gaussianFilter;
CGFloat blurRadius;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self startBackCamera];
    [self configureCamera];
    [self startBlurryFilter];
    [self initialize];
    [self configureTimers];
    [self configureFrontFlash];
    [self disableImpossibleButtons];
    [self getSingleton];
    [self addResetNotificationCenter];
    [self configureImages];
    [self checkIfVeryFirstTime];
}

-(void)checkIfVeryFirstTime{
    NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
    veryFirstTime = ![preferences boolForKey:@"veryFirstTime"];
}


- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    //analytics
    self.screenName = @"Camera screen";
    //
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    [videoCamera resumeCameraCapture];
    self.view.userInteractionEnabled = YES;
    [self.view insertSubview:_undoButton aboveSubview:_recordingIndicator];
}

-(void)viewDidAppear:(BOOL)animated{
    [self configureSwipeGestureRecognizers];
    [self disableRecordToggleFor:0.6];
    [super viewDidAppear:animated];
    if ([sharedSingleton.bShotListURLs count]==0) {
        //
        [self disableMakeButton];
    }
    
    if (launchCounter==0) {
        UIImage *launchScreenImage = [[UIImage alloc]init];
        launchCounter++;
        if (IS_IPHONE_4) {
            launchScreenImage = [UIImage imageNamed:@"default-iphone-4.png"];
        }else if(IS_IPHONE_5){
            launchScreenImage = [UIImage imageNamed:@"default-iphone-5.png"];
        }
        launchScreenImageView = [[UIImageView alloc] initWithImage:launchScreenImage];
        [self.view addSubview:launchScreenImageView];
        [UIView animateWithDuration:SLOW animations:^{launchScreenImageView.hidden=YES;}];
        
        if (veryFirstTime){
            [self beginTutorial];
        }else{
            [self stopBlurryFilter];
            [self enableTapGestureRecognizer];
            [self enableSwipeGestureRecognizers];
            [self revealImages];
        }
        
        
    }else if(launchCounter==1){
        
        if (veryFirstTime) {
            launchCounter++;
            if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
                [self.view ap_makeToast:@"Add more moments to your video!" duration:3 position:APToastPositionCenter];
            }else{
                [self.view ap_makeToast:@"Add more Selfie Stories to your video!" duration:3 position:APToastPositionCenter];
            }
            
            [self.view ap_makeToast:@"Swipe left or right to swap filters!" duration:3 position:APToastPositionCenter];
        }
        
    }
    
    
}

-(void)beginTutorial{
    
    CGPoint center = CGPointMake(screenWidth/2, screenHeight/2);
    CGFloat verticalRoom = 55;
    CGFloat horizontalRoom = 40;
    
    [self disableTapGestureRecognizer];
    [self disableSwipeGestureRecognizers];
    
    CMVTutorialView *tutorialView0 = [[CMVTutorialView alloc] initWithWidth:screenWidth-horizontalRoom
                                                                     height:screenHeight-verticalRoom
                                                                      title:@"Welcome"
                                                                 andMessage:@"Camvy Story is\nan automatic video\nediting app"
                                                               withTriangle:YES];
    [self disableTapGestureRecognizer];
    [self disableSwipeGestureRecognizers];
    [self.view ap_makeToastView:tutorialView0 duration:FLT_MAX center:center tapToComplete:YES completion:^{
        
        
        CMVTutorialView *tutorialView1 = [[CMVTutorialView alloc] initWithWidth:screenWidth-horizontalRoom
                                                                         height:screenHeight-verticalRoom
                                                                          title:@""
                                                                     andMessage:@"Record 1 second moments with the back camera"
                                                                   withTriangle:YES];
        [self disableTapGestureRecognizer];
        [self disableSwipeGestureRecognizers];
        [self.view ap_makeToastView:tutorialView1 duration:FLT_MAX center:center tapToComplete:YES completion:^{
            [videoCamera rotateCamera];
            
            CMVTutorialView *tutorialView2 = [[CMVTutorialView alloc] initWithWidth:screenWidth-horizontalRoom
                                                                             height:screenHeight-verticalRoom
                                                                              title:@""
                                                                         andMessage:@"Record 5-10 second Selfie Stories\nwith the front camera"
                                                                       withTriangle:YES];
            [self.view ap_makeToastView:tutorialView2 duration:FLT_MAX center:center tapToComplete:YES completion:^{
                
                [self disableTapGestureRecognizer];
                [self disableSwipeGestureRecognizers];
                [videoCamera rotateCamera];
                
                CMVTutorialView *tutorialView3 = [[CMVTutorialView alloc] initWithWidth:screenWidth-horizontalRoom
                                                                                 height:screenHeight-verticalRoom
                                                                                  title:@""
                                                                             andMessage:@"Automatically combine them together into a video\n\n Let's begin!"
                                                                           withTriangle:YES];
                [self.view ap_makeToastView:tutorialView3
                                   duration:FLT_MAX
                                     center:center
                              tapToComplete:YES
                                 completion:^{
                                     
                                     [self stopBlurryFilter];
                                     [self enableTapGestureRecognizer];
                                     [self enableSwipeGestureRecognizers];
                                     [self revealImages];
                                     
                                     toastOnScreen = [self.view ap_makeToast:@"Tap to record the first moment!" duration:99 position:APToastPositionCenter];
                                 }];
                
            }];
            
        }];
        
        
    }];
    
}

-(void)addResetNotificationCenter{
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(resetNotificationReceiver:)
												 name:@"reset"
											   object:nil];
}

-(void)revealImages{
    [UIView transitionWithView:_makeButton
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _makeButton.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_flashButton
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _flashButton.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_switchButton
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _switchButton.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_undoButton
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _undoButton.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_recordButton
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordButton.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_recordingIndicator
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordingIndicator.hidden=NO;}
                    completion:nil];
    [UIView transitionWithView:_timerLabel
                      duration:SLOW
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _timerLabel.hidden=NO;}
                    completion:nil];
    
}

-(void)configureImages{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    screenWidth = screenRect.size.width;
    screenHeight = screenRect.size.height;
    sideMargin = 8.0;
    topMargin = 8.0;
    bottomMargin = 8.0;
    rotateImage = [UIImage imageNamed:@"rotateCameraStock.png"];
    UIImage *undoImage = [UIImage imageNamed:@"UndoStock.png"];
    [_undoButton setBackgroundImage:undoImage forState:UIControlStateNormal];
    [_undoButton setTitle:@"" forState:UIControlStateNormal];
    _undoButton.frame = CGRectMake(screenWidth-sideMargin-undoImage.size.width,
                                   topMargin,
                                   undoImage.size.width,
                                   undoImage.size.height);
    
    UIImage *cutImage = [UIImage imageNamed:@"clapper.png"];
    [_makeButton setBackgroundImage:cutImage forState:UIControlStateNormal];
    [_makeButton setTitle:@"" forState:UIControlStateNormal];
    _makeButton.frame = CGRectMake(screenWidth-sideMargin-cutImage.size.width,
                                   screenHeight-bottomMargin-cutImage.size.height,
                                   cutImage.size.width,
                                   cutImage.size.height);
    
    UIImage *flashImage = [UIImage imageNamed:@"flashNonStock.png"];
    [_flashButton setBackgroundImage:flashImage forState:UIControlStateNormal];
    [_flashButton setTitle:@"" forState:UIControlStateNormal];
    _flashButton.frame = CGRectMake(sideMargin,
                                    screenHeight-bottomMargin-(rotateImage.size.height+rotateImage.size.height)/2-flashImage.size.height-bottomMargin,
                                    flashImage.size.width,
                                    flashImage.size.height);
    
    UIImage *recordImage = [UIImage imageNamed:@"record.png"];
    [_recordButton setBackgroundImage:recordImage forState:UIControlStateNormal];
    [_recordButton setTitle:@"" forState:UIControlStateNormal];
    _recordButton.frame = CGRectMake((screenWidth-recordImage.size.width)/2,
                                     screenHeight-bottomMargin-recordImage.size.height,
                                     recordImage.size.width,
                                     recordImage.size.height);
    
    [_switchButton setBackgroundImage:rotateImage forState:UIControlStateNormal];
    [_switchButton setTitle:@"" forState:UIControlStateNormal];
    _switchButton.frame = CGRectMake(sideMargin,
                                     screenHeight-bottomMargin-(rotateImage.size.height+rotateImage.size.height)/2,
                                     rotateImage.size.width,
                                     rotateImage.size.height);
    
    _recordingIndicator = [[UIView alloc]initWithFrame:CGRectMake(0, 0, screenWidth, 36)];
    _recordingIndicator.backgroundColor = [UIColor blackColor];
    _recordingIndicator.alpha = .2;
    _recordingIndicator.hidden=YES;
    _recordingIndicator.userInteractionEnabled=NO;
    [self.view addSubview:_recordingIndicator];
    
}

-(void)getSingleton{
    sharedSingleton = [CompositionSingleton sharedSingleton];
}

-(void)disableImpossibleButtons{
    [self disableMakeButton];
    [self disableUndoButton];
}

-(void)enableMake{
    if (_makeButton.enabled == NO) {
        [self enableMakeButton];
    }
    
}

-(void)configureFrontFlash{
    
    _frontFlash.backgroundColor = [UIColor whiteColor];
    _frontFlash.alpha = 0.9f;
    _frontFlash.hidden = YES;
    [self turnViewsWhite];
}

-(void)configureSwipeGestureRecognizers{
    leftSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeLeft:)];
    leftSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionLeft;
    [filterView addGestureRecognizer:leftSwipeGestureRecognizer];
    
    rightSwipeGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipeRight:)];
    rightSwipeGestureRecognizer.direction = UISwipeGestureRecognizerDirectionRight;
    [filterView addGestureRecognizer:rightSwipeGestureRecognizer];
    
    tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTap:)];
    [filterView addGestureRecognizer:tapGestureRecognizer];
    [self disableTapGestureRecognizer];
    
    longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPress:)];
    [filterView addGestureRecognizer:longPressGestureRecognizer];
}

-(void)didLongPress:(UIGestureRecognizer*)recognizer{
    longPressCounter++;
    if (longPressCounter == 100) {
        veryFirstTime = NO;
        NSUserDefaults* preferences = [NSUserDefaults standardUserDefaults];
        [preferences setBool:NO forKey:@"veryFirstTime"];
    }
}

-(void)configureTimers{
    _timerLabel.font=[UIFont fontWithName:@"ArialUnicodeMS" size:70.0];
    _timerLabel.text=@"0.000    ";
    [UIView transitionWithView:_timerLabel
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _timerLabel.alpha = .65; }
                    completion:nil];
    _timerLabel.textColor = [UIColor whiteColor];
    
    [_timerLabel sizeToFit];
    
}

-(void)incrementShotCounter{
    [self enableUndoButton];
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        bShotCounter++;
    }else{
        aShotCounter++;
    }
    
    if (bShotCounter==kShotsRequired) {
        [self enableMake];
        
    }
}

-(void)restartArollProgress{
    timer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateAProgress:) userInfo:nil repeats:YES];
}

-(void)updateAProgress:(NSTimer *)timer{
    aRollTimeElapsed +=.01;
    NSMutableString *currentTime = [NSMutableString stringWithFormat:@"%.2f",aRollTimeElapsed];
    [currentTime appendString:[NSString stringWithFormat:@"%d",  arc4random() % 9]];
    _timerLabel.text = currentTime;
}

-(void)stopArollProgress{
    [timer invalidate];
}

-(void)restartBrollProgress{
    [self indicateRecording];
    _timerLabel.text = @"0.000";
    bRollTimeElapsed=0;
    timer = [NSTimer scheduledTimerWithTimeInterval:.01 target:self selector:@selector(updateBProgress:) userInfo:nil repeats:YES];
}

-(void)indicateRecording{
    [UIView transitionWithView:_recordingIndicator
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordingIndicator.alpha = .65;
                        _recordingIndicator.backgroundColor = [UIColor redColor];}
                    completion:nil];
    
    
}

-(void)stopIndicatingRecording{
    [UIView transitionWithView:_recordingIndicator
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordingIndicator.alpha = .2;
                        _recordingIndicator.backgroundColor = [UIColor blackColor];}
                    completion:nil];
    
}

-(void)updateBProgress:(NSTimer *)timer{
    
    bRollTimeElapsed = MIN(bRollTimeElapsed+.01, 1);
    NSMutableString *currentTime = [NSMutableString stringWithFormat:@"%.2f",bRollTimeElapsed];
    
    
    
    if (bRollTimeElapsed == 1.0) {
        [self stopIndicatingRecording];
        [UIView transitionWithView:_timerLabel
                          duration:FAST
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _timerLabel.alpha = .65; }
                        completion:nil];
        [currentTime appendString:[NSString stringWithFormat:@"%d",0]];
        [self enableButtons];
    }else{
        [currentTime appendString:[NSString stringWithFormat:@"%d",  arc4random() % 9]];
    }
    
    _timerLabel.text = currentTime;
}

-(void)disableTapGestureRecognizer{
    tapGestureRecognizer.enabled=NO;
}

-(void)enableTapGestureRecognizer{
    
    tapGestureRecognizer.enabled=YES;
}

-(void)disableSwipeGestureRecognizers{
    rightSwipeGestureRecognizer.enabled=NO;
    leftSwipeGestureRecognizer.enabled=NO;
}

-(void)enableSwipeGestureRecognizers{
    rightSwipeGestureRecognizer.enabled=YES;
    leftSwipeGestureRecognizer.enabled=YES;
}

-(void)disableRecordButton{
    [UIView transitionWithView:_recordButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordButton.enabled=NO;}
                    completion:nil];
}

-(void)disableMakeButton{
    [UIView transitionWithView:_makeButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _makeButton.enabled=NO;}
                    completion:nil];
}

-(void)disableSwitchButton{
    [UIView transitionWithView:_switchButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _switchButton.enabled=NO;}
                    completion:nil];
}

-(void)disableFlashButton{
    [UIView transitionWithView:_flashButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _flashButton.enabled=NO;}
                    completion:nil];
}

-(void)disableUndoButton{
    [UIView transitionWithView:_undoButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _undoButton.enabled=NO;}
                    completion:nil];
}


-(void)disableButtons{
    [self disableMakeButton];
    [self disableRecordButton];
    [self disableFlashButton];
    [self disableSwitchButton];
    [self disableUndoButton];
}

-(void)enableMakeButton{
    [UIView transitionWithView:_makeButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{if(sharedSingleton.bShotListURLs!=0)
                        _makeButton.enabled=YES;
                    }
                    completion:nil];
}

-(void)enableFlashButton{
    [UIView transitionWithView:_flashButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _flashButton.enabled=YES;}
                    completion:nil];
}

-(void)enableSwitchButton{
    [UIView transitionWithView:_switchButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _switchButton.enabled=YES;}
                    completion:nil];
}

-(void)enableRecordButton{
    [UIView transitionWithView:_recordButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _recordButton.enabled=YES;}
                    completion:nil];
}


-(void)enableUndoButton{
    [UIView transitionWithView:_undoButton
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _undoButton.enabled=YES;}
                    completion:nil];
}

-(void)enableButtons{
    [self enableMakeButton];
    [self enableFlashButton];
    [self enableSwitchButton];
    [self enableRecordButton];
    [self enableUndoButton];
}

-(void)didTap:(UIGestureRecognizer*)recognizer{
    
    if (recordingAroll) {
        [self stopRecordingAroll];
    }else{
        if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
            if (movieWriter.assetWriter.status !=AVAssetWriterStatusWriting || movieWriter.assetWriter.status !=AVAssetWriterStatusCompleted) {
                [self recordBroll];
            }
        }else{
            [self startRecordingAroll];
        }
    }
    
}

-(void)didSwipeLeft:(UIGestureRecognizer*)recognizer{
    filterCounter++;
    [self refreshFilter];
    
}

-(void)didSwipeRight:(UIGestureRecognizer*)recognizer{
    filterCounter--;
    [self refreshFilter];
}

-(void)refreshFilter{
    bool wasRecordingAroll = recordingAroll;
    if (wasRecordingAroll) {
        [self stopRecordingAroll];
    }
    [self refreshCamera];
    [self configureCamera];
    [self startFilter];
    [self initialize];
    if (wasRecordingAroll) {
        [self startRecordingAroll];
    }
}

-(void)startFrontCamera{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    isBackCameraOn=videoCamera.inputCamera.position == AVCaptureDevicePositionFront;
}

-(void)startBackCamera{
    videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    isBackCameraOn=videoCamera.inputCamera.position == AVCaptureDevicePositionBack;
}

-(void)refreshCamera{
    if (videoCamera.cameraPosition == AVCaptureDevicePositionFront) {
        [self startFrontCamera];
    }else if( videoCamera.cameraPosition == AVCaptureDevicePositionBack){
        [self startBackCamera];
    }
}

-(void)configureCamera{
    videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    videoCamera.horizontallyMirrorRearFacingCamera = NO;
}

-(void)startBlurryFilter{
    gaussianFilter = [[GPUImageGaussianBlurFilter alloc] init];
    blurRadius = 10;
    gaussianFilter.blurRadiusInPixels = blurRadius;
    filter = gaussianFilter;
    
    CMVLookupFilter *lookupFilter = [[CMVLookupFilter alloc] initWithImageName:@"lookup_miss_etikate.png"];
    [lookupFilter addTarget:filter];
    
    [videoCamera addTarget:lookupFilter];
    filterView = (GPUImageView *)self.view;
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
}

-(void)stopBlurryFilter{
    NSTimer *blurTimer = [NSTimer scheduledTimerWithTimeInterval:.05
                                                          target:self
                                                        selector:@selector(updateBlurProgress:)
                                                        userInfo:nil repeats:YES];
    blurTimer = blurTimer;
}

-(void)updateBlurProgress:(NSTimer *)timer{
    if (blurRadius<=0) {
        [timer invalidate];
        
    }else{
        blurRadius -= 0.3;
        gaussianFilter.blurRadiusInPixels = blurRadius;
    }
}

-(void)startFilter{
    NSString *imageName;
    switch (filterCounter%3) {
        case 0:
            imageName = @"lookup_miss_etikate.png";
            break;
        case 1:
            imageName = @"lookup_CineStyle.png";
            break;
        case 2:
            imageName = @"lookup_RGB.png";
            break;
        default:imageName = @"lookup_RGB.png";
            break;
    }
    filter = [[CMVLookupFilter alloc]initWithImageName:imageName];
    [videoCamera addTarget:filter];
    filterView = (GPUImageView *)self.view;
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
}


-(void)initialize{
    [self startMovieWriter];
    [filter addTarget:movieWriter];
    videoCamera.audioEncodingTarget = movieWriter;
    [filter addTarget:filterView];
    [videoCamera startCameraCapture];
}

-(void)startMovieWriter{
    // Start recording to a temporary file array.
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        shotTitle = [NSString stringWithFormat:@"b_shot_%03d", bShotCounter];
    }else{
        shotTitle = [NSString stringWithFormat:@"a_shot_%03d", aShotCounter];
    }
    
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[shotTitle stringByAppendingPathExtension:@"mov"]];
    unlink([tempFilePath UTF8String]);// If a file already exists, AVAssetWriter won't let you record new frames, so delete the old movie
    movieURL = [NSURL fileURLWithPath:tempFilePath];
    movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(480.0, 640.0)];
    movieWriter.delegate = self;
    movieWriter.encodingLiveVideo = YES;
}

-(void)didFinishRecording:(NSURL *)outputFileURL{
    [self addMovieURLToSingleton];
    [self initialize];
    [self enableTapGestureRecognizer];
    
    [self enableSwipeGestureRecognizers];
}

-(void)addMovieURLToSingleton{
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        [sharedSingleton.bShotListURLs addObject:movieURL];
    }else{
        [sharedSingleton.aShotListURLs addObject:movieURL];
    }
}

- (IBAction)switchButton:(id)sender {
    [self.view ap_ejectToast:switchToastOnScreen];
    if (firstToastSwitchButton) {
        firstToastSwitchButton = NO;
        if (veryFirstTime) {
            [self.view ap_makeToast:@"The front camera records for as long as you want!" duration:5 position:APToastPositionCenter];
            selfieStoryToastOnScreen = [self.view ap_makeToast:@"Tap to capture your selfie story!" duration:99 position:APToastPositionCenter];
        }
    }
    
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        if (videoCamera.inputCamera.torchMode == AVCaptureTorchModeOn) {
            isFlashOn = YES;
        }else{
            isFlashOn = NO;
        }
        if ([sharedSingleton.aShotListURLs count] ==0) {
            [self disableUndoButton];
        }
    }else if(videoCamera.inputCamera.position == AVCaptureDevicePositionFront){
        if (_frontFlash.hidden==NO) {
            isFlashOn = YES;
        }else if(_frontFlash.hidden == YES){
            isFlashOn = NO;
        }
        if ([sharedSingleton.bShotListURLs count] ==0) {
            [self disableUndoButton];
        }
    }
    
    [videoCamera rotateCamera];
    
    if (isFlashOn) {
        [self turnFlashOn];
    }else{
        [self turnFlashOff];
    }
    
}

-(void)startRecordingAroll{
    recordingAroll=YES;
    if (aShotCounter==0||sharedSingleton.aShotListURLs==0) {
        [self disableRecordToggleFor:1.04];
        
        dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC);
        dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
            if (recordingAroll && veryFirstTime) {
                [self.view ap_makeToast:@"Tap to stop whenever you are done!" duration:3 position:APToastPositionCenter];
            }
            
        });
    }
    [self disableRecordToggleFor:.10];
    [self.view ap_ejectToast:selfieStoryToastOnScreen animated:YES];
    
    
    NSLog(@"isRecordingSomething: %d", isRecordingSomething);
    NSLog(@"movieWriter.assetWriter.status: %d", movieWriter.assetWriter.status);
    
    
    if (!isRecordingSomething) {
        [self indicateRecording];
        [self incrementShotCounter];
        [self restartArollProgress];
        [self disableMakeButton];
        [self disableFlashButton];
        [self disableSwitchButton];
        [self disableUndoButton];
        [movieWriter startRecording];
        isRecordingSomething = YES;
        
    }
    
    [UIView transitionWithView:_timerLabel
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _timerLabel.alpha = .2; }
                    completion:nil];
}

-(void)disableRecordToggleFor:(float) seconds{
    BOOL recordEnabled = _recordButton.enabled;
    if (recordEnabled) {
        [self disableRecordButton];
        [self disableTapGestureRecognizer];
    }
    
    dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, seconds * NSEC_PER_SEC);
    dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
        if (recordEnabled) {
            [self enableTapGestureRecognizer];
            [self enableRecordButton];
        }
        
    });
}




-(void)stopRecordingAroll{
    if (firstToastRecordAroll) {
        firstToastRecordAroll=NO;
        if (veryFirstTime) {
            cutToastOnScreen = [self.view ap_makeToast:@"Press edit & play to make the video!" duration:99 position:APToastPositionCenter];
        }
        
    }
    
    if (recordingAroll) {
        
        
        if (isRecordingSomething) {
            [self stopIndicatingRecording];
            [self enableMakeButton];
            [self enableFlashButton];
            [self enableSwitchButton];
            [self enableUndoButton];
            [movieWriter finishRecording];
            isRecordingSomething = NO;
        }
        [self didFinishRecording:movieURL];
        [self stopArollProgress];
        recordingAroll=NO;
    }
    timeElapsed=0;
    
    
    [UIView transitionWithView:_timerLabel
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _timerLabel.alpha = .65; }
                    completion:nil];
}

-(void)recordBroll{
    [self disableButtons];
    [self disableSwipeGestureRecognizers];
    [self disableTapGestureRecognizer];
    
    if (bShotCounter==0) {
        [self.view ap_ejectToast:toastOnScreen];
    }else if(bShotCounter == 1){
        [self.view ap_ejectToast:toastOnScreen];
    }else if(bShotCounter > 2){
        
    }
    
    [UIView transitionWithView:_timerLabel
                      duration:FAST
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{ _timerLabel.alpha = .2; }
                    completion:nil];
    [self restartBrollProgress];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),
                   ^(void){
                       if (!isRecordingSomething) {
                           [movieWriter startRecording];
                           isRecordingSomething = YES;
                       }
                       double delayInSeconds = (double)kBrollSeconds;
                       dispatch_time_t stopTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
                       dispatch_after(stopTime, dispatch_get_main_queue(), ^(void){
                           
                           [self stopRecordingBroll];
                           
                       });
                   });
}

-(void)stopRecordingBroll{
    if (veryFirstTime) {
        if (bShotCounter==0) {
            [self.view ap_makeToast:@"First moment captured!" duration:2 position:APToastPositionCenter];
            toastOnScreen = [self.view ap_makeToast:@"Tap again to record another moment!" duration:99 position:APToastPositionCenter];
            
        }else if(bShotCounter==1){
            [self.view ap_makeToast:@"Second moment captured!" duration:3 position:APToastPositionCenter];
            [self.view ap_makeToast:@"The back camera records for 1 second at a time!" duration:3 position:APToastPositionCenter];
            switchToastOnScreen = [self.view ap_makeToast:@"Now switch your camera!" duration:99 position:APToastPositionCenter];
        }else if(bShotCounter==2){
            
        }
    }
    
    
    
    if (isRecordingSomething) {
        [timer invalidate];
        [movieWriter finishRecording];
        isRecordingSomething = NO;
    }
    [self incrementShotCounter];
    [self didFinishRecording:movieURL];
}

- (IBAction)flashButton:(id)sender {
    if (isFlashOn) {
        [self turnFlashOff];
    }else{
        [self turnFlashOn];
    }
}

-(void)turnFlashOn{
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        
        [UIView transitionWithView:_frontFlash
                          duration:FAST
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _frontFlash.hidden=YES;
                            [self turnViewsWhite];}
                        completion:nil];
        NSError *error = nil;
        if (![videoCamera.inputCamera lockForConfiguration:&error])
            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOn];
        [videoCamera.inputCamera unlockForConfiguration];
    }else{
        [UIView transitionWithView:_frontFlash
                          duration:FAST
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^{ _frontFlash.hidden=NO;
                            
                            [self turnViewsGray];}
                        completion:nil];
        
    }
    isFlashOn=YES;
}
-(void)turnViewsGray{
    _timerLabel.textColor = [UIColor darkGrayColor];
    
    [_flashButton setBackgroundImage:[UIImage imageNamed:@"flashNonStockGray.png"] forState:UIControlStateNormal];
    [_switchButton setBackgroundImage:[UIImage imageNamed:@"rotateCameraStockGray.png"] forState:UIControlStateNormal];
    [_makeButton setBackgroundImage:[UIImage imageNamed:@"clapperGray.png"] forState:UIControlStateNormal];
    [_undoButton setBackgroundImage:[UIImage imageNamed:@"UndoStockGray.png"] forState:UIControlStateNormal];
    [_recordButton setBackgroundImage:[UIImage imageNamed:@"recordGray.png"] forState:UIControlStateNormal];
}
-(void)turnViewsWhite{
    _timerLabel.textColor = [UIColor whiteColor];
    
    [_flashButton setBackgroundImage:[UIImage imageNamed:@"flashNonStock.png"] forState:UIControlStateNormal];
    [_switchButton setBackgroundImage:[UIImage imageNamed:@"rotateCameraStock.png"] forState:UIControlStateNormal];
    [_makeButton setBackgroundImage:[UIImage imageNamed:@"clapper.png"] forState:UIControlStateNormal];
    [_undoButton setBackgroundImage:[UIImage imageNamed:@"UndoStock.png"] forState:UIControlStateNormal];
    [_recordButton setBackgroundImage:[UIImage imageNamed:@"record.png"] forState:UIControlStateNormal];
}



-(void)turnFlashOff{
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        _frontFlash.hidden=YES;
        NSError *error = nil;
        if (![videoCamera.inputCamera lockForConfiguration:&error])
            
            [videoCamera.inputCamera setTorchMode:AVCaptureTorchModeOff];
        [videoCamera.inputCamera unlockForConfiguration];
    }else
    {
        _frontFlash.hidden=YES;
        [self turnViewsWhite];
    }
    isFlashOn=NO;
}

- (IBAction)makeButton:(id)sender {
    [self.view ap_ejectToast:cutToastOnScreen];
    if (firstToastMakeButton) {
        firstToastMakeButton = NO;
        if ([sharedSingleton.bShotListURLs count]!=0) {
            if (movieWriter.assetWriter.status !=AVAssetWriterStatusWriting || movieWriter.assetWriter.status !=AVAssetWriterStatusCompleted) {
                [self make];
            }
        }
        
    }
    
    
}

-(void)make{
    
    //videoCamera=nil;
    //tapGestureRecognizer = nil;
    
}

- (IBAction)undoButton:(id)sender {
    [self.view ap_ejectToast:undoToast];
    
    if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
        [sharedSingleton.bShotListURLs removeLastObject];
        if ([sharedSingleton.bShotListURLs count]==0) {
            [self disableUndoButton];
        }
        undoToast = [self.view ap_makeToast:@"Last moment removed" duration:2 position:APToastPositionCenter];
    }else{
        [sharedSingleton.aShotListURLs removeLastObject];
        if ([sharedSingleton.aShotListURLs count]==0) {
            [self disableUndoButton];
        }
        undoToast = [self.view ap_makeToast:@"Last selfie story removed" duration:2 position:APToastPositionCenter];
    }
    
    if ([sharedSingleton.bShotListURLs count] + [sharedSingleton.aShotListURLs count]==0) {
        [self disableUndoButton];
        [self disableMakeButton];
    }
}

-(void)resetNotificationReceiver:(NSNotification*) notification{
    if ([[notification name] isEqualToString:@"reset"]) {
        aShotCounter=0;
        bShotCounter=0;
    }
}

-(void)viewWillDisappear:(BOOL)animated{
    [videoCamera pauseCameraCapture];
    self.view.userInteractionEnabled = NO;
}

- (void)viewDidUnload {
    [self setRecordButton:nil];
    [self setRecordingIndicator:nil];
    [super viewDidUnload];
}

- (IBAction)recordButton:(id)sender {
    
    
    if (recordingAroll) {
        [self stopRecordingAroll];
    }else{
        if (videoCamera.inputCamera.position == AVCaptureDevicePositionBack) {
            [self recordBroll];
        }else{
            [self startRecordingAroll];
        }
    }
}
@end
