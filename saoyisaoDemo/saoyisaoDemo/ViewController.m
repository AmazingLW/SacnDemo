//
//  ViewController.m
//  saoyisaoDemo
//
//  Created by guoqingyang on 16/3/14.
//  Copyright © 2016年 guoqingyang. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

//屏幕高度
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
//屏幕高度
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
@interface ViewController ()<AVCaptureMetadataOutputObjectsDelegate>//用于处理采集信息的代理
{
    int num;
    BOOL upOrdown;
    NSTimer *timer;
}
@property (strong, nonatomic) AVCaptureSession *session;//输入输出的中间桥梁
//UI
@property (strong, nonatomic) UIImageView *scopeImageView;
@property (nonatomic, retain) UIImageView *lineImageView;
//播放器
@property (strong, nonatomic) AVAudioPlayer *beepPlayer;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self initAVAudioPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self setUpQRCodeUI];
    [self beginScanning];
}

- (void)beginScanning{
    //获取摄像设备
    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //创建输入流
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    //创建输出流
    AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc]init];
    //设置代理 在主线程里刷新
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //设置有效扫描区域
    output.rectOfInterest=CGRectMake(0,0,1, 1);
    
    //初始化链接对象
    _session = [[AVCaptureSession alloc]init];
    //高质量采集率
    [_session setSessionPreset:AVCaptureSessionPresetHigh];
    
    [_session addInput:input];
    [_session addOutput:output];
    //设置扫描支持的编码格式(如下设置条形码和二维码兼容)
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,AVMetadataObjectTypeEAN8Code,AVMetadataObjectTypeCode128Code];
    
    AVCaptureVideoPreviewLayer *layer = [AVCaptureVideoPreviewLayer layerWithSession:_session];
    layer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    layer.frame = CGRectMake(0, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height, ScreenWidth, ScreenHeight - (self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height));
    [self.view.layer insertSublayer:layer atIndex:0];
    //开始捕获
    [_session startRunning];
    timer = [NSTimer scheduledTimerWithTimeInterval:0.02 target:self selector:@selector(upOrDownAnimation) userInfo:nil repeats:YES];
}

-(void)upOrDownAnimation{
    if (upOrdown == NO) {
        num ++;
        _lineImageView.frame = CGRectMake(60, _scopeImageView.frame.origin.y+10+2*num, ScreenWidth-120, 2);
        int scopeHight = ScreenWidth - 120 - 20;
        if (2*num >= scopeHight) {
            upOrdown = YES;
        }
    }else {
        num --;
        _lineImageView.frame = CGRectMake(60, _scopeImageView.frame.origin.y+10+2*num, ScreenWidth-120, 2);
        if (num <= 0) {
            upOrdown = NO;
        }
    }
}

- (void)setUpQRCodeUI{
    _scopeImageView = [[UIImageView alloc]init];
    _scopeImageView.frame = CGRectMake(60, self.navigationController.navigationBar.frame.origin.y + self.navigationController.navigationBar.frame.size.height + (155 - 64) + 21 +5, ScreenWidth - 60*2, ScreenWidth - 60*2);
    [_scopeImageView setImage:[UIImage imageNamed:@"扫描框"]];
    [self.view addSubview:_scopeImageView];
    _lineImageView = [[UIImageView alloc] initWithFrame:CGRectMake(60, _scopeImageView.frame.origin.y + 10, ScreenWidth-120, 2)];
    _lineImageView.image = [UIImage imageNamed:@"line"];
    [self.view addSubview:_lineImageView];
}



- (void)initAVAudioPlayer{
    NSString * wavPath = [[NSBundle mainBundle] pathForResource:@"beep" ofType:@"wav"];
    NSData* data = [[NSData alloc] initWithContentsOfFile:wavPath];
    _beepPlayer = [[AVAudioPlayer alloc] initWithData:data error:nil];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects.count > 0) {
        [timer invalidate];
        [_session stopRunning];
        [_beepPlayer play];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        //输出扫描字符串
        NSLog(@"____________%@_____________",metadataObject.stringValue);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"扫描结果" message:metadataObject.stringValue delegate:self cancelButtonTitle:@"退出" otherButtonTitles:@"再次扫描", nil];
        [alert show];
    }
}


@end
