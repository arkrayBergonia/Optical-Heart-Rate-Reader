//
//  HeartRateViewController.m
//  Heart Rate Detector
//
//  Created by Jay Bergonia on 02/10/2019.
//  Copyright © 2019 Jay Bergonia. All rights reserved.
//

#import "HeartRateViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "PulseDetector.h"
#import "Fiter.h"
@interface HeartRateViewController ()<AVCaptureVideoDataOutputSampleBufferDelegate>{
    BOOL showText;
    BOOL blinkStatus;
    BOOL startDetecting;
    BOOL pausedDetecting;
    BOOL cameraPressed;
    int totalSeconds;
    NSTimer *timer;
}
@property(nonatomic, strong) AVCaptureSession *session;
@property(nonatomic, strong) AVCaptureDevice *camera;
@property(nonatomic, strong) PulseDetector *pulseDetector;
@property(nonatomic, strong) Fiter *fiter;
@property(nonatomic, assign) CURRENT_STATE currentState;
@property(nonatomic, assign) int validFrameCounter;

@end

@implementation HeartRateViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.fiter = [[Fiter alloc]init];
    
    self.pulseDetector = [[PulseDetector alloc]init];
    
    self.startMeasureBtn.layer.cornerRadius = 10;
    self.startMeasureBtn.clipsToBounds = YES;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // イントロのVCを表示 || show intro VC
    [self segueToVC:@"introVC"];
    
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}

- (void)segueToVC:(NSString *)controllerID {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    UIViewController *ivc = [storyboard instantiateViewControllerWithIdentifier:controllerID];
    [self presentViewController:ivc animated:YES completion:nil];
}

- (IBAction)startBtnPressed:(id)sender {
    
    if (!startDetecting) {
        [self startCountDown];
        
        if (!pausedDetecting) {
            // 心拍数のキャプチャを開始 || start HeartRate capture
            [self startCameraCapture];
        } else {
            [self resume];
        }
    } else {
        [self pause]; // 心拍数のキャプチャを一時停止 || pause HeartRate capture
        pausedDetecting = YES;
        self.heartMainTitleLbl.text = NSLocalizedString(@"heartRateMeasureTitle", nil);
        self.heartSubTitleLbl.text = NSLocalizedString(@"pressToStartSubTitle", nil);
        self.bpmValueLabel.text = @"00";
    }
    
    [self.startMeasureBtn setTitle: startDetecting ? NSLocalizedString(@"startYourMeasureText", nil) : NSLocalizedString(@"cancelYourMeasureText", nil) forState:UIControlStateNormal];
    startDetecting = !startDetecting ? YES : NO;
}


- (void) startCountDown {
    self.countDownLabel.hidden = NO;
    totalSeconds = DEFAULT_TIMER;
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
      target:self
    selector:@selector(timer)
    userInfo:nil
     repeats:YES];
}

- (void)timer {
    // this method updates the labels depending on the status of heart rate capture
    // この方法は、心拍数のキャプチャの状態に応じてラベルを更新します
    if (cameraPressed) {
        totalSeconds--;
        _countDownLabel.text = [NSString stringWithFormat:NSLocalizedString(@"countDownText", nil), totalSeconds];
    }
    
    if ( totalSeconds == 0 ) {
        [timer invalidate];
        [self.heartImage setImage:[UIImage imageNamed:@"digital_heart"]];
        self.countDownLabel.hidden = YES;
        
        NSTimer *quick = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(startBtnPressed:) userInfo:nil repeats:NO];
        
        if (![self.bpmValueLabel.text isEqual: @"00"]) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"heartRateResultText", nil)
                                       message:[NSString stringWithFormat:@"%@ BPM", self.bpmValueLabel.text]
                                       preferredStyle:UIAlertControllerStyleAlert];

            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                           handler:^(UIAlertAction * action) {}];

            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }
    
    if(blinkStatus == NO){
        [self.heartImage setImage:[UIImage imageNamed:@"red_heart"]];
        blinkStatus = YES;
    }else {
        [self.heartImage setImage:[UIImage imageNamed:@"digital_heart"]];
        blinkStatus = NO;
    }
}

// //フレームのキャプチャを開始 || start capturing frame
- (void) startCameraCapture {
    
    // AVCaptureを作成します。 || Create AVCapture
    self.session = [[AVCaptureSession alloc]init];
    
    // デフォルトのカメラデバイスを取得 || get the default camera device
    self.camera = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    // AVCaptureInputのccameraデバイスを作成します。 || Create a AVCaptureInput ccamera device
    NSError *error=nil;
    AVCaptureInput* cameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:self.camera error:&error];
    if (cameraInput == nil) {
        NSLog(@"Error to create camera capture:%@",error);
    }
    
    // 出力を設定します || set the output
    AVCaptureVideoDataOutput* videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    
    // 撮影したキューの実行を作成します || create a queue run captured
    dispatch_queue_t captureQueue=dispatch_queue_create("captureQueue", NULL);
    
    // キャプチャするために、独自の委員会を設定 || set their own commission to capture
    [videoOutput setSampleBufferDelegate:self queue:captureQueue];
    
    // ピクセルフォーマットを設定します || Configure pixel format
    videoOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    
    // 10 fpsに最小許容フレームレート || minimum acceptable frame rate to 10 fps
    videoOutput.minFrameDuration=CMTimeMake(1, 10);
    
    // フレームの大きさ - 私たちは可能な最小のフレームサイズを使用します || size of the frame - we'll use the smallest frame size available
    [self.session setSessionPreset:AVCaptureSessionPresetLow];
    
    // 入力と出力を追加 || add an input and output
    [self.session addInput:cameraInput];
    [self.session addOutput:videoOutput];
    
    // 起動 || start up
    [self.session startRunning];
    
    // カメラのステータス：我々は今、カメラからサンプリングしています || Camera status:  we're now sampling from the camera
    self.currentState=STATE_SAMPLING;
    
    // オープントーチモード - いいえ、それはパルスを検出することはできませんが、それは捕獲率を向上 || Open torch mode - no it can not detect a pulse, but it enhances capture rate
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOn;
        [self.camera unlockForConfiguration];
    }
    
    // 寝てからアプリを停止 || stop the app from sleeping
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    // タイマーは、一回ごとに0.1秒を実行しました || Timer executed once every 0.1 seconds
    [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(update) userInfo:nil repeats:YES];

}

-(void) stopCameraCapture {
    [self.session stopRunning];
    self.session=nil;
}

#pragma mark Pause and Resume of pulse detection
-(void) pause {
    if(self.currentState==STATE_PAUSED) return;
    
    //トーチをオフにします || Turn off the torch
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOff;
        [self.camera unlockForConfiguration];
    }
    self.currentState=STATE_PAUSED;
    
    // 電話機がアイドル状態の場合、アプリケーションがスリープ状態に行きましょう || let the application go to sleep if the phone is idle
    [UIApplication sharedApplication].idleTimerDisabled = NO;
}

-(void) resume {
    if(self.currentState!=STATE_PAUSED) return;
    
    // トーチをオンにします || turn on the torch
    if([self.camera isTorchModeSupported:AVCaptureTorchModeOn]) {
        [self.camera lockForConfiguration:nil];
        self.camera.torchMode=AVCaptureTorchModeOn;
        [self.camera unlockForConfiguration];
    }
    self.currentState=STATE_SAMPLING;
    
    // 寝てからアプリを停止 || stop the app from sleeping
    [UIApplication sharedApplication].idleTimerDisabled = YES;
}

// find online algorithm
// r,g,b values are from 0 to 1 // h = [0,360], s = [0,1], v = [0,1]
//    if s == 0, then h = -1 (undefined)
void RGBtoHSV( float r, float g, float b, float *h, float *s, float *v ) {
    float min, max, delta;
    min = MIN( r, MIN(g, b ));
    max = MAX( r, MAX(g, b ));
    *v = max;
    delta = max - min;
    if( max != 0 )
        *s = delta / max;
    else {
        // r = g = b = 0
        *s = 0;
        *h = -1;
        return;
    }
    if( r == max )
        *h = ( g - b ) / delta;
    else if( g == max )
        *h=2+(b-r)/delta;
    else
        *h=4+(r-g)/delta;
    *h *= 60;
    if( *h < 0 )
        *h += 360;
}

// ビデオフレームを処理します || processing video frames
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    
    // 裁判官が停止すると、何も処理を行いません。 || judge to stop and do not do any processing
    if(self.currentState==STATE_PAUSED) {
        
        // 私たちのフレームカウンタをリセット || reset our frame counter
        self.validFrameCounter = 0;
        return;
    }
    
    
    // 血液中の分析変動は値を取得します ||Analyzing fluctuations in blood // Get Value
    if (self.validFrameCounter == 0) {
        
        dispatch_async(dispatch_get_main_queue(), ^{
            // callback or notify the main thread is refreshed,
            self.heartMainTitleLbl.text=NSLocalizedString(@"placeFingerText", nil);
        });

    } else {
        // get the data (may be used to display a progress bar or electrocardiogram) ********
        NSLog(@"int:%d",self.validFrameCounter);
        //*********
        if (!showText) {
            //notify the main thread refresh
            dispatch_async(dispatch_get_main_queue(), ^{
                // callback or notify the main thread is refreshed,
                self.heartMainTitleLbl.text = NSLocalizedString(@"detectingPulseText", nil);
            });
        }
    }
    
    // 画像バッファ || image buffer
    CVImageBufferRef cvimgRef = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    // ロック画像バッファ|| Lock image buffer
    CVPixelBufferLockBaseAddress(cvimgRef,0);
    
    // データへのアクセス || Access to data
    size_t width=CVPixelBufferGetWidth(cvimgRef);
    size_t height=CVPixelBufferGetHeight(cvimgRef);
    
    // 画像バイトを取得します || Acquiring an image bytes
    uint8_t *buf=(uint8_t *) CVPixelBufferGetBaseAddress(cvimgRef);
    size_t bprow=CVPixelBufferGetBytesPerRow(cvimgRef);
    
    // フレームの平均RGB値を引き出し || and pull out the average rgb value of the frame
    float r=0,g=0,b=0;
    for(int y=0; y<height; y++) {
        for(int x=0; x<width*4; x+=4) {
            b+=buf[x];
            g+=buf[x+1];
            r+=buf[x+2];
        }
        buf+=bprow;
    }
    r/=255*(float) (width*height);
    g/=255*(float) (width*height);
    b/=255*(float) (width*height);
    
    // RGB、HSV colourspaceへ変換します || to convert from rgb hsv colourspace
    float h,s,v;
    
    RGBtoHSV(r, g, b, &h, &s, &v);
    
    // //指がカメラ内に配置されているかどうかを確認するためのチェックを行います || do a check to see if a finger is placed in the camera
    if(s>0.5 && v>0.5) {
        
        // フレームの有効数を増やします || increase the effective number of frames
        self.validFrameCounter++;
        
        // //階調値フィルタ、フィルタは、高周波ノイズと、任意のDC成分を除去するための単純なバンドパスフィルタであります || tone value filter, the filter is a simple band-pass filter to eliminate high frequency noise and any DC component
        float filtered=[self.fiter processValue:h];
        
        // 私たちは、フィルタが安定するのに十分なフレームを収集してきましたか？ || have we collected enough frames for the filter to settle?
        if(self.validFrameCounter > MIN_FRAMES_FOR_FILTER_TO_SETTLE) {
            
            // パルス検出器に新しい値を追加します。 || Add a new value into a pulse detector
            [self.pulseDetector addNewValue:filtered atTime:CACurrentMediaTime()];
        }
    } else {
        self.validFrameCounter = 0;
        
        // クリアパルス検出器 - 私たちは一度だけこれを実行する必要があります || clear pulse detector - we only need to do this once
        [self.pulseDetector reset];
    }
}

-(void) update {
    
    NSInteger distance =  MIN(100, (100 * self.validFrameCounter)/MIN_FRAMES_FOR_FILTER_TO_SETTLE);
    
    if (distance == 100) showText = NO;
    
    cameraPressed = (distance == 100) ? YES : NO;
    
    self.heartSubTitleLbl.text = (self.currentState!=STATE_PAUSED) ? [NSString stringWithFormat:NSLocalizedString(@"setFingerOnCameraText", nil),distance] : NSLocalizedString(@"pressToStartSubTitle", nil);
    
    // if we're paused then do nothing
    if(self.currentState==STATE_PAUSED) return;
    
    // パルス検出器からのパルスレートの平均期間を取得 || get the average period of the pulse rate from the pulse detector
    float avePeriod=[self.pulseDetector getAverage];
    
    
    // value obtained (after processing)
//    NSLog(@"avePeriod:%f",avePeriod);
    
    if(avePeriod==INVALID_PULSE_PERIOD) {
        
        // no value available temporarily to do post-processing may be used
        // 後処理を行うことが一時的に利用可能な値を使用することはできません
        
    } else {
        
        // ショーBPM値 || Show BPM Value
        showText = YES;
        float pulse=60.0/avePeriod;
   
        dispatch_async(dispatch_get_main_queue(), ^{
            self.bpmValueLabel.text=[NSString stringWithFormat:@"%0.0f", pulse];
        });
        
    }
}


@end
