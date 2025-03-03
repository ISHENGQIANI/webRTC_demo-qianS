//
//  CallViewController.m
//  webRTC
//
//  Created by qianS on 2019/11/2.
//  Copyright © 2019年 qianS. All rights reserved.
//

#import "CallViewController.h"

@interface CallViewController() <ProcessCommandEvents, RTCPeerConnectionDelegate, RTCVideoViewDelegate>
{
    
//    NSString* userID;
//    NSString* friendID;
    
    NSString* myState;
    //AFManager* AFNet;
    ProcessCommand* pCMD;
    
    RTCPeerConnectionFactory* factory;
    RTCCameraVideoCapturer* capture;

    RTCPeerConnection* peerConnection;
    
    RTCVideoTrack* videoTrack;
    RTCAudioTrack* audioTrack;
    
    RTCVideoTrack* remoteVideoTrack;
    CGSize remoteVideoSize;
    
    NSMutableArray* ICEServers;
    
}

@property (strong, nonatomic) RTCEAGLVideoView *remoteVideoView;
@property (strong, nonatomic) RTCCameraPreviewView *localVideoView;//如果设置成RTCEAGLVideoView 则需要从videoTrack中获取数据

@property (strong, nonatomic) NSString* userID;
@property (strong, nonatomic) NSString* friendID;

@property (strong, nonatomic) UIButton* leaveBtn;


@property (strong, nonatomic) dispatch_source_t timer;

@end

@implementation CallViewController

static CGFloat const kLocalVideoViewSize = 120;
static CGFloat const kLocalVideoViewPadding = 8;

static NSString *const RTCSTUNServerURL = @"stun:hy03.teclub.cn:3478";
static NSString *const RTCTURNServerURL = @"turn:turn003.teclub.cn:17711";
static int logY = 0;

- (instancetype) initWithId:(ProcessCommand* )pCmd friendID:(NSString* )friend userID:(NSString* )user{
    _friendID = friend;
    _userID = user;
    pCMD = pCmd;
    [self initView];
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    logY = 0;
    
    [self createPeerConnectionFactory];
    
    //创建本地流
    [self captureLocalMedia];
    
    pCMD.delegate = self;
    myState = @"init";
    
}

-(void)initView{
    self.remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:self.view.bounds];
    self.remoteVideoView.delegate = self;//---------------------------or here
    [self.view addSubview:self.remoteVideoView];
    
    self.localVideoView = [[RTCCameraPreviewView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.localVideoView];
    
    CGRect localVideoFrame =
    CGRectMake(0, 0, kLocalVideoViewSize, kLocalVideoViewSize);
    localVideoFrame.origin.x = CGRectGetMaxX(self.view.bounds)
    - localVideoFrame.size.width - kLocalVideoViewPadding;
    localVideoFrame.origin.y = CGRectGetMaxY(self.view.bounds)
    - localVideoFrame.size.height - kLocalVideoViewPadding;
    [self.localVideoView setFrame: localVideoFrame];
    
    self.leaveBtn = [[UIButton alloc] init];
    [self.leaveBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.leaveBtn setTintColor:[UIColor whiteColor]];
    [self.leaveBtn setTitle:@"leave" forState:UIControlStateNormal];
    [self.leaveBtn setBackgroundColor:[UIColor greenColor]];
    [self.leaveBtn setShowsTouchWhenHighlighted:YES];
    [self.leaveBtn.layer setCornerRadius:40];
    [self.leaveBtn.layer setBorderWidth:1];
    [self.leaveBtn setClipsToBounds:FALSE];
    [self.leaveBtn setFrame:CGRectMake(self.view.bounds.size.width/2-40,
                                       self.view.bounds.size.height-140,
                                       80,
                                       80)];
    
    [self.leaveBtn addTarget:self
                      action:@selector(leaveRoom:)
            forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.leaveBtn];
    
}

- (void)layoutSubviews {
    CGRect bounds = self.view.bounds;
    if (remoteVideoSize.width > 0 && remoteVideoSize.height > 0) {
        CGRect remoteVideoFrame =
        AVMakeRectWithAspectRatioInsideRect(remoteVideoSize, bounds);
        CGFloat scale = 1;
        if (remoteVideoFrame.size.width > remoteVideoFrame.size.height) {
            scale = bounds.size.height / remoteVideoFrame.size.height;
        } else {
            scale = bounds.size.width / remoteVideoFrame.size.width;
        }
        remoteVideoFrame.size.height *= scale;
        remoteVideoFrame.size.width *= scale;
        self.remoteVideoView.frame = remoteVideoFrame;
        self.remoteVideoView.center =
        CGPointMake(CGRectGetMidX(bounds), CGRectGetMidY(bounds));
    } else {
        self.remoteVideoView.frame = bounds;
    }
    
}
//TODO:finish it
- (void) leaveRoom:(UIButton*) sender {
    
    [self willMoveToParentViewController:nil];
    [self.view removeFromSuperview];
    [self removeFromParentViewController];
    
    if(peerConnection){
        [peerConnection close];
        peerConnection = nil;
    }
}

#pragma mark - SignalEventNotify
//TODO: finish it
- (void) leaved:(NSString *)room {
    NSLog(@"leaved room(%@) notify!", room);
}

- (void) join :(NSString* )friendId{
    NSLog(@"joined room(%@) notify!", friendId);
    myState = @"joined";
    //这里应该创建PeerConnection
    if (!peerConnection) {
        peerConnection = [self createPeerConnection];
    }
}

- (void) otherjoin:(NSString *)friendID userID:(NSString *)user{
    if (!peerConnection) {
        peerConnection = [self createPeerConnection];
    }
    myState =@"joined_conn";
    //调用call， 进行媒体协商
    [self doStartCall];
}

- (void) full {
    NSLog(@"the friendID(%@) is buzy!", _friendID);
    myState = @"leaved";
    if(peerConnection) {
        [peerConnection close];
        peerConnection = nil;
    }
    
    //弹出提醒添加成功
    MBProgressHUD *hud= [[MBProgressHUD alloc] initWithView:self.view];
    [hud setRemoveFromSuperViewOnHide:YES];
    hud.label.text = @"房间已满";
    UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, 50, 50)];
    [hud setCustomView:view];
    [hud setMode:MBProgressHUDModeCustomView];
    [self.view addSubview:hud];
    [hud showAnimated:YES];
    [hud hideAnimated:YES afterDelay:1.0]; //设置1秒钟后自动消失
    
    if(self.localVideoView) {
        //[self.localVideoView removeFromSuperview];
        //self.localVideoView = nil;
    }
    
    if(self.remoteVideoView) {
        //[self.localVideoView removeFromSuperview];
        //self.remoteVideoView = nil;
    }
    
    if(capture) {
        [capture stopCapture];
        capture = nil;
    }
    
    if(factory) {
        factory = nil;
    }
}

- (void) byeFrom:(NSString *)room User:(NSString *)uid {
    NSLog(@"the user(%@) has leaved from room(%@) notify!", uid, room);
    myState = @"joined_unbind";
    
    [peerConnection close];
    peerConnection = nil;
    
}

- (void) answer:(NSString *)sdp {
    //NSLog(@"have received a answer message %@", sdp);
    NSString *remoteAnswerSdp = sdp;
    RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc]
                                        initWithType:RTCSdpTypeAnswer
                                        sdp: remoteAnswerSdp];
    [peerConnection setRemoteDescription:remoteSdp
                       completionHandler:^(NSError * _Nullable error) {
                           if(!error){
                               NSLog(@"Success to set remote Answer SDP");
                           }else{
                               NSLog(@"Failure to set remote Answer SDP, err=%@", error);
                           }
                       }];
}

- (void) setLocalAnswer: (RTCPeerConnection*)pc withSdp: (RTCSessionDescription*)sdp {
    [pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if(!error){
            NSLog(@"Successed to set local answer!");
        }else {
            NSLog(@"Failed to set local answer, err=%@", error);
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate sendAnswerAFNet:sdp.sdp friendId:self->_friendID];
    });
}

- (void) getAnswer:(RTCPeerConnection*) pc {
    NSLog(@"Success to set remote offer SDP");
    [pc answerForConstraints:[self defaultPeerConnContraints]
           completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
               if(!error){
                   NSLog(@"Success to create local answer sdp!");
                   __weak RTCPeerConnection* weakPeerConn = pc;
                   [self setLocalAnswer:weakPeerConn withSdp:sdp];
                   
               }else{
                   NSLog(@"Failure to create local answer sdp!");
               }
           }];
}

//本地
- (void) offer:(NSString *)sdp {
    //NSLog(@"have received a offer message %@", sdp);
    NSString* remoteOfferSdp = sdp;
    RTCSessionDescription* remoteSdp = [[RTCSessionDescription alloc]
                                        initWithType:RTCSdpTypeOffer
                                        sdp: remoteOfferSdp];
    if(!peerConnection){
        peerConnection = [self createPeerConnection];
    }
    __weak RTCPeerConnection* weakPeerConnection = peerConnection;
    [weakPeerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
        if(!error){
            [self getAnswer: weakPeerConnection];
        }else{
            NSLog(@"Failure to set remote offer SDP, err=%@", error);
        }
    }];
}
//本地
- (void) candidate: (NSDictionary *)dict {
    //NSLog(@"have received a message %@", dict);
    NSString* desc = dict[@"sdp"];
    NSString* sdpMLineIndex = dict[@"label"];
    int index = [sdpMLineIndex intValue];
    NSString* sdpMid = dict[@"id"];
    RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:desc
                                                        sdpMLineIndex:index
                                                               sdpMid:sdpMid];
    [peerConnection addIceCandidate:candidate];
}

#pragma mark RTCPeerConnectionDelegate
/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged{
    NSLog(@"%s",__func__);
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didAddStream:(RTCMediaStream *)stream{
    NSLog(@"%s",__func__);
}

/** Called when a remote peer closes a stream.
 *  This is not called when RTCSdpSemanticsUnifiedPlan is specified.
 */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveStream:(RTCMediaStream *)stream{
    NSLog(@"%s",__func__);
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection {
    NSLog(@"%s",__func__);
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState{
    NSLog(@"%s",__func__);
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState{
    NSLog(@"%s",__func__);
}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate{
    NSLog(@"%s",__func__);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSDictionary* dict = [[NSDictionary alloc] initWithObjects:@[[NSString stringWithFormat:@"%d", candidate.sdpMLineIndex],
                                                                     candidate.sdpMid,
                                                                     candidate.sdp]
                                                           forKeys:@[@"label", @"id", @"sdp"]];
        [self.delegate sendCandidateAFNet:dict friendId:self->_friendID];
        //[self->AFNet sendCandidate:dict friendId:self->friendID];
    });
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates {
    NSLog(@"%s",__func__);
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel {
    NSLog(@"%s",__func__);
}

- (void)peerConnection:(RTCPeerConnection *)peerConnection
        didAddReceiver:(RTCRtpReceiver *)rtpReceiver
               streams:(NSArray<RTCMediaStream *> *)mediaStreams{
    NSLog(@"%s",__func__);
    
    RTCMediaStreamTrack* track = rtpReceiver.track;
    if([track.kind isEqualToString:kRTCMediaStreamTrackKindVideo]){
        
        if(!self.remoteVideoView){
            NSLog(@"error:remoteVideoView have not been created!");
            return;
        }
        
        remoteVideoTrack = (RTCVideoTrack*)track;
        
        //dispatch_async(dispatch_get_main_queue(), ^{
        
        [remoteVideoTrack addRenderer: self.remoteVideoView];
        //});
        //[remoteVideoTrack setIsEnabled:true];
        
        //[self.view addSubview:self.remoteVideoView];
    }
    
}

#pragma mark webrtc
- (RTCMediaConstraints*) defaultPeerConnContraints {
    RTCMediaConstraints* mediaConstraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{
                                                                kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,
                                                                kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue
                                                                }
                                          optionalConstraints:@{ @"DtlsSrtpKeyAgreement" : @"true" }];//原设置为true
    return mediaConstraints;
}


- (void) captureLocalMedia {
    NSDictionary* mandatoryConstraints = @{};
    NSDictionary* optionalConstraints = @{};
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                          optionalConstraints:optionalConstraints];
    
    RTCAudioSource* audioSource = [factory audioSourceWithConstraints: constraints];
    audioTrack = [factory audioTrackWithSource:audioSource trackId:@"ADRAMSa0"];
    
    NSArray<AVCaptureDevice* >* captureDevices = [RTCCameraVideoCapturer captureDevices];//移动端支持的设备列表
    AVCaptureDevicePosition position = AVCaptureDevicePositionFront;//前置摄像头
    AVCaptureDevice* device;
    if (captureDevices.count != 0){
        device = captureDevices[0];
        for (AVCaptureDevice* obj in captureDevices) {
            if (obj.position == position) {
                device = obj;
                break;
            }
        }
    }
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        //弹出提醒添加成功
        MBProgressHUD *hud= [[MBProgressHUD alloc] initWithView:self.view];
        [hud setRemoveFromSuperViewOnHide:YES];
        hud.label.text = @"没有权限访问相机";
        UIView* view = [[UIView alloc] initWithFrame:CGRectMake(0,0, 50, 50)];
        [hud setCustomView:view];
        [hud setMode:MBProgressHUDModeCustomView];
        [self.view addSubview:hud];
        [hud showAnimated:YES];
        [hud hideAnimated:YES afterDelay:1.0]; //设置1秒钟后自动消失
        return;
    }
    
    if (device)
    {
        RTCVideoSource* videoSource = [factory videoSource];
        //相当于将videoSource设置为capture的代理
        capture = [[RTCCameraVideoCapturer alloc] initWithDelegate:videoSource];
        AVCaptureDeviceFormat* format = [[RTCCameraVideoCapturer supportedFormatsForDevice:device] lastObject];
        CGFloat fps = [[format videoSupportedFrameRateRanges] firstObject].maxFrameRate;
        videoTrack = [factory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
        self.localVideoView.captureSession = capture.captureSession;//展示的关键************************
        [capture startCaptureWithDevice:device
                                 format:format
                                    fps:fps];
        
    }
    
}
//初始化STUN Server （ICE Server）
- (RTCIceServer *)defaultSTUNServer {
    return [[RTCIceServer alloc] initWithURLStrings:@[RTCTURNServerURL, RTCSTUNServerURL] username:@"user00" credential:@"abcD1234" tlsCertPolicy:RTCTlsCertPolicyInsecureNoCheck];
}

- (void) createPeerConnectionFactory {
    //设置SSL传输
    [RTCPeerConnectionFactory initialize];
    //如果点对点工厂为空
    if (!factory)
    {
        RTCDefaultVideoDecoderFactory* decoderFactory = [[RTCDefaultVideoDecoderFactory alloc] init];
        RTCDefaultVideoEncoderFactory* encoderFactory = [[RTCDefaultVideoEncoderFactory alloc] init];
        NSArray* codecs = [encoderFactory supportedCodecs];
        [encoderFactory setPreferredCodec:codecs[2]];//vp8编码器
        
        factory = [[RTCPeerConnectionFactory alloc] initWithEncoderFactory: encoderFactory
                                                            decoderFactory: decoderFactory];
    }
}

- (RTCPeerConnection *)createPeerConnection {
    if (!ICEServers) {
        ICEServers = [NSMutableArray array];
        [ICEServers addObject:[self defaultSTUNServer]];
    }
    //用工厂来创建连接
    RTCConfiguration* configuration = [[RTCConfiguration alloc] init];
    [configuration setIceServers:ICEServers];
    
    RTCPeerConnection* conn = [RTCPeerConnection alloc];
    conn = [self->factory //bug should Fixed返回值总是为nil
            peerConnectionWithConfiguration:configuration//configuration//最主要就是ICEServer
            constraints:[self defaultPeerConnContraints]//限制，
            delegate:self];
    NSArray<NSString*>* mediaStreamLabels = @[@"ARDAMS"];
    //如果没有将Track添加到PeerConnection中，那么在进行媒体协商的时候是不会接收数据的
    [conn addTrack:videoTrack streamIds:mediaStreamLabels];//添加视频信息
    [conn addTrack:audioTrack streamIds:mediaStreamLabels];//添加音频信息
    return conn;
}

- (void)setLocalOffer:(RTCPeerConnection*)pc withSdp:(RTCSessionDescription*) sdp{
    
    [pc setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
        if (!error) {
            NSLog(@"Successed to set local offer sdp!");
        }else{
            NSLog(@"Failed to set local offer sdp, err=%@", error);
        }
    }];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate sendOfferAFNet:sdp.sdp friendId:self->_friendID];
    });
}

- (void) doStartCall {
    NSLog(@"Start Call, Wait ...");
    //[self addLogToScreen: @"Start Call, Wait ..."];
    if (!peerConnection) {
        peerConnection = [self createPeerConnection];
    }
    
    [peerConnection offerForConstraints:[self defaultPeerConnContraints]
                      completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
                          if(error){
                              NSLog(@"Failed to create offer SDP, err=%@", error);
                          } else {
                              __weak RTCPeerConnection* weakPeerConnction = self->peerConnection;
                              [self setLocalOffer: weakPeerConnction withSdp: sdp];
                          }
                      }];
}

#pragma mark - RTCEAGLVideoViewDelegate
- (void)videoView:(RTCEAGLVideoView*)videoView didChangeVideoSize:(CGSize)size {
    if (videoView == self.remoteVideoView) {
        remoteVideoSize = size;
    }
    [self layoutSubviews];
}

@end
