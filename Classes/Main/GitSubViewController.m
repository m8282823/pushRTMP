//
//  GitSubViewController.m
//  GitTest
//
//  Created by 云尚互动 on 15/12/1.
//  Copyright © 2015年 云尚互动. All rights reserved.
//

#import "GitSubViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "MainMacro.h"
#import "GitPlayerView.h"

typedef void(^PropertyChangeBlock)(AVCaptureDevice *captureDevice);

static NSString *const videoName = @"videoName";
static NSString *const cmSampleBuffer = @"cmSampleBuffer";

@interface GitSubViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic,strong)NSMutableData *outputData;

@property (nonatomic,strong)AVPlayer *player;
@property (nonatomic,strong)AVPlayerItem *item;
@property (nonatomic,strong)UISlider *progress;

@end

@implementation GitSubViewController
{
    UIButton *_button;
    UIView *_preview;
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_videoDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureVideoDataOutput *_videoOutput;
    
    
    BOOL _isRunning;     //录制状态
    BOOL _enableRotation; // 是否允许旋转
    CMTime _playTime;
    NSInteger _testNumber;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @" 李响的直播间";
        self.outputData = [NSMutableData data];
   
    }
    return self;
}

- (void)testTime
{
    NSLog(@"%li",_testNumber++);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    //初始化摄像组件
    [self setupCaptureSession];
    
    NSTimer *time = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(testTime) userInfo:nil repeats:YES];
    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
    [runLoop addTimer:time forMode:NSRunLoopCommonModes];
    [time fire];
    
    [self setPreview];
    
    [self setPlayUI];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                            selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    
    [self setupCaptureOrientation];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self startRunning];
    [self forbidVisit];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc{
  
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - AV capture methods

- (void)setupCaptureSession{
    if (_captureSession) {
        return;
    }
    /*
    AVCaptureSession *_captureSession;
    AVCaptureDevice *_videoDevice;
    AVCaptureDeviceInput *_videoInput;
    AVCaptureVideoPreviewLayer *_previewLayer;
    AVCaptureMetadataOutput *_metadataOutput;*/

    _videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!_videoDevice) {
        NSLog(@"没有找到摄像头");
        return;
    }
    
    _captureSession = [[AVCaptureSession alloc]init];
    if ([_captureSession canSetSessionPreset:AVCaptureSessionPreset352x288]) {
        [_captureSession setSessionPreset:AVCaptureSessionPresetMedium];
    }
    
    _videoInput = [[AVCaptureDeviceInput alloc]initWithDevice:_videoDevice error:nil];
    
    if ([_captureSession canAddInput:_videoInput]) {
        [_captureSession addInput:_videoInput];
        
    }
    
    
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:_captureSession];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    
    //capture and process the metadata
    _videoOutput = [[AVCaptureVideoDataOutput alloc]init];
    [_videoOutput setSampleBufferDelegate:self queue:dispatch_queue_create("outputQueue", nil)];
    _videoOutput.videoSettings = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
//    Use AVCaptureConnection's videoMinFrameDuration property instead.");
//    [_videoOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
//    _videoDevice.activeVideoMinFrameDuration = CMTimeMake(1, 15);//  帧数/帧率==秒
    AVCaptureConnection *captureConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    //设置预览图层和视频方向保持一致
    captureConnection.videoOrientation = [_previewLayer connection].videoOrientation;
    if ([captureConnection isVideoStabilizationSupported]) {
        captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;//防抖
    }
    
    if ([_captureSession canAddOutput:_videoOutput]) {
        [_captureSession addOutput:_videoOutput];
    }
    
    _enableRotation = NO;
}
#pragma mark -visitMethod
- (void)forbidVisit{
    AVAuthorizationStatus authorizationStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authorizationStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"摄像头访问受限" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self dismissViewControllerAnimated:YES completion:nil];
        }];
        [alertController addAction:action];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)setupCaptureOrientation
{
    if ([_previewLayer.connection isVideoOrientationSupported]) {
        AVCaptureVideoOrientation orientation;
        
        switch ([[UIApplication sharedApplication] statusBarOrientation]) {
            case UIInterfaceOrientationLandscapeLeft:
                orientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
                
            case UIInterfaceOrientationLandscapeRight:
                orientation = AVCaptureVideoOrientationLandscapeRight;
                break;
                
            default:
                orientation = AVCaptureVideoOrientationLandscapeLeft;
                break;
        }
        orientation = AVCaptureVideoOrientationPortrait;
        [_previewLayer.connection setVideoOrientation:orientation];
    }
}

- (void)startRunning
{
    if (_isRunning) return;
    [_captureSession startRunning];
    _isRunning = YES;
    
//    AVCaptureConnection *captureConnection = [_videoOutput connectionWithMediaType:AVMediaTypeVideo];
    
}

#pragma mark -NotificationMethod

- (void)orientationChanged:(NSNotification *)note{
    [self setPreview];
}

- (void)stopRunning
{
    if (!_isRunning) return;
    [_captureSession stopRunning];
    _isRunning = NO;
}

- (void)applicationWillEnterForeground:(NSNotification *)note{
    [self startRunning];
}
- (void)applicationDidEnterBackground:(NSNotification *)note{
    [self stopRunning];
}

- (void)setPreview
{
    _preview = nil;
    _button = nil;
    _preview = [[UIView alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width / 2.0, self.view.frame.size.height / 2.0f)];
    [self.view addSubview:_preview];
    
    _previewLayer.frame = _preview.bounds;
    [_preview.layer addSublayer:_previewLayer];
//    [self.view.layer addSublayer:_previewLayer];
    
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame = CGRectMake(100, 200, 50, 60);
    [_button setTitle:@"切换摄像头" forState:UIControlStateNormal];
    _button.backgroundColor = [UIColor yellowColor];
    [_button addTarget:self action:@selector(changeVedio) forControlEvents:UIControlEventTouchUpInside];
    [_preview addSubview:_button];
}

- (void)changeVedio{
    AVCaptureDevice *currentDevice = [_videoInput device];
    AVCaptureDevicePosition currentPosition = [currentDevice position];

//    [self removeNotificationFromCaptureDevice:currentDevice];    //捕获区域改变
    
    AVCaptureDevice *toChangeDevice;
    AVCaptureDevicePosition toChangePositon = AVCaptureDevicePositionFront;
    if (currentPosition == AVCaptureDevicePositionUnspecified || currentPosition == AVCaptureDevicePositionFront) {
        toChangePositon = AVCaptureDevicePositionBack;
    }
    
    toChangeDevice = [self getCameraDeviceWithPosition:toChangePositon];
//    [self addNotificationToCaptureDevice:toChangeDevice];    //捕获区域改变
    
    AVCaptureDeviceInput *toChangeDeviceInput = [[AVCaptureDeviceInput alloc]initWithDevice:toChangeDevice error:nil];
    
    [_captureSession beginConfiguration];
    [_captureSession removeInput:_videoInput];
    if ([_captureSession canAddInput:toChangeDeviceInput]) {
        [_captureSession addInput:toChangeDeviceInput];
        _videoInput = toChangeDeviceInput;
    }
    [_captureSession commitConfiguration];
    
    [self setPreview];
}

- (void)addNotificationToCaptureDevice:(AVCaptureDevice *)device{
    [self changeDeviceProperty:^(AVCaptureDevice *captureDevice) {
        captureDevice.subjectAreaChangeMonitoringEnabled = YES;
    }];
        //捕获区域改变
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(areaChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:device];
}

- (void)removeNotificationFromCaptureDevice:(AVCaptureDevice *)captureDevice{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:captureDevice];
}

- (void)removeNotification{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self];
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{

}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    
//    NSDictionary *dictionary = @{cmSampleBuffer:[NSValue value:&sampleBuffer withObjCType:@encode(CMSampleBufferRef)]};
//    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(readDataToFile:) userInfo:dictionary repeats:YES];
//    NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//    [runLoop addTimer:timer forMode:NSRunLoopCommonModes];
    
    NSData *currentData = [self imageToBuffer: sampleBuffer];
    [self.outputData appendData:currentData];
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self videoPath]]) {
        [self.outputData writeToFile:[self videoPath] atomically:YES];
    }else{
        [[NSFileManager defaultManager] createFileAtPath:[self videoPath] contents:self.outputData attributes:nil];
    }
    
    NSDictionary *dic = [[NSFileManager defaultManager]attributesOfItemAtPath:[self videoPath] error:nil];
    NSLog(@"%f",(unsigned long long)[dic fileSize] / 1024.0 / 1024.0);
}

//- (void)readDataToFile:(NSTimer *)timer{
//    CMSampleBufferRef sampleBufferRef;
//    [[timer.userInfo valueForKey:cmSampleBuffer] getValue:&sampleBufferRef];
//    NSData *currentData = [self imageToBuffer: sampleBufferRef];
//    [self.outputData setData:currentData];
//    if ([[NSFileManager defaultManager] fileExistsAtPath:[self videoPath]]) {
//        [self.outputData writeToFile:[self videoPath] atomically:YES];
//    }else{
//        [[NSFileManager defaultManager] createFileAtPath:[self videoPath] contents:self.outputData attributes:nil];
//    }
//    
//    NSDictionary *dic = [[NSFileManager defaultManager]attributesOfItemAtPath:[self videoPath] error:nil];
//    NSLog(@"%f",(unsigned long long)[dic fileSize] / 1024.0 / 1024.0);
//}

- (NSData *)imageToBuffer:(CMSampleBufferRef)sampleBufferRef
{
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBufferRef);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    return data;
}

- (void)areaChange:(NSNotification *)note{
    NSLog(@"捕获区域改变...");
}

-(void)sessionRuntimeError:(NSNotification *)notification{
    NSLog(@"会话发生错误.");
}

#pragma mark - 私有方法 

- (AVCaptureDevice *)getCameraDeviceWithPosition:(AVCaptureDevicePosition)position{
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if ([camera position] == position) {
            return camera;
        }
    }
    return nil;
}

- (void)changeDeviceProperty:(PropertyChangeBlock)changeBlock{
    AVCaptureDevice *captureDevice = [_videoInput device];
    NSError *error;
    if ([captureDevice lockForConfiguration:&error]) {
        changeBlock(captureDevice);
    [captureDevice unlockForConfiguration];
    }else{
        NSLog(@"设置设备属性过程中发生错误--->%@",error.localizedDescription);
    }
}

#pragma mark -播放UI
- (void)setPlayUI{
    GitPlayerView *playerView = [[GitPlayerView alloc]initWithFrame:CGRectMake(kScreenWidth / 2.0, kScreenHeight / 2.0, kScreenWidth / 2.0, kScreenHeight / 2.0)];
//    playerView.backgroundColor = [UIColor redColor];
//    self.item = [[AVPlayerItem alloc]initWithAsset:[[AVAsset alloc]init]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:[self videoPath]]) {
        [fileManager createFileAtPath:[self videoPath] contents:nil attributes:nil];
    }
    
//    NSURL *videoUrl = [NSURL fileURLWithPath:[self videoPath]];
//    AVAsset *asset = [AVAsset
    
//    self.item = [[AVPlayerItem alloc]initWithAsset:<#(nonnull AVAsset *)#>:videoUrl];
    self.item = [[AVPlayerItem alloc]initWithURL:[NSURL URLWithString:@"http://192.168.1.234/test.mp4"]];
   
    self.player = [[AVPlayer alloc]initWithPlayerItem:self.item];
    playerView.player = self.player;
    [self.view addSubview:playerView];
    [self.player play];
}




#pragma mark -filePath

- (NSString *)videoPath{
    NSString *homePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *filePath = [homePath stringByAppendingPathComponent:videoName];
    return filePath;
}


@end
