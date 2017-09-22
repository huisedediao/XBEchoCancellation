//
//  XBEchoCancellation.m
//  iOSEchoCancellation
//
//  Created by xxb on 2017/8/25.
//  Copyright © 2017年 xxb. All rights reserved.
//

#import "XBEchoCancellation.h"

typedef struct MyAUGraphStruct{
    AUGraph graph;
    AudioUnit remoteIOUnit;
} MyAUGraphStruct;



@interface XBEchoCancellation ()
{
    MyAUGraphStruct myStruct;
}
@property (nonatomic,copy) XBEchoCancellationBlock bufferBlock;
@property (nonatomic,assign) BOOL isCloseServer; //没有开启回音消除服务
@end

@implementation XBEchoCancellation

@synthesize streamFormat;

+ (instancetype)shared
{
    return [self new];
}
+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static XBEchoCancellation *cancel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cancel = [super allocWithZone:zone];
    });
    return cancel;
}
- (instancetype)init
{
    if (self = [super init])
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            self.status = XBEchoCancellationStatus_close;
            self.isCloseServer = YES;
        });
    }
    return self;
}
- (void)startWithBlock:(XBEchoCancellationBlock)bl_buffer
{
    self.bufferBlock = bl_buffer;
    
    [self stopGraph:myStruct.graph];
    
    [self setupSession];
    
    [self createAUGraph:&myStruct];
    
    [self setupRemoteIOUnit:&myStruct];
    
    [self startGraph:myStruct.graph];
}

- (void)stop
{
    [self stopGraph:myStruct.graph];
}

-(void)openOrCloseEchoCancellation
{
    if (self.isCloseServer == YES)
    {
        return;
    }
    UInt32 echoCancellation;
    UInt32 size = sizeof(echoCancellation);
    CheckError(AudioUnitGetProperty(myStruct.remoteIOUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Global,
                                    0,
                                    &echoCancellation,
                                    &size),
               "kAUVoiceIOProperty_BypassVoiceProcessing failed");
    if (echoCancellation==0) {
        echoCancellation = 1;
    }else{
        echoCancellation = 0;
    }
    
    CheckError(AudioUnitSetProperty(myStruct.remoteIOUnit,
                                    kAUVoiceIOProperty_BypassVoiceProcessing,
                                    kAudioUnitScope_Global,
                                    0,
                                    &echoCancellation,
                                    sizeof(echoCancellation)),
               "AudioUnitSetProperty kAUVoiceIOProperty_BypassVoiceProcessing failed");
    self.status = echoCancellation == 0 ? XBEchoCancellationStatus_open : XBEchoCancellationStatus_close;
}

-(void)startGraph:(AUGraph)graph
{
    if (self.isCloseServer == NO)
    {
        return;
    }
    CheckError(AUGraphInitialize(graph),
               "AUGraphInitialize failed");
    CheckError(AUGraphStart(graph),
               "AUGraphStart failed");
    self.isCloseServer = NO;
    self.status = XBEchoCancellationStatus_open;
}

- (void)stopGraph:(AUGraph)graph
{
    if (self.isCloseServer == YES)
    {
        return;
    }
    CheckError(AUGraphUninitialize(graph),
               "AUGraphUninitialize failed");
    CheckError(AUGraphStop(graph),
               "AUGraphStop failed");
    self.isCloseServer = YES;
    self.status = XBEchoCancellationStatus_close;
}


-(void)createAUGraph:(MyAUGraphStruct*)augStruct{
    //Create graph
    CheckError(NewAUGraph(&augStruct->graph),
               "NewAUGraph failed");
    
    //Create nodes and add to the graph
    AudioComponentDescription inputcd = {0};
    inputcd.componentType = kAudioUnitType_Output;
    inputcd.componentSubType = kAudioUnitSubType_VoiceProcessingIO;
    inputcd.componentManufacturer = kAudioUnitManufacturer_Apple;
    
    AUNode remoteIONode;
    //Add node to the graph
    CheckError(AUGraphAddNode(augStruct->graph,
                              &inputcd,
                              &remoteIONode),
               "AUGraphAddNode failed");
    
    //Open the graph
    CheckError(AUGraphOpen(augStruct->graph),
               "AUGraphOpen failed");
    
    //Get reference to the node
    CheckError(AUGraphNodeInfo(augStruct->graph,
                               remoteIONode,
                               &inputcd,
                               &augStruct->remoteIOUnit),
               "AUGraphNodeInfo failed");
}


-(void)setupRemoteIOUnit:(MyAUGraphStruct*)augStruct{
    //Open input of the bus 1(input mic)
    UInt32 inputEnableFlag = 1;
    CheckError(AudioUnitSetProperty(augStruct->remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Input,
                                    1,
                                    &inputEnableFlag,
                                    sizeof(inputEnableFlag)),
               "Open input of bus 1 failed");
    
    //Open output of bus 0(output speaker)
    UInt32 outputEnableFlag = 1;
    CheckError(AudioUnitSetProperty(augStruct->remoteIOUnit,
                                    kAudioOutputUnitProperty_EnableIO,
                                    kAudioUnitScope_Output,
                                    0,
                                    &outputEnableFlag,
                                    sizeof(outputEnableFlag)),
               "Open output of bus 0 failed");
    
    //Set up stream format for input and output
    streamFormat.mFormatID = kAudioFormatLinearPCM;
    streamFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked;
    streamFormat.mSampleRate = kRate;
    streamFormat.mFramesPerPacket = 1;
    streamFormat.mBytesPerFrame = 2;
    streamFormat.mBytesPerPacket = 2;
    streamFormat.mBitsPerChannel = 16;
    streamFormat.mChannelsPerFrame = 1;
    
    CheckError(AudioUnitSetProperty(augStruct->remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    0,
                                    &streamFormat,
                                    sizeof(streamFormat)),
               "kAudioUnitProperty_StreamFormat of bus 0 failed");
    
    CheckError(AudioUnitSetProperty(augStruct->remoteIOUnit,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Output,
                                    1,
                                    &streamFormat,
                                    sizeof(streamFormat)),
               "kAudioUnitProperty_StreamFormat of bus 1 failed");
    
    AURenderCallbackStruct input;
    input.inputProc = InputCallback_xb;
    input.inputProcRefCon = (__bridge void *)(self);
    CheckError(AudioUnitSetProperty(augStruct->remoteIOUnit,
                                    kAudioOutputUnitProperty_SetInputCallback,
                                    kAudioUnitScope_Output,
                                    1,
                                    &input,
                                    sizeof(input)),
               "couldnt set remote i/o render callback for output");
}

-(void)createRemoteIONodeToGraph:(AUGraph*)graph
{
    
}

-(void)setupSession
{
    NSError *error = nil;
    AVAudioSession* session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:&error];
    [session setActive:YES error:nil];
}



#pragma mark - 其他方法

static void CheckError(OSStatus error, const char *operation)
{
    if (error == noErr) return;
    char errorString[20];
    // See if it appears to be a 4-char-code
    *(UInt32 *)(errorString + 1) = CFSwapInt32HostToBig(error);
    if (isprint(errorString[1]) && isprint(errorString[2]) &&
        isprint(errorString[3]) && isprint(errorString[4])) {
        errorString[0] = errorString[5] = '\'';
        errorString[6] = '\0';
    } else
        // No, format it as an integer
        sprintf(errorString, "%d", (int)error);
    fprintf(stderr, "Error: %s (%s)\n", operation, errorString);
    exit(1);
}

OSStatus InputCallback_xb(void *inRefCon,
                       AudioUnitRenderActionFlags *ioActionFlags,
                       const AudioTimeStamp *inTimeStamp,
                       UInt32 inBusNumber,
                       UInt32 inNumberFrames,
                       AudioBufferList *ioData){
    
    XBEchoCancellation *echoCancellation = (__bridge XBEchoCancellation*)inRefCon;
    MyAUGraphStruct *myStruct = &(echoCancellation->myStruct);
    
    AudioBufferList bufferList;
    bufferList.mNumberBuffers = 1;
    bufferList.mBuffers[0].mData = NULL;
    bufferList.mBuffers[0].mDataByteSize = 0;

    AudioUnitRender(myStruct->remoteIOUnit,
                                      ioActionFlags,
                                      inTimeStamp,
                                      1,
                                      inNumberFrames,
                                      &bufferList);
    AudioBuffer buffer = bufferList.mBuffers[0];
    
    if (echoCancellation.bufferBlock)
    {
        echoCancellation.bufferBlock(buffer);
    }

    NSLog(@"InputCallback");
    return noErr;
}
@end
